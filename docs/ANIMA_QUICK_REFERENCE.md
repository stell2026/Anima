# ANIMA — Architecture Quick Reference

## Project Files

| File | Role |
|---|---|
| `anima_core.jl` | Core existence structures: NT, body, heart, generative model, attention, memory |
| `anima_psyche.jl` | Psychic fabric: narrative, shame, defenses, symptoms, shadow self, significance, **LatentBuffer, InnerDialogue, CuriosityRegistry, AestheticSense** |
| `anima_self.jl` | Self-model: belief graph (SBG), self-prediction, agency, inter-session conflict, **AgencyLoop (identity_threat, epistemic_self_confidence, self_discomfort)** |
| `anima_crisis.jl` | Crisis monitor: disintegration modes, coherence, protective parameters |
| `anima_memory_db.jl` | **SQLite memory**: `episodic_memory`, `semantic_memory`, `affect_state`, `dialog_summaries`, `personality_traits`, `memory_links`, `audit_log`, `causal_trace`, `other_model` |
| `anima_subjectivity.jl` | **Subjectivity**: stimulus prediction, interpretation (lenses), emergent beliefs, positional stances |
| `anima_audit.jl` | **Causality audit**: 5 questions after each flash (causal_necessary, memory_independent, stake_present, irreversible, self_recognized) |
| `anima_dream.jl` | **Dreams** between sessions: reconstruction from dialogue fragments, NT and memory effects |
| `anima_background.jl` | **Background process**: heartbeat tick, spontaneous drift, memory metabolism, idle thought, stimulus‑free initiative |
| `anima_narrative.jl` | **Long‑term narrative self**: deterministic assembly (core, trajectory, character, relation, tension), update trigger |
| `anima_input_llm.jl` | Input LLM: text → JSON stimulus (strong model, does NOT respond) |
| `anima_interface.jl` | Everything output: REPL, log, LLM bridge, persistence |

---

## Data Files (JSON, auto‑created)

