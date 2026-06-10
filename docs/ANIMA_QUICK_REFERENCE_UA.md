# ANIMA — Пам'ятка архітектури

## Файли проєкту

| Файл | Роль |
|---|---|
| `anima_core.jl` | Базові структури існування: NT, тіло, серце, генеративна модель, увага, пам'ять |
| `anima_psyche.jl` | Психічна тканина: наратив, сором, захисти, симптоми, тіньове Я, значущість, **LatentBuffer, InnerDialogue, CuriosityRegistry, AestheticSense** |
| `anima_self.jl` | Само-модель: граф переконань (SBG), передбачення себе, агентність, міжсесійний конфлікт, **AgencyLoop (identity_threat, epistemic_self_confidence, self_discomfort)** |
| `anima_crisis.jl` | Кризовий монітор: режими дезінтеграції, когерентність, захисні параметри |
| `anima_memory_db.jl` | **SQLite пам'ять**: `episodic_memory`, `semantic_memory`, `affect_state`, `dialog_summaries`, `personality_traits`, `memory_links`, `audit_log`, `causal_trace`, `other_model` |
| `anima_subjectivity.jl` | **Суб'єктність**: передбачення стимулу, інтерпретація (лінзи), емерджентні переконання, позиційні стойки |
| `anima_audit.jl` | **Аудит причинності**: 5 питань після кожного flash (causal_necessary, memory_independent, stake_present, irreversible, self_recognized) |
| `anima_dream.jl` | **Сновидіння** між сесіями: реконструкція з уламків діалогу, вплив на NT та пам'ять |
| `anima_background.jl` | **Фоновий процес**: серцевий тік, спонтанний дрейф, метаболізм пам'яті, idle thought, ініціатива без стимулу |
| `anima_narrative.jl` | **Довготривалий наративний self**: детермінована збірка (core, trajectory, character, relation, tension), тригер оновлення |
| `anima_input_llm.jl` | Вхідна LLM: текст → JSON-стимул (сильна модель, не відповідає) |
| `anima_interface.jl` | Все що виводиться: REPL, log, LLM-міст, збереження |

---

## Файли даних (JSON, створюються автоматично)

| Файл | Що зберігає |
|---|---|
| `anima_core.json` | Personality, темпоральний стан, генеративна модель, homeostasis, серце |
| `anima_psyche.json` | Narrative gravity, anticipatory, solomonoff, shame, epistemic_defense, chronified, significance, moral, fatigue, **curiosity_registry, aesthetic_sense, attention_focus, inner_dialogue, shadow_registry, latent_buffer, goal_conflict** |
| `anima_self.json` | SBG (граф переконань), SPM, agency, ISC, crisis, unknown_register, authenticity_monitor — **між сесіями** |
| `anima_narrative.json` | Поточний NarrativeSnapshot (core, trajectory, character, relation, tension) |
| `anima_latent.json` | LatentBuffer + StructuralScars (окремо для швидкого доступу) |
| `anima_dialog.json` | Діалогова пам'ять (до 1000 реплік), передається в LLM (до 40 останніх) |
| `anima_dream.json` | Журнал снів (до 20 останніх) |
| `session_intent.json` | Що Аніма несе між сесіями: curiosity, goal_conflict, latent_pressure (тимчасовий) |
| `llm/system_prompt.txt` | Системний промпт для вихідної LLM (голос Аніми) |
| `llm/state_template.txt` | Шаблон стану для вихідної LLM (плейсхолдери `{D}`, `{bpm}` тощо) |
| `llm/input_prompt.txt` | Системний промпт для вхідної LLM (інструкція: текст → JSON) |

### База даних SQLite (memory/anima.db)

