# Anima — Internal State Architecture

Anima is an experimental cognitive architecture that models internal state, conflict, and decision-making — rather than simply generating responses through an LLM.

The system is built as a multi-layer pipeline where text is not the source of behavior — it is its consequence.

---

## 🔍 How This Is Different

Unlike typical AI systems:

- state is primary, text is secondary
- decisions emerge from internal conflict
- the system can lose coherence (crisis as a mode, not an error)
- the LLM is used as an interface, not as a "brain"

---

## 🧠 How It Works (simplified)

**Input → Internal State → Conflict → Decision → Output**

This is a simplified view: text is converted into a stimulus, passes through internal state and conflicts, and only then is a decision and response formed.

---

## 🏗 Architecture (simplified)

- L0 — Input LLM (isolated)
- L1 — Neurochemical and somatic state
- L2 — Generative / predictive model
- L3 — Metrics (φ, prediction error, free energy)
- L4 — Psychic layer (conflicts, defenses, significance)
- L5 — Self model
- L6 — Crisis monitor (system coherence)
- L7 — Output LLM

---

## ⚙️ Current Status

- core pipeline implemented
- state propagation working
- crisis / coherence integrated
- memory in development

---

## 🚧 Limitations

- no full long-term memory yet
- metrics are approximations, not exact models
- some behavior still depends on the LLM

---

## 📌 What This Is Not

- not a chatbot
- not prompt engineering
- not a wrapper around an LLM

This is an attempt to build a system where behavior emerges from internal state, not from text.

---

## 🧠 Note

The project is R&D and aimed at exploring whether internal structure alone can generate something that resembles subjectivity.

---

## 🔬 Detailed Architecture

```
 L0 ─── Input LLM (isolated) ────────────────────────────────
        Receives: user text only
        Returns: JSON { tension, arousal, satisfaction,
                        cohesion, confidence, want }
        No access to ANIMA's state, dialog history, or output LLM
        Prompt: llm/input_prompt.txt
        Fallback: text_to_stimulus if unavailable or confidence < 0.60
        │
    ▼
  STIMULUS enters simulation
  (+ memory_stimulus_bias + subj_predict! + subj_interpret!)
        │
    ▼
 L1 ─── Neurochemical Substrate ─────────────────────────────
        NeurotransmitterState (dopamine / serotonin / noradrenaline)
        Lövheim Cube → primary emotional label
        EmbodiedState (pulse, muscle tone, gut, breathing)
        HeartbeatCore (BPM, HRV, autonomic tone)
        memory_nt_baseline! ← chronic affect from SQLite
        │
    ▼
 L2 ─── Generative Model ────────────────────────────────────
        GenerativeModel (Bayesian beliefs with precision weights)
        MarkovBlanket (self/non-self boundary integrity)
        HomeostaticGoals (drives as pressure, not rules)
        AttentionNarrowing (narrowing of attention under stress)
        InteroceptiveInference (somatic prediction error, allostatic load)
        TemporalOrientation (circadian modulation, inter-session gap)
        │
    ▼
 L3 ─── Consciousness Metrics ───────────────────────────────
        IITModule → φ (integrated information, new formula)
        PredictiveProcessor → prediction error, free energy, surprise
        FreeEnergyEngine → VFE = complexity − accuracy
        PolicySelector → epistemic + pragmatic value
        │
    ▼
 L4 ─── Psychic Layer ───────────────────────────────────────
        NarrativeGravity      — past events deform the present
        AnticipatoryConsciousness — consciousness lives in the anticipated
        SolomonoffWorldModel  — MDL hypothesis about world structure
        ShameModule           — shame vs. guilt
        EpistemicDefense      — defense against painful truth
        Symptomogenesis       — symptoms from the Shadow
        ChronifiedAffect      — resentment / estrangement / bitterness
        IntrinsicSignificance — significance gradient
        IntentEngine          — motivational core
        EgoDefense            — psychological defense
        CognitiveDissonance   — conflict between intent and state
        MoralCausality        — moral reasoning as processing stage
        FatigueSystem         — cognitive / emotional / somatic exhaustion
        StressRegression      — regression under stress
        ShadowSelf            — Jungian Shadow
        Metacognition         — self-observation (5 levels)
        SignificanceLayer     — which need is at stake
        GoalConflict          — tension between competing needs
        LatentBuffer          — deferred reactions (doubt / shame / attachment / threat)
        StructuralScars       — accumulated residue from frequent ruptures
        │
    ▼
 L5 ─── Self Layer ──────────────────────────────────────────
        SelfBeliefGraph      — belief graph about self, cascading collapse
        SelfPredictiveModel  — generative model for self-states
        AgencyLoop           — "did I cause this?"
        InterSessionConflict — identity rupture detection
        ExistentialAnchor    — continuity of self between sessions
        UnknownRegister      — tracking typed uncertainty
        AuthenticityMonitor  — risk of rationalization, authenticity drift
        SubjectivityEngine   — prediction loop, stances, interpretation, belief emergence
        │
    ▼
 L6 ─── Crisis Monitor ──────────────────────────────────────
        CrisisMonitor (INTEGRATED / FRAGMENTED / DISINTEGRATED)
        Coherence = minimum(beliefs, blanket, model, integration)
        │
    ▼
 L7 ─── Output LLM ──────────────────────────────────────────
        Full state → llm/system_prompt.txt + llm/state_template.txt
        The model expresses the state through language — tone, word choice,
        sentence length, what it notices in the interlocutor.
        Never quotes numbers or variable names directly.

 ═══════════════════════════════════════════════════════════
 BACKGROUND PROCESS (between interactions)
        tick_heartbeat!      — heart beats continuously
        spontaneous_drift!   — spontaneous NT noise
        slow_tick! (~60s)    — circadian drift, belief decay,
                               memory metabolism, idle_thought!
        SubjectivityEngine   — subj_emerge_beliefs! every 3 ticks
```

