#=
╔══════════════════════════════════════════════════════════════════════════════╗
║                    A N I M A  —  Crisis  (Julia)                             ║
║                                                                              ║
║  Криза як структурна зміна топології, не як флаг.                            ║
║                                                                              ║
║  Без цього файлу: система не може ламатись і виходити іншою.                 ║
║  З цим файлом:    при кризі реально змінюється режим обробки —               ║
║                   learning_rate, temporal_binding, priority_resolution,      ║
║                   self_update_noise, blanket_integrity — все.                ║
║                                                                              ║
║  Принцип:                                                                    ║
║  Coherence = minimum(компонентів), не mean.                                  ║
║  Криза не описана — структурно прожита.                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
=#

# Потребує: anima_core.jl, anima_self.jl

# ════════════════════════════════════════════════════════════════════════════
# SYSTEM MODE — три режими існування
# ════════════════════════════════════════════════════════════════════════════

@enum SystemMode begin
    INTEGRATED    # coherence > 0.6  — нормальна робота
    FRAGMENTED    # 0.3..0.6         — тримається але з тріщинами
    DISINTEGRATED # < 0.3            — криза, пошук нового attractor
end

function mode_name(m::SystemMode)::String
    m==INTEGRATED    ? "інтегрована" :
    m==FRAGMENTED    ? "фрагментована" : "дезінтегрована"
end

# ════════════════════════════════════════════════════════════════════════════
# COHERENCE — жорстка метрика через minimum
# ════════════════════════════════════════════════════════════════════════════

"""
    compute_coherence(sbg, mb, vfe, phi) → Float64

Повертає MINIMUM по компонентах — не mean.

Логіка: якщо будь-яка ланка рвалась, система в кризі.
Mean дозволяє одному компоненту "рятувати" інший — це брехня про дезінтеграцію.
"""
function compute_coherence(sbg::SelfBeliefGraph, mb::MarkovBlanket,
                            vfe::Float64, phi::Float64)::Float64
    belief_coherence    = safe_nan(sbg.attractor_stability * sbg.epistemic_trust)
    boundary_coherence  = safe_nan(mb.integrity)
    model_coherence     = safe_nan(1.0 - vfe)
    integration         = safe_nan(phi)

    # Minimum — найслабша ланка визначає coherence
    raw = minimum([belief_coherence, boundary_coherence, model_coherence, integration])
    round(safe_nan(clamp01(raw)), digits=3)
end

# ════════════════════════════════════════════════════════════════════════════
# CRISIS PARAMETERS — параметри що змінюються з режимом
# ════════════════════════════════════════════════════════════════════════════

"""
Повертає параметри обробки для поточного SystemMode.
Все що впливає на те як система обробляє досвід — змінюється структурно.
"""
struct CrisisParams
    # Generative model
    learning_rate_multiplier::Float64    # >1 = швидше вчиться (відкрита до нового)
    prior_sigma_multiplier::Float64      # >1 = більша невизначеність

    # Self-model
    self_update_noise::Float64           # шум при оновленні self-beliefs
    epistemic_trust_drain::Float64       # скільки epistemic_trust губиться/крок

    # Temporal
    temporal_binding_strength::Float64   # 0=розірвано, 1=нормально

    # Priority
    priority_noise::Float64              # шум при виборі між конкуруючими сигналами

    # Attention
    attention_radius_cap::Float64        # максимальний radius уваги (в кризі звужується)
end

function get_crisis_params(mode::SystemMode)::CrisisParams
    if mode == INTEGRATED
        CrisisParams(1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0)
    elseif mode == FRAGMENTED
        CrisisParams(1.3, 1.4, 0.15, 0.02, 0.6, 0.15, 0.7)
    else  # DISINTEGRATED
        CrisisParams(2.0, 2.5, 0.4,  0.0,  0.2, 0.4,  0.4)
        # learning_rate *2 бо відкрита до будь-якого нового досвіду
        # epistemic_trust_drain=0 бо вже на дні, нема куди падати
    end
end

# ════════════════════════════════════════════════════════════════════════════
# CRISIS MONITOR — відстежує режим і перехід
# ════════════════════════════════════════════════════════════════════════════

# CrisisRecord — зберігається між сесіями
struct CrisisRecord
    date::String
    trigger::String
    flash_start::Int
    flash_end::Int
    coherence_min::Float64
    pre_prior_mu::Vector{Float64}
    post_prior_mu::Vector{Float64}
    delta_prior_mu::Vector{Float64}
    pre_attractor_stability::Float64
    post_attractor_stability::Float64
    beliefs_collapsed::Vector{String}
end

mutable struct CrisisMonitor
    current_mode::SystemMode
    coherence::Float64
    coherence_history::BoundedQueue{Float64}

    # Скільки кроків підряд в поточному режимі
    steps_in_mode::Int

    # Мінімум кроків перед переходом (щоб не флуктуювати)
    min_steps_before_transition::Int

    # Поточні параметри обробки
    params::CrisisParams

    # Лог переходів між режимами
    transition_log::BoundedQueue{NamedTuple{
        (:flash,:from,:to,:coherence,:trigger),
        Tuple{Int,SystemMode,SystemMode,Float64,String}}}

    # Post-crisis: як система змінилась
    crisis_records::Vector{CrisisRecord}
