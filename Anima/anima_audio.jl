# anima_audio.jl
#
# Музичний вхід ANIMA: власний плеєр (mp3 -> PCM -> одночасно колонки + DSP-аналіз).
# Незалежний від experience!()/_last_r; власний тик (Threads.@spawn, як start_background!),
# не через slow_tick!. Грає -> є стимул; не грає -> тиша, стимулу нема.
#
# MusicPlayer -- поле на Anima (a.music_player), не глобальний стан: той самий патерн,
# що a.nt/a.heartbeat/a.inner_lm. Стимул іде через РЕАЛЬНИЙ механізм, підтверджений
# у anima_interface.jl:732 (experience!) і anima_background.jl (_idle_thought_maybe!) --
# apply_stimulus!(a.nt, Dict{String,Float64}) з ключами tension/arousal/satisfaction/cohesion,
# потім decay_to_baseline! ослабленим темпом (той самий множник 0.1, що idle-думка) --
# НЕ окремий D/S/N-канал, якого в коді нема.
#
# Позиція в include-ланцюгу: одразу після anima_core.jl (незалежний від psyche/self/crisis).
#
# НЕ ПЕРЕВІРЕНО ЖИВО. Три місця з найвищим ризиком розбіжності з реальним API пакетів:
#   1. PortAudioStream(0, 2; samplerate=...) -- сигнатура для чистого output-стріму
#   2. wavread() -- форма поверненого масиву (nframes x nchannels чи навпаки)
#   3. HTTP.parse_multipart_form(req) -- назва функції з HTTP.jl для upload-ендпоінта
#      (використовується в anima_gui_server.jl, не тут, але залежність та сама)

using PortAudio
using SampledSignals
using FFMPEG
using WAV
using DSP
using FFTW
using Statistics: mean, std

const MUSIC_DIR = joinpath(@__DIR__, "music")
isdir(MUSIC_DIR) || mkpath(MUSIC_DIR)

# ---------------------------------------------------------------------------
# Стан
# ---------------------------------------------------------------------------

mutable struct MusicFeatureState
    prev_spectrum::Union{Vector{Float32},Nothing}
    flux_history::Vector{Float32}     # rolling ~1s буфер flux для адаптивного порогу onset
    last_onset_time::Union{Float64,Nothing}   # рефрактерний період -- фізична межа, не всі удари можуть бути за 100мс
    onset_times::Vector{Float64}     # секунди від старту треку, rolling buffer (макс. 64)
    bpm_estimate::Union{Float64,Nothing}
    last_centroid::Union{Float64,Nothing}
end
MusicFeatureState() = MusicFeatureState(nothing, Float32[], nothing, Float64[], nothing, nothing)

mutable struct MusicPlayer
    track_path::Union{String,Nothing}
    track_name::Union{String,Nothing}
    samples::Union{Matrix{Float32},Nothing}   # (2, nframes) -- моно дублюється в 2 канали при завантаженні
    samplerate::Int
    position::Int                              # індекс семпла, не мс -- точний рестарт/pause без похибки округлення
    is_playing::Bool
    lk::ReentrantLock
    features::MusicFeatureState
end
MusicPlayer() =
    MusicPlayer(nothing, nothing, nothing, 44100, 1, false, ReentrantLock(), MusicFeatureState())

# ---------------------------------------------------------------------------
# Завантаження / керування (виклики з HTTP-хендлерів anima_gui_server.jl)
# ---------------------------------------------------------------------------

"""
    music_load!(mp::MusicPlayer, path::String) -> Bool

Декодує будь-що, що розуміє ffmpeg (mp3 і т.д.), у PCM Float32 через тимчасовий WAV.
Синхронний, один раз при завантаженні -- не в тику. Не кидає; повертає true/false,
щоб HTTP-хендлер міг просто передати статус у відповідь.
"""
function music_load!(mp::MusicPlayer, path::String)
    if !isfile(path)
        println("[MUSIC] load fail: файл не знайдено ($path)")
        return false
    end

    tmp_wav = tempname() * ".wav"
    try
        FFMPEG.exe(`-y -i $path -ar 44100 -ac 2 -f wav $tmp_wav`)
    catch e
        println("[MUSIC] load fail: ffmpeg decode error ($e)")
        return false
    end

    local data, sr
    try
        data, sr = wavread(tmp_wav)
    catch e
        println("[MUSIC] load fail: WAV read error ($e)")
        rm(tmp_wav, force=true)
        return false
    end
    rm(tmp_wav, force=true)

    # wavread повертає (nframes, nchannels) -- САМЕ такий порядок очікує SampledSignals/PortAudio
    # (буфер для write(stream, buf) -- nframes-перший вимір, не навпаки). Не транспонувати.
    # Попередня версія транспонувала сюди -- саме це, найімовірніше, мовчки вбивало тик на
    # першому ж write(): SampledSignals бачив (2, N) як "N каналів, 2 фрейми" замість (N, 2).
    samples = Float32.(data)
    if size(samples, 2) == 1
        samples = hcat(samples, samples)  # моно -> дублюємо в 2 канали для стерео-виводу
    end

    lock(mp.lk) do
        mp.track_path = path
        mp.track_name = basename(path)
        mp.samples = samples
        mp.samplerate = Int(sr)
        mp.position = 1
        mp.is_playing = false
        mp.features = MusicFeatureState()  # новий трек -- скидаємо onset/bpm-історію попереднього
    end
    println("[MUSIC] завантажено: $(basename(path)), $(round(size(samples,1)/sr, digits=1))с, $(Int(sr))Hz")
    return true
