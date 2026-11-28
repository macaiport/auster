# Auster — Spec

Product name Auster (decided 2026-11-25), repo `macaiport/auster`. Concept, roadmap and open questions:
[docs/concept.md](docs/concept.md).

## Build Status

| Phase | Scope | Status |
|---|---|---|
| 0 | Scaffold: CLAUDE.md, SPEC.md, memory/, docs/, concept captured | Done 2026-11-25 |
| 1 | Household assistant built by hand on the Studio: engine, a model that fits, always-on server, one client, per-user keys, all measured | Current: under way. Models A, B and C measured and quizzed; MLX compared; keys, the chat page and an iPad on the home network tested ([docs/phase-1.md](docs/phase-1.md)). Left: two devices with one key revoked, and the restart tests (AD15). The model is chosen (plan A6) and a cold start measured (step 10) |
| 2 | v0.1: the `household-assistant` recipe. Recipe format, from-zero installer, capability rules, and the built-in update of Auster and of its models | Building. V1 to V8 built and tested (`tests/run.sh`: the test stubs and fixtures, the registry reader and gate, section C, the recipe's test, the first install: `install.sh` and `common/driver.sh`; the engine job and the check job; keys, the QR code, the `auster` command and removal; the repo's own `registry.tsv`, `assets/` and recipe folder), order 1's chat template patched where it failed on some dates (BD20); U1, the update's rule file, U2, the records' readers and the ownership rule, U3, the registry fetch and each recipe's line, U4, `auster update` and the update run up to its question, and U5, the update's yes to the end (Auster's programs first, a change of setting and `auster people`, the checks with the publisher, the download, the isolated test and both ways of switching), and U6, `auster rollback`, `hold`, `auster unhold`, `auster cleanup` and the disk rule's and `auster verify`'s tests, built; U7, the update-waiting notification and the ownership rule in both jobs, built; U6's third part, an update that repairs a changed file of the build in use before Auster's programs change, built; U8 and U9 next. [`docs/plans/v0.1.md`](docs/plans/v0.1.md) is drafted in full (2026-11-26). The whole plan was reviewed the same day (pass 2, seven lenses), found to need rework, and reworked; re-checked six times and each pass's fixes folded; the owner accepted BD8 to BD20. **check-it'd 2026-11-26 — build-ready-with-fixes (pass 2g)**. V1 begun (`tools/mint-id`, `tests/run.sh`). Phase 2's first step settled the facts that can be settled on the development Mac ([docs/phase-2.md](docs/phase-2.md)) |
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

Side tracks, not phases: funding, whose notes are kept privately. The name is settled (2026-11-28).

**Current phase:** 2, building: V1 to V8 and U1 to U7 done, with U6's third part; U8 and U9 next. Phase 1's last items need the owner, and so do three of phase 2's first-step checks ([docs/phase-2.md](docs/phase-2.md)). The household recipe's model is chosen: Mistral Small 4, then Magistral Small (plan A6)

**First beta (owner, 2026-11-28):** installable well before 2026-12-17, for a few testers. It is
**v0.1.0**, with "beta" said in the README and on auster.build; fixes go out as v0.1.1 and up, through the
built-in update. In order: a real install from zero on the Studio (begun 2026-11-28); U6's third part; U9
and the first `release` branch and tag (public, on the owner's word); the D12 checks at the Mac; U8 as
v0.1.1, taken by the Studio as the first real update; auster.build's how-to. Then `auster report`, a report
a tester reads and emails to reports@auster.build ([`docs/plans/report.md`](docs/plans/report.md), checked
build-ready-with-fixes 2026-11-28), as a v0.1.x; the owner sets that address up with the domain. A tester's Mac, by section C:
Apple Silicon with 32 GB or more (24 GB is refused), on macOS 27 (BD15).

**The README by 2026-12-16** (owner, 2026-11-28), each line only once it is true: the status, dated, and
"beta" only after v0.1.0 is tagged; the households it is in daily use in, as a count; what was measured on
which Mac (added 2026-11-28); which of "What it is meant to do" v0.1.0 does and which are planned, with no
link to data centers claimed before it works; a link to auster.works once that site is live; auster.build
once it is a site, not a redirect here. The mark at the top only if the owner chooses it.

**Next:**
1. Phase 1's last items: the restart tests for AD15 (they need the owner at the Mac and an administrator),
   and two devices at once with one key revoked.
2. The D12 checks that need the owner: the iPad reading the QR
   code, a launchd job for the engine's speeds, and `auster update` opening its `.command` file in
   Terminal at the Mac's screen (the tests replace `open`, so no test opens Terminal).
3. Build the rest of the update: withdrawn builds (U8), and the release gate (U9).

**Auster's icon on the Mac (owner, 2026-11-28):** the app icon in `docs/brand/app-icon/` is to be Auster's own
icon wherever it shows in Finder or the Dock. v0.1 puts nothing there yet; the first thing to carry it would be a
double-clickable Auster that opens the chat page ([`docs/plans/app.md`](docs/plans/app.md), checked
2026-11-28). **The owner registers as an Apple Developer in the week of 2026-11-30** (2026-11-28), so that
Auster's app can later be signed and notarized; how a signed app reaches a Mac through the installer, which
fetches a git tree, is not known yet and is a plan of its own.

**Parked, for later discussion** (not phased, not in any plan): [docs/concepts/](docs/concepts/).
- [central-services.md](docs/concepts/central-services.md): a central service that Auster works
  without: a collector of figures shared back, and a relay to data centers that pools households and
  keeps nothing (2026-11-27).

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

- ~~The name checks.~~ **Settled by the owner on 2026-11-28:** searches found no prior art, no legal
  clearance is sought, and the name stays Auster.
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
4. The Mac restarts and the server is answering again without anyone touching it. **Not true of a
   Mac with FileVault on, or with restart after a power cut off:** someone has to start the Mac or
   unlock its disk first. The plan's decision AD15 settles how.
5. Every step done by hand is written down in order. Phase 2 turns that list into the installer.

### Test plan (draft)
Each criterion is tested by doing it and recording what was seen, with the command and its output.
Criterion 3 is run with a key that was never issued as well, which must be refused.

### Rollback
Everything phase 1 installs is listed as it goes in, with the way to remove it. Nothing else on the
Studio depends on it.