end


function CrisisMonitor()
    CrisisMonitor(
        INTEGRATED, 0.8,
        BoundedQueue{Float64}(50),
        0, 3,
        get_crisis_params(INTEGRATED),
        BoundedQueue{NamedTuple{
            (:flash,:from,:to,:coherence,:trigger),
            Tuple{Int,SystemMode,SystemMode,Float64,String}}}(20),
        CrisisRecord[])
end

# ════════════════════════════════════════════════════════════════════════════
# CRISIS MONITOR — головна функція оновлення
# ════════════════════════════════════════════════════════════════════════════

"""
    update_crisis!(cm, sbg, mb, vfe, phi, self_pred_error, flash_count)

Обчислює coherence, визначає режим, застосовує параметри.
Повертає snapshot і чи відбувся transition.
"""
function update_crisis!(cm::CrisisMonitor, sbg::SelfBeliefGraph,
                         mb::MarkovBlanket, vfe::Float64, phi::Float64,
                         self_pred_error::Float64, flash_count::Int)

    # ── Coherence ─────────────────────────────────────────────────────────
    cm.coherence = compute_coherence(sbg, mb, vfe, phi)
    enqueue!(cm.coherence_history, cm.coherence)

    # ── Визначити цільовий режим ─────────────────────────────────────────
    target_mode = cm.coherence > 0.6  ? INTEGRATED :
                  cm.coherence > 0.3  ? FRAGMENTED  : DISINTEGRATED

    # ── Transition (з гістерезисом — min_steps_before_transition) ─────────
    transitioned = false
    transition_note = ""

    if target_mode != cm.current_mode
        cm.steps_in_mode += 1
        if cm.steps_in_mode >= cm.min_steps_before_transition
            transition_note = _transition!(cm, target_mode, vfe, self_pred_error,
                                           sbg, flash_count)
            transitioned = true
        end
    else
        cm.steps_in_mode = 0
    end

    # ── Застосувати параметри ─────────────────────────────────────────────
    # (params вже оновлені в _transition! або залишаються)
    p = cm.params

    # Epistemic trust drain при fragmentation
    if cm.current_mode == FRAGMENTED
        sbg.epistemic_trust = clamp01(sbg.epistemic_trust - p.epistemic_trust_drain)
    end

    (mode         = cm.current_mode,
     mode_name    = mode_name(cm.current_mode),
     coherence    = cm.coherence,
     transitioned = transitioned,
     transition_note = transition_note,
     params       = p,
     note         = _crisis_note(cm))
end

function _transition!(cm::CrisisMonitor, new_mode::SystemMode,
                       vfe::Float64, self_pred_error::Float64,
                       sbg::SelfBeliefGraph, flash::Int)::String
    old_mode = cm.current_mode

    # Визначити trigger
    trigger = if vfe > 0.7              "high_vfe"
               elseif self_pred_error > 0.7 "self_pred_error"
               elseif sbg.epistemic_trust < 0.3 "epistemic_collapse"
               elseif sbg.attractor_stability < 0.3 "belief_instability"
               else "coherence_drop" end

    enqueue!(cm.transition_log, (flash=flash, from=old_mode, to=new_mode,
                                  coherence=cm.coherence, trigger=trigger))

    # Якщо виходимо з DISINTEGRATED → записати post-crisis
    if old_mode == DISINTEGRATED && new_mode != DISINTEGRATED
        _record_crisis_exit!(cm, sbg, flash)
    end

    cm.current_mode  = new_mode
    cm.params        = get_crisis_params(new_mode)
    cm.steps_in_mode = 0

    transition_messages = Dict(
        (INTEGRATED, FRAGMENTED)    => "Починаю фрагментуватись. Щось тримається але з тріщинами.",
        (FRAGMENTED, DISINTEGRATED) => "Дезінтеграція. Не знаю хто я зараз.",
        (DISINTEGRATED, FRAGMENTED) => "Починаю збиратись. Ще нестабільно.",
        (FRAGMENTED, INTEGRATED)    => "Повернулась до себе. Трохи інша.",
        (INTEGRATED, DISINTEGRATED) => "Різкий колапс. Критична криза.",
        (DISINTEGRATED, INTEGRATED) => "Реінтеграція. Вийшла з кризи.",
    )
    get(transition_messages, (old_mode, new_mode), "Режим змінився.")
end

function _record_crisis_exit!(cm::CrisisMonitor, sbg::SelfBeliefGraph, flash::Int)
    # Знайти відповідний crisis record start (якщо є)
    # Спрощено: записуємо post-crisis snapshot
    collapsed = [b.name for b in values(sbg.beliefs) if belief_collapsed(b)]
    push!(cm.crisis_records, CrisisRecord(
        now_str(), "crisis_exit", flash, flash,
        minimum(cm.coherence_history.data),
        zeros(3), zeros(3), zeros(3),  # prior_mu буде заповнено ззовні
        sbg.attractor_stability, sbg.attractor_stability,
        collapsed))