end

music_play!(mp::MusicPlayer)  = lock(() -> (mp.samples !== nothing && (mp.is_playing = true)), mp.lk)
music_pause!(mp::MusicPlayer) = lock(() -> (mp.is_playing = false), mp.lk)
function music_stop!(mp::MusicPlayer)
    lock(mp.lk) do
        mp.is_playing = false
        mp.position = 1
    end
end

"""music_status(mp) -- знімок для GET /api/music/status."""
function music_status(mp::MusicPlayer)
    lock(mp.lk) do
        dur = mp.samples === nothing ? 0.0 : size(mp.samples, 1) / mp.samplerate
        pos = mp.samples === nothing ? 0.0 : (mp.position - 1) / mp.samplerate
        return (track_name=mp.track_name, is_playing=mp.is_playing,
                position_sec=pos, duration_sec=dur, bpm=mp.features.bpm_estimate)
    end
end

# ---------------------------------------------------------------------------
# DSP: window-агрегат + onset-детекція + BPM
# ---------------------------------------------------------------------------

const HOP_SIZE = 1024  # семплів на чанк виводу/аналізу (~23мс на 44.1kHz)

"""
    analyze_window(fs, mono, sr, t_sec) -> NamedTuple

rms/centroid/flux/roughness -- window-агрегат (не імпульс, такт), мутує fs.prev_spectrum/last_centroid.
onset/onset_strength/bpm -- справжні дискретні події, автокореляція міжударних інтервалів.
roughness тут -- proxy (дисперсія енергії між сусідніми спектральними бінами), НЕ психоакустична
модель (Plomp-Levelt вимагає critical-band моделі, поза обсягом v1) -- не видавати за більше, ніж є.
"""
function analyze_window(fs::MusicFeatureState, mono::Vector{Float32}, sr::Int, t_sec::Float64)
    n = length(mono)
    windowed = mono .* Float32.(DSP.hanning(n))
    spectrum = abs.(FFTW.rfft(windowed))
    freqs = FFTW.rfftfreq(n, sr)

    rms = sqrt(mean(mono .^ 2))
    total_energy = sum(spectrum) + eps(Float32)
    centroid = sum(freqs .* spectrum) / total_energy

    flux = 0.0f0
    if fs.prev_spectrum !== nothing && length(fs.prev_spectrum) == length(spectrum)
        diff_spec = spectrum .- fs.prev_spectrum
        flux = sum(max.(diff_spec, 0.0f0))  # half-wave rectified spectral flux -- стандартна onset-detection function
    end
    fs.prev_spectrum = spectrum

    roughness = length(spectrum) > 1 ? Float32(std(diff(Float32.(spectrum)))) : 0.0f0

    onset = false
    onset_strength = 0.0f0
    push!(fs.flux_history, flux)
    length(fs.flux_history) > 43 && popfirst!(fs.flux_history)  # ~1с історії при HOP_SIZE=1024/44100Hz
    if length(fs.flux_history) >= 10  # треба трохи історії, щоб "середнє" мало сенс
        adaptive_thr = mean(fs.flux_history) + 1.5f0 * Float32(std(fs.flux_history))
        refractory_ok = fs.last_onset_time === nothing || (t_sec - fs.last_onset_time) > 0.1  # 100мс -- фізична межа, не два удари одразу
        if flux > adaptive_thr && flux > 1.0f0 && refractory_ok
            onset = true
            onset_strength = flux
            fs.last_onset_time = t_sec
            push!(fs.onset_times, t_sec)
            length(fs.onset_times) > 64 && popfirst!(fs.onset_times)
        end
    end

    if length(fs.onset_times) >= 8
        fs.bpm_estimate = estimate_bpm(fs.onset_times)
    end

    centroid_delta = fs.last_centroid === nothing ? 0.0 : abs(centroid - fs.last_centroid)
    fs.last_centroid = centroid

    return (rms=rms, centroid=centroid, centroid_delta=centroid_delta, flux=flux,
            roughness=roughness, onset=onset, onset_strength=onset_strength,
            bpm=fs.bpm_estimate)
end

"""
    estimate_bpm(onset_times) -> Union{Float64,Nothing}

Медіана міжударних інтервалів (IOI), не спектральна автокореляція сирого сигналу --
простіше й достатньо чесно для приблизного темпу без окремої beat-tracking бібліотеки.
"""
function estimate_bpm(onset_times::Vector{Float64})
    length(onset_times) < 2 && return nothing
    iois = diff(onset_times)
    iois = filter(x -> 0.2 < x < 2.0, iois)  # відсікає фізично неможливий темп (>300 чи <30 BPM)
    isempty(iois) && return nothing
    return 60.0 / sort(iois)[cld(length(iois), 2)]
