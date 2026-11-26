# Auster — Spec

Product name Auster (decided 2026-11-25), repo `macaiport/auster`. Concept, roadmap and open questions:
[docs/concept.md](docs/concept.md).

## Build Status

| Phase | Scope | Status |
|---|---|---|
| 0 | Scaffold: CLAUDE.md, SPEC.md, memory/, docs/, concept captured | Done 2026-11-25 |
| 1 | Household assistant built by hand on the Studio: engine, a model that fits, always-on server, one client, per-user keys, all measured | Current: planning |
| 2 | v0.1: the `household-assistant` recipe. Recipe format, from-zero installer, capability rules, and the built-in update of Auster and of its models | Planning only. [`docs/plans/v0.1.md`](docs/plans/v0.1.md) is started: the update section is drafted, and was reviewed and reworked on 2026-11-26; three sections are not written; the plan as a whole is not checked |
| 3 | `coders-companion`, the second recipe on the same format | Planning only |
| 4 | Launcher window (concept v0.2) | Planning only |
| 5 | `kids-homework-box`, `audit-tower`, trust-tier labels (concept v0.3) | Planning only |
| 6 | Multi-user hardening behind Auster's own front door (keys, limits), which also makes MLX builds possible; optional escalation-tier hook (concept v0.4) | Planning only |
| later | `brain-cluster`, contribution guidelines. **Windows and Linux on Intel** (owner, 2026-11-26: much later, not dropped) | Unscheduled |

This order was agreed on 2026-11-26 (household first) and replaces the order of the concept's roadmap.

**Required from the first release (owner, 2026-11-26):** a built-in update. Starting the model checks whether a newer Auster is
out, and Auster can move a recipe to a newer model when one is available and appropriate. It is part
of phase 2 and is designed in the v0.1 plan, so no version is ever installed without it.

**Auster stands on its own (owner, 2026-11-26).** 1launcher is where the method came from: how
releases are cut, plans are checked and findings are measured. That stays shared. It is not the guide
for Auster's design, which has problems 1launcher never had: a server that is always on, several
people, models that can be quietly worse, and rules worked out on each Mac. Auster's documents read
without opening another repo, and its update code is its own.

**Engine principle (owner, 2026-11-26):** each platform gets the engine that is best on it, decided by
measurement. The Mac need not run what Windows and Linux run. A recipe therefore names its use and its
model, and carries a separate build (engine, file, checksum) for each engine and platform.

**Engine order on the Mac (agreed 2026-11-26):** v0.1 ships on llama.cpp alone, because it has keys
and TLS built in. MLX is measured once in phase 1, on the small model, for information. MLX builds
are added when phase 6's front door exists, since MLX's own server has no keys. If the phase 1
measurement shows MLX is much better on Mistral Small 4, it moves up to right after v0.1.

**Auster assesses the Mac and adapts (owner, 2026-11-26).** Nothing that depends on memory or disk is
a fixed choice. How a model is swapped, how many stay loaded and how many earlier builds stay on disk
are rules evaluated on each Mac. A Mac with room for five models is treated as one.

**Fewest parts on the household's Mac (owner, 2026-11-26).** "Lean" means few things installed on the
person's Mac, ahead of little code for us to write. What follows from it, each to be confirmed in the
plan: v0.1 requires no Homebrew, Python or Docker; the engine's own chat page is tried before a
separate client such as Open WebUI (`llama-server` serves one by default); as few background jobs as is
safe. The shape this points to in the long run is the engine inside one native app, which is where
MLX fits.

Side tracks, not phases: the name checks and funding. Their notes are kept privately.

**Current phase:** 1 (planning)

**Next:**
1. Phase 1: confirm the engine and the order of models in [docs/shortlist.md](docs/shortlist.md)
   on llama.cpp, with one MLX measurement on the small model. Wait for disk space and for the other
   project's tests first.
2. Finish [`docs/plans/v0.1.md`](docs/plans/v0.1.md). Its update section was reviewed by seven lenses on
   2026-11-26, found to need rework, and reworked. Fourteen of its 15 decisions are answered; the last, how the server
   comes back after a restart, waits on phase 1 (D9, AD15). Still to write, from phase 1's measurements: recipe format and registry
   (Q4), installer (Q3), capability rules. Licensing stance (Q5) is also open.
3. Run `check it` on it; build only from a dated verdict.

---

## Public since 2026-11-26

The repo is public: transparency is part of the ethos, and the update
check has to be able to read it. The project is kept apart from the owner's other projects, not hidden.

What was done first:

1. Internal notes (funding, naming, the original concept note) were moved out of the tracked files into
   `private/`, which is never tracked. `docs/concept.md` is an edited public version.
2. The GitHub repo was deleted and created again from a history of one commit, so no commit carries
   those notes. The earlier history is kept privately.