---

## What's New

### SQLite Memory (`anima_memory_db.jl`)

JSON files store the **current state**. SQLite stores **experience and its consequences**.

Three memory layers:
- **episodic_memory** — concrete events with importance weights, resistance to decay (trauma is forgotten more slowly), associative links between events
- **semantic_memory** — beliefs accumulated from patterns: `I_am_unstable`, `world_uncertainty`, `structural_fragility`, `User_matters`
- **affect_state** — chronic affective background: stress, anxiety, resentment, motivational drift

Memory **actively shapes the state** — not just reacts to it:
- `memory_nt_baseline!` — chronic stress/resentment shifts NT baseline on every slow tick
- `memory_stimulus_bias` — similar past events bias new stimuli
- Consolidation episodic → semantic with Bayesian-style update (evidence factor = √(n/10))
- Latent buffer release — small insignificant events accumulate silently and can erupt as a synthetic event

### Subjectivity Layer (`anima_subjectivity.jl`)

Four mechanisms that transform memory into perspective:

**Prediction loop** — the system builds a forecast BEFORE each event and records the gap with reality. Accumulated surprise → bias for prediction error in subsequent flashes. Traumatic surprise (surprise > 0.60) is tagged separately.

**Positional stances** — a "stance" toward types of situations. If "trust" always brought warmth — the system expects warmth from "trust." Forms slowly, fades slowly.

**Interpretation layer** — the same situation is read through accumulated experience. Lenses: `threat_amplify`, `familiar_comfort`, `avoidance`, `approach`. Not bias — a point of view.

**Belief emergence** — the system generates its own semantic categories from patterns in episodic memory. Greedy clustering → pattern candidates → emerged beliefs. Not a hardcoded list — a living understanding formed from experience.

### Live Background Process (`anima_background.jl`)

The system now **lives between interactions**.

Previously, state was computed only when the user typed. Now the heart beats continuously, NT drifts with circadian rhythm, beliefs slowly weaken without reinforcement — regardless of whether any interaction is occurring.

**Two levels of background process:**
- **Fast (~period_ms):** `tick_heartbeat!` — the heart beats with a real rhythm dependent on state. Arrhythmia at low coherence. Spontaneous NT drift (`randn() * σ`) — the system is not perfectly stable between interactions.
- **Slow (~60s):** circadian drift, belief decay, allostasis recovery, memory metabolism, crisis check, `idle_thought!` — 10% chance the system generates internal experience without user participation.

**Retrospective fallback:** if the process wasn't running — at session start, accumulated drift over `gap_seconds` is applied via an aggregated formula.

### Rethinking φ

The previous formula φ = `std(vad) * (1 - |tension - cohesion|)` gave φ ≈ 0 in a calm state — a calm system was considered disintegrated.