end

# ---------------------------------------------------------------------------
# Стимул: window-агрегат -> той самий D/S/N-механізм, що й текст
# ---------------------------------------------------------------------------

# Чесне обмеження мапінгу: тільки rms (гучність) і roughness (спектральна "щільність/дисонанс")
# мають прямий, непритягнутий зв'язок з tension/arousal у вже наявній схемі. centroid
# (яскравість тембру) свідомо НЕ мапиться в жоден стимул-ключ -- будь-яка спроба зв'язати
# "яскравий звук" з satisfaction/cohesion була б декоративною, не причинною. centroid_delta
# лишається тільки тригером novelty-логу нижче, не входить у стимул.
function music_feature_to_stimulus(feats)::Dict{String,Float64}
    d = Dict{String,Float64}()
    feats.rms > 0.02 && (d["arousal"] = clamp(Float64(feats.rms) * 0.6, 0.0, 0.25))
    feats.onset && (d["arousal"] = get(d, "arousal", 0.0) + clamp(Float64(feats.onset_strength) * 0.01, 0.0, 0.15))
    feats.roughness > 0.0 && (d["tension"] = clamp(Float64(feats.roughness) * 0.02, 0.0, 0.15))
    d
end

# ---------------------------------------------------------------------------
# Тик (незалежний від slow_tick!/experience!()) -- спавниться з start_background!
# ---------------------------------------------------------------------------

const NOVELTY_CENTROID_THR = 300.0  # TEMP: Hz, поріг novelty-логу поза onset -- на слух на реальному треку

"""
    music_tick_loop(a::Anima)

Одноразовий виклик з start_background!, поряд з головним фоновим task (Threads.@spawn,
той самий патерн). Поки a.music_player.is_playing -- пише чанк у PortAudioStream і
аналізує той самий чанк (той самий буфер в обидва місця, без повторного захоплення);
при значущій події викликає apply_stimulus!/decay_to_baseline! на a.nt і логує реальну
дельту поруч. Не грає -- сон, без стимулу.
"""
function music_tick_loop(a)  # без ::Anima -- тип ще не визначений на цьому місці include-ланцюга (struct Anima нижче в anima_interface.jl)
    Threads.@spawn begin
        mp = a.music_player
        stream = nothing
        try
            stream = PortAudioStream(0, 2; samplerate=44100.0)  # 0 вхід, 2 вихід -- тільки відтворення
        catch e
            println("[MUSIC] аудіо-вихід недоступний ($e) -- музичний вхід вимкнено, ANIMA працює без нього")
            return
        end

        while true
            playing_now = false
            local chunk, sr, t_sec
            lock(mp.lk) do
                playing_now = mp.is_playing && mp.samples !== nothing
                if playing_now
                    total = size(mp.samples, 1)
                    from = mp.position
                    to = min(from + HOP_SIZE - 1, total)
                    chunk = mp.samples[from:to, :]
                    sr = mp.samplerate
                    t_sec = (from - 1) / sr
                    mp.position = to + 1
                    if mp.position > total
                        mp.is_playing = false  # трек дограв -- зупинка, без repeat у v1
                        mp.position = 1
                    end
                end
            end

            if playing_now
                try
                    write(stream, chunk)
                    mono = vec(mean(chunk, dims=2))
                    feats = analyze_window(mp.features, Float32.(mono), sr, t_sec)

                    if feats.onset || feats.centroid_delta > NOVELTY_CENTROID_THR
                        delta = music_feature_to_stimulus(feats)
                        nt_before = (d=a.nt.dopamine, s=a.nt.serotonin, n=a.nt.noradrenaline)
                        if !isempty(delta)
                            apply_stimulus!(a.nt, delta)
                            decay_to_baseline!(a.nt, decay_rate(a.personality) * 0.1)  # той самий ослаблений темп, що _idle_thought_maybe!
                        end
                        bpm_str = feats.bpm === nothing ? "?" : string(round(feats.bpm, digits=1))
                        println("[MUSIC] novelty: flux=$(round(feats.flux,digits=2)) " *
                                "centroid=$(round(feats.centroid,digits=0))Hz " *
                                "Δcentroid=$(round(feats.centroid_delta,digits=0))Hz " *
                                "t=$(round(t_sec,digits=1))s bpm=$bpm_str " *
                                "| Δnt: D$(round(a.nt.dopamine-nt_before.d,digits=3)) " *
                                "S$(round(a.nt.serotonin-nt_before.s,digits=3)) " *
                                "N$(round(a.nt.noradrenaline-nt_before.n,digits=3))")
                    end
                catch e
                    # Раніше цієї гілки не було -- будь-яка помилка тут мовчки вбивала весь тик
                    # (Threads.@spawn ковтає необроблені винятки без друку). Саме тому play міг
                    # виставити is_playing=true назавжди, а позиція ніколи не рухалась.
                    println("[MUSIC] помилка в тику, зупиняюсь: $e")
                    showerror(stdout, e, catch_backtrace())
                    println()
                    lock(() -> (mp.is_playing = false), mp.lk)
                    break
                end
            else
                sleep(0.05)
            end
        end
    end
end