3. An MIT licence, in the name of the contributors.
4. README, CHANGELOG, CONTRIBUTING, SECURITY and CODE_OF_CONDUCT.
5. A scan of every commit and file for references to the owner's other projects: none.
6. Repo settings: issues and discussions on, wiki off, private vulnerability reporting on.

Still open:

- The name checks, the trademark search among them. The repo went public before that search, knowingly.
- The rulesets on `release` and the `v` tags, which come with the first release (plan AD10).

---

## Review of the concept against the development Mac (2026-11-26)

Measured on the Mac Studio (M5 Max, 64 GB) unless a source is named.

- **Usable GPU memory is 53,084 MiB (about 55.7 GB).** Read from `llama-server --list-devices`,
  llama.cpp 0.3.0 from Homebrew. That is 81% of the total, above the concept's "⅔–¾" rule.
- **The flagship model does not fit.** The concept gives Mistral Small 4 as 119B. At exactly 4 bits
  that is 59.5 GB of weights, before any context. So the matrix row "64 GB: 119B MoE 4-bit tight" is
  wrong, and `household-assistant` as specified cannot be tested on this Mac.
- **A "4-bit" file is not 4 bits.** The Devstral Small 2 Q4_K_M file was 14,334,446,752 bytes for a
  24B model, about 4.8 bits per weight.
- **The only engine installed is llama.cpp.** No LM Studio, Ollama, MLX or Open WebUI.
- **No model is installed.** The one that was (Devstral Small 2, trialled 2026-10-26, never adopted)
  went to the Trash on 2026-11-26. The owner's decision: start fresh from the concept and do not port
  that trial.
- **The trial's measurements still stand as reference** (`runbooks/devstral.md` in the private
  `metal-working` repo):
  - It needed two chat-template fixes and a temperature setting, all specific to the client. A recipe
    must pin the template, sampling settings and client version, as well as engine, model and quant.
  - Decode ran at 30–36 tok/s and was bound by memory bandwidth; a 128K context took 33.4 GB in all.
    The capability rules need bandwidth and context, not only total memory.
  - The file came from a third-party quantizer (unsloth), not the model's publisher.
  - Its no-egress sandbox is the mechanism `kids-homework-box` and the trust tiers need.
- **The household server has not been built by hand yet.**
- **Checked later the same day** ([docs/shortlist.md](docs/shortlist.md)):
  Mistral Small 4 is 119.4B and Apache 2.0, with no service clause in its licence field; its 4-bit
  files are 69.5–73.8 GB. Apertus 70B fits at 4 bits (43.7 GB).
- **Disk:** the Studio had 64.2 GB free of 2.0 TB on 2026-11-26. Phase 1's candidates are about
  44 GB each. **Planning assumption (owner, 2026-11-26): at least 500 GB will be free** once another
  project's tests finish and its files are tidied. Until the space is really there, nothing large is
  downloaded. Measurements also wait for those tests to end, because both would be competing for the
  same memory bandwidth.

---

## Phase 1 — the household assistant, by hand

No product code. The aim is one working household server on the Studio, and the measurements the
v0.1 plan needs. What is done by hand is written down in order in [docs/phase-1.md](docs/phase-1.md).

**The checks Auster will make are made by hand first, and nobody's word is taken for them:** free
disk, memory, what else is running, and whether the publisher still offers the pinned file. They are
run again before each download and each measurement.

### Scope
- Engine: llama.cpp (agreed). Choose the model from the three in the shortlist: about 55.7 GB is
  usable by the GPU, and context and several users need room inside that.
- Measure MLX once on the small model, same questions and context size, and record the difference.
  Preferably through the Swift MLX stack Osaurus uses ([docs/shortlist.md](docs/shortlist.md)), since
  Python is not something Auster would ship.
- Run it as an always-on server that comes back after a restart and answers at a fixed name on the
  home network.
- One client that works from an iPad, with a separate key for each person.
- Proposed as out of scope: fail-over to a second Mac (concept Q2).

### Exit criteria (draft, to be confirmed)
1. The model is chosen, with the reason and the alternatives that were measured, and the one MLX
   measurement is recorded beside llama.cpp's.
2. Written down from measurement: memory in use at the working context, prefill and decode speed,
   and the time to a first answer after a restart.
3. Two people use it from two devices at the same time, each with their own key. Revoking one key
   stops that person only.
4. The Mac restarts and the server is answering again without anyone touching it. **Not true of the
   Studio as it is set up:** FileVault is on and restart after a power cut is off (measured
   2026-11-26), so someone has to unlock the disk first. The plan's decision AD15 settles how.
5. Every step done by hand is written down in order. Phase 2 turns that list into the installer.

### Test plan (draft)
Each criterion is tested by doing it and recording what was seen, with the command and its output.
Criterion 3 is run with a key that was never issued as well, which must be refused.

### Rollback
Everything phase 1 installs is listed as it goes in, with the way to remove it. Nothing else on the
Studio depends on it.