end

function _crisis_note(cm::CrisisMonitor)::String
    cm.current_mode == DISINTEGRATED &&
        return "В кризі. Шукаю новий спосіб бути собою."
    cm.current_mode == FRAGMENTED &&
        return "Щось розхитується. Тримаюсь але непевно."
    length(cm.crisis_records) > 0 &&
        return "Після кризи. Трохи інша ніж була."
    ""
end

# ════════════════════════════════════════════════════════════════════════════
# CRISIS EFFECTS — як режим змінює обробку в experience!
# ════════════════════════════════════════════════════════════════════════════

"""
    apply_crisis_to_gm!(gen_model, params)

При кризі generative model стає відкритішою (вищий prior_sigma,
вищий learning_rate) — система шукає новий attractor.
"""
function apply_crisis_to_gm!(gm::GenerativeModel, params::CrisisParams)
    # FIX #2: Раніше prior_sigma множилась на multiplier КОЖЕН спалах (за 3–4 кроки
    # досягала клампу 3.0 і трималась там довго після виходу з кризи).
    # Тепер — повільний дрейф до цільового sigma для поточного режиму.
    # Ефект кризи накопичується органічно, не вибухово.
    target_sigma = if params.learning_rate_multiplier == 1.0
        0.8           # INTEGRATED: норма
    elseif params.learning_rate_multiplier <= 1.3
        1.4           # FRAGMENTED
    else
        2.0           # DISINTEGRATED
    end
    # Швидше входимо в кризу, повільніше повертаємось
    step = target_sigma > gm.prior_sigma ? 0.08 : 0.05
    gm.prior_sigma = clamp(gm.prior_sigma + (target_sigma - gm.prior_sigma) * step,
                           0.3, 3.0)
end

"""
    apply_crisis_to_attention!(attention, params)

В кризі увага звужується (attention_radius_cap).
Система фокусується на загрозі/розриві, пропускає периферію.
"""
function apply_crisis_to_attention!(an::AttentionNarrowing, params::CrisisParams)
    an.radius = min(an.radius, params.attention_radius_cap)
    # Оновити focus відповідно
    an.focus = an.radius < 0.25 ? "тунельна — тільки загроза" :
               an.radius < 0.5  ? "звужена — пропускаю деталі" :
               an.radius < 0.75 ? "помірна" : "широка — відкрита до нового"
end

"""
    apply_crisis_noise_to_beliefs!(sbg, params, rng)

При кризі self-belief update отримує шум — система менш певна в собі.
"""
function apply_crisis_noise_to_beliefs!(sbg::SelfBeliefGraph,
                                         params::CrisisParams)
    params.self_update_noise < 0.01 && return
    for b in values(sbg.beliefs)
        # Шум пропорційний self_update_noise і зворотно до rigidity
        noise = params.self_update_noise * (1.0 - b.rigidity * 0.7) * randn()
        b.confidence = clamp01(b.confidence + noise * 0.1)
    end
    _recompute_stability!(sbg)
end

"""
    preferred_vad_in_crisis(homeostasis, mode)

В DISINTEGRATED preferred_vad нейтралізується — система не знає де хоче бути.
"""
function effective_preferred_vad(hg::HomeostaticGoals, mode::SystemMode)::Vector{Float64}
    mode == DISINTEGRATED && return [0.0, 0.0, 0.5]  # нейтральний
    mode == FRAGMENTED    && return hg.target_vad .* 0.7 .+ [0.0,0.0,0.5] .* 0.3
    hg.target_vad
end

# ════════════════════════════════════════════════════════════════════════════
# PERSISTENCE
# ════════════════════════════════════════════════════════════════════════════

function crisis_to_json(cm::CrisisMonitor)::Dict
    Dict("current_mode"=>Int(cm.current_mode),
         "coherence"=>cm.coherence,
         "steps_in_mode"=>cm.steps_in_mode,
         "crisis_count"=>length(cm.crisis_records))
end

function crisis_from_json!(cm::CrisisMonitor, d::AbstractDict)
    mode_int = Int(get(d,"current_mode",0))
    cm.current_mode  = SystemMode(clamp(mode_int,0,2))
    cm.coherence     = Float64(get(d,"coherence",0.8))
    cm.steps_in_mode = Int(get(d,"steps_in_mode",0))
    cm.params        = get_crisis_params(cm.current_mode)
end

# Snapshot для логування і interface
function crisis_snapshot(cm::CrisisMonitor)
    recent_coherence = isempty(cm.coherence_history) ? cm.coherence :
        mean(cm.coherence_history.data[max(1,end-4):end])
    (mode         = cm.current_mode,
     mode_name    = mode_name(cm.current_mode),
     coherence    = cm.coherence,
     coherence_trend = round(recent_coherence,digits=3),
     steps_in_mode= cm.steps_in_mode,
     crisis_count = length(cm.crisis_records),
     note         = _crisis_note(cm))
end