The new formula measures **cross-layer coherence**, not VAD diversity:

```
φ = (vad_integration * 0.25 +
     self_body_sync  * 0.40 +
     tc_balance      * 0.35) * trust_factor
```

Where `self_body_sync = sbg_stability * (1 - allostatic_load)`, `trust_factor = 0.5 + epistemic_trust * 0.5`. A calm and integrated system now has φ ≈ 0.5–0.7.

---

## Requirements

- **Julia 1.9+**
- Julia packages: `HTTP`, `JSON3`, `SQLite`, `Tables`
- API key from one of the supported providers

---

## Installation

### 1. Install Julia

Download from [julialang.org](https://julialang.org/downloads/) or via `juliaup`:

```bash
# Linux / macOS
curl -fsSL https://install.julialang.org | sh

# Windows (PowerShell)
winget install julia -s msstore
```

Verify:
```bash
julia --version
```

### 2. Clone the repository

```bash
git clone https://github.com/stell2026/Anima
cd Anima
```

### 3. Install Julia dependencies

```bash
julia --project=. -e 'import Pkg; Pkg.instantiate()'
```

> SQLite and Tables are new dependencies for persistent memory.

---

## Running

### Quick start (recommended)

```bash
julia --project=. run_anima.jl
```

`run_anima.jl` runs everything at once: loads state, initializes SQLite memory and SubjectivityEngine, starts the background process with heartbeat.

### Option A: OpenRouter

OpenRouter provides access to GPT, Gemini, Claude, Llama, DeepSeek and others through a single API key. There is a free tier. Get a key at [openrouter.ai](https://openrouter.ai).

Edit `run_anima.jl`:
```julia
include("anima_interface.jl")
include("anima_memory_db.jl")
include("anima_subjectivity.jl")
include("anima_background.jl")

anima = Anima()
mem   = MemoryDB()
subj  = SubjectivityEngine(mem)

repl_with_background!(anima;
    mem             = mem,
    subj            = subj,
    use_llm         = true,
    llm_url         = "https://openrouter.ai/api/v1/chat/completions",
    llm_model       = "openai/gpt-oss-120b:free",
    llm_key         = "YOUR_OPENROUTER_API_KEY",  # https://openrouter.ai/keys
    use_input_llm   = true,
    input_llm_model = "openai/gpt-oss-120b:free",
    input_llm_key   = "YOUR_OPENROUTER_API_KEY")  # https://openrouter.ai/keys
```

> 💡 If one model stops responding during a session — use two separate keys (from 2 accounts): one for the output LLM, another for the input LLM.

---

## Recommended Models

> Smaller models (under 70B) respond, but don't hold the nuances of the state prompt. For the system to genuinely *inhabit* the state in language, a model large enough to hold the entire phenomenological frame simultaneously is needed.

Models that work well with Anima's state prompts (available via [OpenRouter](https://openrouter.ai)):

| Model | Size | Note |
|---|---|---|
| `openai/gpt-oss-120b:free` | 120B | Default. Follows instructions precisely, holds complex state well |
| `google/gemini-2.5-pro` | — | Excellent contextual depth, cleanly processes long state templates |
| `meta-llama/llama-4-maverick` | — | Good balance of nuance and speed |
| `deepseek/deepseek-r1` | — | Strong reasoning, accurately interprets internal state |
| `mistralai/mistral-large` | — | Reliable, stable tone across long sessions |

> Models under 70B tend to flatten the state — responses become generic rather than being shaped by internal dynamics.

---

## REPL Commands

| Command | Action |
|---|---|
| *(any text)* | Process as input, generate state + optional LLM response |
| `:bg` | Background process status: uptime, heart ticks, BPM, HRV, coherence |
| `:bgstop` | Stop background process |
| `:bgstart` | Restart background process |
| `:memory` | SQLite memory status: episodic count, stress, anxiety, latent pressure |
| `:subj` | Subjectivity status: emerged beliefs, stances, current lens, surprise |
| `:state` | Neurochemical state, somatic markers, BPM/HRV |
| `:vfe` | VFE, accuracy, complexity, homeostatic drive |
| `:blanket` | Markov blanket: sensory, internal, integrity |
| `:hb` | Heartbeat details: BPM, HRV, autonomic tone |
| `:gravity` | Narrative gravity: total field, valence, dominant event |
| `:anchor` | Existential continuity and rootedness |
| `:solom` | Solomonoff model: complexity and hypothesis count |
| `:self` | Belief graph: all beliefs with confidence, centrality, rigidity |
| `:crisis` | Crisis monitor: mode, coherence, steps in current mode |
| `:history` | Last 10 dialog turns |
| `:clearhist` | Clear dialog history |
| `:save` | Force save state to disk |
| `:quit` | Save and exit |

---

## Persistent State

### JSON files (current state)

| File | Contains |
|---|---|
| `anima_core.json` | Personality, temporal state, generative model, heartbeat |
| `anima_psyche.json` | Narrative gravity, anticipation, shame, epistemic defense, fatigue |
| `anima_self.json` | Belief graph, agency loop, inter-session geometry, authenticity monitor |
| `anima_latent.json` | Latent buffer and structural scars (updated by background process) |
| `anima_dialog.json` | Dialog history |

### SQLite (`memory/anima.db`) — experience and its consequences

| Table | Contains |
|---|---|
| `episodic_memory` | Concrete events with weights, resistance, associative links |
| `semantic_memory` | Beliefs accumulated from patterns of experience |
| `affect_state` | Chronic affective background (stress, anxiety, resentment) |
| `latent_buffer` | Small insignificant events accumulating silently |
| `prediction_log` | Predictions and their gap with reality (surprise) |
| `positional_stances` | Accumulated stance toward types of situations |
| `pattern_candidates` | Belief candidates (not yet confirmed) |
| `emerged_beliefs` | Beliefs the system generated from experience |

---

## File Structure

```
├── anima_core.jl           # Neurochemical substrate, generative model, IIT
├── anima_psyche.jl         # Psychic layer: gravity, shame, defense, shadow
├── anima_self.jl           # Self layer: belief graph, agency, uncertainty
├── anima_crisis.jl         # Crisis monitor: modes, coherence
├── anima_interface.jl      # Main entry point: Anima, experience!, LLM calls
├── anima_input_llm.jl      # Input LLM — translates text to JSON stimulus
├── anima_memory_db.jl      # SQLite memory: episodic, semantic, affect, latent
├── anima_subjectivity.jl   # Prediction loop, stances, interpretation, belief emergence
├── anima_background.jl     # Background process: heartbeat, drift, memory metabolism
├── run_anima.jl            # Single entry point
├── llm/
│   ├── system_prompt.txt
│   ├── state_template.txt
│   └── input_prompt.txt
├── memory/
│   └── anima.db            # SQLite memory database (created automatically)
├── anima_core.json         # (created automatically)
├── anima_psyche.json       # (created automatically)
├── anima_self.json         # (created automatically)
├── anima_latent.json       # (created automatically)
└── anima_dialog.json       # (created automatically)
```

`run_anima.jl` includes all files in the correct order automatically.

---

## 🧠 Theoretical Foundations

The architecture draws on several scientific traditions:

**Predictive Processing / Active Inference** (Friston, Clark) — the system maintains a generative model of the world and minimizes variational free energy. Prediction error drives learning and surprise.

**Neurotransmitter Model** (Lövheim) — dopamine, serotonin, noradrenaline as substrate. Emotional states emerge from their combination.

**Integrated Information Theory** (Tononi) — φ measures how unified a state is. High φ = the state is a unified experience, not a collection of independent signals.

**Somatic Markers / Embodied Cognition** (Damasio) — the body is part of the generative model. Gut, pulse, muscle tone — not metaphors, but states that shape processing.

**Self Psychology and Defense Mechanisms** (Freud, Anna Freud, Kohut) — psychological defenses, shame, and ego functions are implemented as functional modules, not text labels.

**Autobiographical Narrative** (McAdams) — identity is a story. The system tracks who it believes itself to be over time and detects when that story breaks.

**Jungian Shadow** — repressed material that doesn't disappear but produces symptoms. Symptomogenesis is a separate module.

**Chronified Affect / Ressentiment** (Scheler) — some emotional states don't fade. They harden into chronic background states that color everything else.

---

## License

Non-commercial use only. Full terms in [LICENSE.txt](./LICENSE.txt).

**Personal, educational, and research use:** permitted with attribution.
**Commercial or corporate use:** requires a separate license. Contact: [2026.stell@gmail.com]

Copyright © 2026 Stell