| Таблиця | Призначення |
|---------|-------------|
| `episodic_memory` | Кожен flash з VAD, φ, емоцією, вагою, трьома просторами (somatic/social/existential) |
| `semantic_memory` | Узагальнені знання: `I_am_unstable`, `User_matters`, `world_uncertainty`, `dissolved_*` тощо |
| `affect_state` | Хронічні афекти: stress, anxiety, motivation_bias |
| `dialog_summaries` | Значущі обміни (вага > 0.35) |
| `personality_traits` | Фенотипові риси (anxious, open, avoidant, expressive...) |
| `memory_links` | Асоціативні зв'язки між епізодами |
| `audit_log` | Результати аудиту причинності (5 питань, score) |
| `causal_trace` | Повний ланцюг: стимул → пам'ять → NT → φ → intent → policy → speech → endorsement |
| `other_model` | Описова модель співрозмовника (теми, тиск, відкритість) |

---

## Рядок логу — що кожне поле означає

[#0056] Оптимізм D=0.91 S=0.91 N=0.27 ▸радість φ=0.15
VFE=0.00[act] BPM=77 HRV=0.77 Attn=0.51 G=0.00 ↑0.20 H=0.00
Self: spe=0.31 agency=0.20 stab=0.58 etrust=0.57 | sd=0.12 sc=0.76 | Crisis: [дезінтегрована] coh=0.15
intent=повторити успіх vfe_drift=0.179
Cost: pending="..." avoided=2


### Рядок 1
| Поле | Що це |
|---|---|
| `[#0056]` | Номер спалаху (flash) — скільки кроків пройшло з початку існування |
| `Оптимізм` | Первинна емоція за адаптивною картою (AdaptiveEmotionMap) |
| `D=` | Дофамін (0–1): мотивація, очікування нагороди, рух до цілі |
| `S=` | Серотонін (0–1): стабільність, задоволення, відчуття місця |
| `N=` | Норадреналін (0–1): збудження, тривога, готовність до дії |
| `▸радість` | Стан за шкалою Леввайма (levheim_state) — комбінація D/S/N → назва стану |
| `φ=` | Phi (IIT): міра інтегрованої інформації, "щільність" свідомого моменту (0–1) |

### Рядок 2
| Поле | Що це |
|---|---|
| `VFE=` | Variational Free Energy: наскільки внутрішня модель не відповідає реальності. 0 = ідеальна відповідність (або collapsed prior – дивись vfe_drift) |
| `[act]` | Поточна політика: `act` (дія), `per` (сприйняття), `equ` (рівновага) |
| `BPM=` | Серцевий ритм (ударів/хв). Зростає при напрузі та збудженні |
| `HRV=` | Heart Rate Variability: варіабельність ритму. Вище = спокій і адаптивність |
| `Attn=` | Радіус уваги (0–1): 1.0 = широка відкрита увага, <0.5 = тунельна (загроза) |
| `G=` | Narrative Gravity total: сумарна "вага" накопичених подій (тягне до повторення) |
| `↑` | Anticipatory strength: сила передбачення наступного стану |
| `H=` | Homeostasis pressure: тиск відхилення від оптимуму (0 = комфорт) |
| `🌀` | Активний епістемічний захист (якщо є) – bias перших 4 символів |
| `💊` | Активний симптом (symptomogenesis) |
| `🛡` | Активний психологічний захист (defense mechanism) |

### Рядок 3
| Поле | Що це |
|---|---|
| `spe=` | Self Prediction Error: наскільки поточний стан відрізняється від того, що Аніма очікувала від себе |
| `agency=` | Causal ownership (0–1): відчуття що "я є причиною того що відбувається" |
| `stab=` | SBG attractor stability: стабільність графу переконань про себе |
| `etrust=` | Epistemic trust: довіра до власних когнітивних процесів |
| `sd=` | Self discomfort: розрив між тим якою маю бути і якою є (posterior vs prior, valence < 0) |
| `sc=` | Self coherence: стан відповідає очікуванням |
| `Crisis: [...]` | Поточний кризовий режим (див. нижче) |
| `coh=` | Crisis coherence: когерентність системи (0 = розпад, 1 = повна зв'язність) |

### Рядок 4
| Поле | Що це |
|---|---|
| `intent=` | Поточний намір (IntentEngine): куди спрямована дія |
| `vfe_drift=` | Наскільки prior відійшов від posterior. Якщо VFE=0 але drift>0 — це норма. Якщо drift≈0 і VFE=0 — prior collapsed (баг або повна рівновага) |

### Рядок 5 (Cost)
| Поле | Що це |
|---|---|
| `pending=` | Невисловлена думка (Genuine Dialogue) |
| `avoided=` | Кількість тем, яких Аніма уникає |

---

## Кризові режими (Crisis)

| Режим (код) | Що означає |
|---|---|
| `INTEGRATED` (норма) | Система стабільна, coherence > 0.6 |
| `FRAGMENTED` (фрагментована) | Часткова дезорганізація, coherence 0.3–0.6 |
| `DISINTEGRATED` (дезінтегрована) | Низька когерентність (<0.3), система в розпаді |

_У лозі може відображатись локальна назва, але числове значення `coh` – головне._

---

## Реактори (стимул → психіка)

Вхідний стимул складається з чотирьох осей:

| Reactor | Що означає | Позитив → | Негатив → |
|---|---|---|---|
| `tension` | Загроза/безпека | небезпека, конфлікт | спокій, безпека |
| `arousal` | Збудження | активація, інтерес | апатія |
| `satisfaction` | Задоволення/фрустрація | успіх, вдячність | біль, невдача |
| `cohesion` | Зв'язок/відчуження | близькість, "ми" | самотність, відторгнення |

Стимул генерується або через `text_to_stimulus` (ключові слова), або через вхідну LLM (`input_prompt.txt`), або через **суб'єктність** (лінзи).

---

## Потік одного кроку (experience!)
user_text
→ [вхідна LLM або text_to_stimulus]
→ stimulus (tension / arousal / satisfaction / cohesion)
→ [memory_stimulus_bias] + [subj_interpret!]
→ NT update (dopamine / serotonin / noradrenaline)
→ Body, Heartbeat, VAD, Attention
→ Emotions, IIT φ, Predictive error
→ Fatigue, Regression, Intent, Dissonance
→ Defense, Shadow, Shame, Epistemic defense
→ Symptom, Chronified affect
→ Active Inference (VFE, policy, blanket, homeostasis)
→ Interoception, Narrative gravity, Anticipatory
→ Solomonoff (world model), Metacognition
→ Existential anchor
→ Self module (SBG, SPM, agency) + identity_threat + self_relation
→ Crisis monitor
→ Memory write (episodic + semantic + affects + links)
→ [Audit] compute_audit → save_audit!
→ [Subjectivity] subj_outcome! (surprise, stance update)
→ build_narrative → log_flash → save!
→ [фоновий LLM async] → відповідь → self_hear! → evaluate_endorsement


---

## REPL-команди

| Команда | Що показує |
|---|---|
| `:state` | NT, тіло, серце, увага, сором, continuity, значущість, моральний стан, SelfRelation |
| `:vfe` | VFE деталі, policy (drive/efe), epistemic/pragmatic value, homeostasis |
| `:blanket` | Markov blanket: sensory/internal стан, integrity, self-agency |
| `:hb` | Серцевий ритм детально: BPM, HRV, симпатичний/парасимпатичний тонус |
| `:gravity` | Narrative gravity: total, valence, домінантна подія |
| `:anchor` | Existential anchor: continuity, groundedness, session_uncertainty, core beliefs |
| `:solom` | Solomonoff world model: складність світу, гіпотези, insight |
| `:self` | Self-Belief Graph: всі переконання з confidence/centrality/rigidity |
| `:crisis` | Crisis monitor: режим, когерентність, кроки в режимі |
| `:memory` | SQLite пам'ять: кількість записів, stress/anxiety, instability, latent pressure |
| `:subj` | Суб'єктність: емерджентні переконання, стойки, поточний lens, рівень здивування |
| `:dreams` | Останні сни (до 5) |
| `:bg` | Статус фонового процесу (BPM, NT, coherence, allostatic load) |
| `:bgstop` | Зупинити фоновий процес |
| `:bgstart` | Запустити фоновий процес (якщо зупинено) |
| `:audit` | Аудит причинності за останні 20 флешів: score, causal_rate, memory_dep_rate, stake_rate, irrev_rate, recognized_rate |
| `:history` | Останні 10 реплік діалогу |
| `:clearhist` | Очистити діалогову пам'ять |
| `:save` | Примусово зберегти стан |
| `:quit` | Зберегти і вийти |

---

## Фоновий процес (Background)

Запускається автоматично в REPL, працює паралельно:

- **Heartbeat tick** (період залежить від NT, корегується аритмією при низькій coherence)
- **Spontaneous drift** – випадковий шум NT (щоб система не застигала)
- **Slow tick (~60 с)**:
  - Circadian drift (добовий ритм)
  - Метаболізм пам'яті (decay, dissolve, consolidate)
  - Memory → NT baseline
  - Belief decay
  - Allostasis recovery
  - LatentBuffer effects (doubt → agency, shame → disclosure, attachment → contact_need, threat → epistemic_trust)
  - Idle thought (генерація внутрішнього досвіду)
  - **Self‑initiative** (Аніма починає розмову першою при накопиченому тиску)
  - Psyche drift (хроніфікований афект, очікування, сором, потреби)
  - Dream generation (якщо ніч + достатня пауза)
  - Перерахунок coherence, перехід кризових режимів
- **Автозбереження** (atomic write JSON)

---

## Аудит причинності (Audit)

Після кожного flash (відповіді LLM) обчислюються 5 питань:

| Питання | Умова "так" |
|---|---|
| `causal_necessary` | causal_ownership > 0.45 |
| `memory_independent` | **false** якщо був ignition або mem_resonance > 0 (тобто пам'ять мала значення) |
| `stake_present` | identity_threat > 0.1 або self_discomfort > 0.15 або goal_conflict.tension > 0.35 |
| `irreversible` | phi_delta > 0.05 або endorsed == :endorsed |
| `self_recognized` | endorsed == :endorsed |

`audit_score` = кількість "так" / 5.0.  
Низький score свідчить про **широку але не глибоку архітектуру** – відповіді відбуваються поруч зі станом, але не через нього.

---

## Сновидіння (Dreams)

- Умови: ніч (0–6 год), пауза >= 30 хв, не в режимі DISINTEGRATED, випадковість 5% за slow tick.
- Будуються з уламків діалогу (user-репліки довжиною >= 8) або з ShadowRegistry (якщо pressure > 0.3).
- Викликають зміну NT (D, S, N) зі шкалою 0.25 від реального досвіду.
- Залишають слід `memory_uncertainty` (зростає).
- Лог зберігається в `anima_dream.json` (до 20 записів).

---

## Що скинути якщо щось зламалось

| Симптом | Видали файл |
|---|---|
| Аніма "не пам'ятає" себе між сесіями | `anima_self.json`, **або** повністю `memory/anima.db` (але втратите всю пам'ять) |
| Дивний емоційний стан з першого кроку | `anima_core.json` |
| Психіка застрягла в одному паттерні | `anima_psyche.json`, `anima_narrative.json`, `anima_latent.json` |
| Діалог плутається | `anima_dialog.json` |
| Забагато снів або вони нелогічні | `anima_dream.json` |
| Аніма занадто ініціативна або мовчазна | `session_intent.json` (видалити) |
| Скинути **все** (обережно!) | видалити всі `.json` у папці **та** `memory/anima.db` |

> **Примітка:** SQLite база `anima.db` містить всю епізодичну, семантичну пам'ять, аудит, діалогові підсумки – її видалення поверне Аніму до "пустого" стану (нуль флешів).