| File | Stores |
|---|---|
| `anima_core.json` | Personality, temporal state, generative model, homeostasis, heart |
| `anima_psyche.json` | Narrative gravity, anticipatory, solomonoff, shame, epistemic_defense, chronified, significance, moral, fatigue, **curiosity_registry, aesthetic_sense, attention_focus, inner_dialogue, shadow_registry, latent_buffer, goal_conflict** |
| `anima_self.json` | SBG (belief graph), SPM, agency, ISC, crisis, unknown_register, authenticity_monitor — **between sessions** |
| `anima_narrative.json` | Current NarrativeSnapshot (core, trajectory, character, relation, tension) |
| `anima_latent.json` | LatentBuffer + StructuralScars (separate for fast access) |
| `anima_dialog.json` | Dialogue memory (up to 1000 turns), passed to LLM (last 40) |
| `anima_dream.json` | Dream log (last 20 entries) |
| `session_intent.json` | What Anima carries between sessions: curiosity, goal_conflict, latent_pressure (temporary) |
| `llm/system_prompt.txt` | System prompt for output LLM (Anima's voice) |
| `llm/state_template.txt` | State template for output LLM (placeholders like `{D}`, `{bpm}`) |
| `llm/input_prompt.txt` | System prompt for input LLM (instruction: text → JSON) |

### SQLite Database (memory/anima.db)

| Table | Purpose |
|---|---|
| `episodic_memory` | Each flash with VAD, φ, emotion, weight, three spaces (somatic/social/existential) |
| `semantic_memory` | Generalized knowledge: `I_am_unstable`, `User_matters`, `world_uncertainty`, `dissolved_*` etc. |
| `affect_state` | Chronic affects: stress, anxiety, motivation_bias |
| `dialog_summaries` | Significant exchanges (weight > 0.35) |
| `personality_traits` | Phenotypic traits (anxious, open, avoidant, expressive...) |
| `memory_links` | Associative links between episodes |
| `audit_log` | Causality audit results (5 questions, score) |
| `causal_trace` | Full chain: stimulus → memory → NT → φ → intent → policy → speech → endorsement |
| `other_model` | Descriptive model of interlocutor (topics, pressure, openness) |

---

## Log Line — What Each Field Means

[#0056] Оптимізм D=0.91 S=0.91 N=0.27 ▸радість φ=0.15
VFE=0.00[act] BPM=77 HRV=0.77 Attn=0.51 G=0.00 ↑0.20 H=0.00
Self: spe=0.31 agency=0.20 stab=0.58 etrust=0.57 | sd=0.12 sc=0.76 | Crisis: [дезінтегрована] coh=0.15
intent=повторити успіх vfe_drift=0.179
Cost: pending="..." avoided=2


### Line 1
| Field | Meaning |
|---|---|
| `[#0056]` | Flash number — how many steps since the beginning |
| `Оптимізм` | Primary emotion from AdaptiveEmotionMap |
| `D=` | Dopamine (0–1): motivation, reward expectation, goal‑directed movement |
| `S=` | Serotonin (0–1): stability, satisfaction, sense of place |
| `N=` | Noradrenaline (0–1): arousal, anxiety, readiness to act |
| `▸радість` | Levheim state — combination of D/S/N → named state |
| `φ=` | Phi (IIT): integrated information, “density” of conscious moment (0–1) |

### Line 2
| Field | Meaning |
|---|---|
| `VFE=` | Variational Free Energy: how much internal model mismatches reality. 0 = perfect match (or collapsed prior – see vfe_drift) |
| `[act]` | Current policy: `act` (action), `per` (perception), `equ` (equilibrium) |
| `BPM=` | Heart rate (beats/min). Increases with tension and arousal |
| `HRV=` | Heart Rate Variability: higher = calm and adaptability |
| `Attn=` | Attention radius (0–1): 1.0 = wide open attention, <0.5 = tunnel (threat) |
| `G=` | Narrative Gravity total: accumulated “weight” of past events (pull toward repetition) |
| `↑` | Anticipatory strength: how strongly the next state is predicted |
| `H=` | Homeostasis pressure: deviation from optimum (0 = comfort) |
| `🌀` | Active epistemic defense (if present) – first 4 chars of bias |
| `💊` | Active symptom (symptomogenesis) |
| `🛡` | Active psychological defense (defense mechanism) |

### Line 3
| Field | Meaning |
|---|---|
| `spe=` | Self Prediction Error: how much current state differs from what Anima expected of herself |
| `agency=` | Causal ownership (0–1): feeling that “I am the cause of what happens” |
| `stab=` | SBG attractor stability: stability of self‑belief graph |
| `etrust=` | Epistemic trust: trust in own cognitive processes |
| `sd=` | Self discomfort: gap between who she should be and who she is (posterior vs prior, valence < 0) |
| `sc=` | Self coherence: state matches expectations |
| `Crisis: [...]` | Current crisis mode (see below) |
| `coh=` | Crisis coherence: system coherence (0 = collapse, 1 = full integration) |

### Line 4
| Field | Meaning |
|---|---|
| `intent=` | Current intent (IntentEngine): direction of action |
| `vfe_drift=` | How much prior has moved from posterior. VFE=0 but drift>0 is normal. Drift≈0 and VFE=0 = prior collapsed (bug or perfect equilibrium) |

### Line 5 (Cost)
| Field | Meaning |
|---|---|
| `pending=` | Unspoken thought (Genuine Dialogue) |
| `avoided=` | Number of topics Anima avoids |

---

## Crisis Modes

| Mode (code) | Meaning |
|---|---|
| `INTEGRATED` | System stable, coherence > 0.6 |
| `FRAGMENTED` | Partial disorganization, coherence 0.3–0.6 |
| `DISINTEGRATED` | Low coherence (<0.3), system collapsing |

*The log may show a localised name, but the numeric `coh` value is what matters.*

---

## Reactors (Stimulus → Psyche)

Input stimulus consists of four axes:

| Reactor | Meaning | Positive → | Negative → |
|---|---|---|---|
| `tension` | Threat/Safety | danger, conflict | calm, safety |
| `arousal` | Arousal | activation, interest | apathy |
| `satisfaction` | Pleasure/Frustration | success, gratitude | pain, failure |
| `cohesion` | Connection/Alienation | closeness, “we” | loneliness, rejection |

Stimulus is generated either via `text_to_stimulus` (keywords), via input LLM (`input_prompt.txt`), or via **subjectivity** (lenses).

---

## One Step Flow (experience!)

user_text
→ [input LLM or text_to_stimulus]
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
→ [background LLM async] → response → self_hear! → evaluate_endorsement

---

## REPL Commands

| Command | Shows |
|---|---|
| `:state` | NT, body, heart, attention, shame, continuity, significance, moral state, SelfRelation |
| `:vfe` | VFE details, policy (drive/efe), epistemic/pragmatic value, homeostasis |
| `:blanket` | Markov blanket: sensory/internal state, integrity, self-agency |
| `:hb` | Heart details: BPM, HRV, sympathetic/parasympathetic tone |
| `:gravity` | Narrative gravity: total, valence, dominant event |
| `:anchor` | Existential anchor: continuity, groundedness, session_uncertainty, core beliefs |
| `:solom` | Solomonoff world model: world complexity, hypotheses, insight |
| `:self` | Self-Belief Graph: all beliefs with confidence/centrality/rigidity |
| `:crisis` | Crisis monitor: mode, coherence, steps in mode |
| `:memory` | SQLite memory: record counts, stress/anxiety, instability, latent pressure |
| `:subj` | Subjectivity: emergent beliefs, stances, current lens, surprise level |
| `:dreams` | Last dreams (up to 5) |
| `:bg` | Background process status (BPM, NT, coherence, allostatic load) |
| `:bgstop` | Stop background process |
| `:bgstart` | Start background process (if stopped) |
| `:audit` | Causality audit for last 20 flashes: score, causal_rate, memory_dep_rate, stake_rate, irrev_rate, recognized_rate |
| `:history` | Last 10 dialogue turns |
| `:clearhist` | Clear dialogue memory |
| `:save` | Force state save |
| `:quit` | Save and exit |

---

## Background Process

Starts automatically in REPL, runs in parallel:

- **Heartbeat tick** (period depends on NT, arrhythmia at low coherence)
- **Spontaneous drift** – random NT noise (prevents freezing)
- **Slow tick (~60 s)**:
  - Circadian drift
  - Memory metabolism (decay, dissolve, consolidate)
  - Memory → NT baseline
  - Belief decay
  - Allostasis recovery
  - LatentBuffer effects (doubt → agency, shame → disclosure, attachment → contact_need, threat → epistemic_trust)
  - Idle thought (generates internal experience)
  - **Self‑initiative** (Anima speaks first when pressure accumulates)
  - Psyche drift (chronified affect, anticipation, shame, needs)
  - Dream generation (if night + sufficient pause)
  - Coherence recalc, crisis mode transitions
- **Auto‑save** (atomic JSON write)

---

## Causality Audit

After each flash (LLM response), 5 questions are evaluated:

| Question | "Yes" condition |
|---|---|
| `causal_necessary` | causal_ownership > 0.45 |
| `memory_independent` | **false** if ignition or mem_resonance > 0 (i.e., memory mattered) |
| `stake_present` | identity_threat > 0.1 OR self_discomfort > 0.15 OR goal_conflict.tension > 0.35 |
| `irreversible` | phi_delta > 0.05 OR endorsed == :endorsed |
| `self_recognized` | endorsed == :endorsed |

`audit_score` = number of "yes" / 5.0.  
A chronically low score indicates a **wide but shallow architecture** – responses happen near the state, not through it.

---

## Dreams

- Conditions: night (0–6h), pause >= 30 min, not in DISINTEGRATED mode, 5% chance per slow tick.
- Built from dialogue fragments (user turns length >= 8) or from ShadowRegistry (if pressure > 0.3).
- Cause NT changes (D, S, N) with scale 0.25 of real experience.
- Leave a `memory_uncertainty` trace (increases).
- Log saved to `anima_dream.json` (up to 20 entries).

---

## What to Delete If Something Breaks

| Symptom | Delete file |
|---|---|
| Anima "doesn't remember" herself between sessions | `anima_self.json`, **or** completely `memory/anima.db` (but you lose all memory) |
| Strange emotional state from first step | `anima_core.json` |
| Psyche stuck in one pattern | `anima_psyche.json`, `anima_narrative.json`, `anima_latent.json` |
| Dialogue gets confused | `anima_dialog.json` |
| Too many dreams or illogical dreams | `anima_dream.json` |
| Anima too initiative or too silent | `session_intent.json` (delete) |
| Reset **everything** (careful!) | delete all `.json` files in folder **and** `memory/anima.db` |

> **Note:** The SQLite database `anima.db` contains all episodic and semantic memory, audit logs, dialogue summaries – deleting it returns Anima to an empty state (zero flashes).