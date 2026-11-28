# Auster

Local AI on Apple Silicon, one recipe per use. The free stack (engines, weights, clients) already
exists, but putting it together takes a weekend in Terminal. This project assembles it into curated
recipes with one-line installs and double-clickable results, the way
[1launcher](https://github.com/macgameport/1launcher) does for Windows games on the Mac. A recipe is one
folder: model, quant, server config and client setup, with pinned checksums and measured findings.
The full concept, roadmap and open questions are in [docs/concept.md](docs/concept.md).

## Name and home
- The product is **Auster**, decided 2026-11-25. Its home on GitHub is `macaiport/auster`, the
  counterpart to `macgameport/1launcher`. This local folder is still called `macaiport`.
- The name checks still open are listed in `private/`.
- **Two sites** (owner, 2026-11-28). `auster.build` is the technical site: the how-to, what connects to
  the server, the support contact and the roadmap. Its documentation, of Auster as it is and as it will
  be, is kept in this repo, so that it changes in the same commit as the code. `auster.works` says why,
  who and the project's philosophy; it has a repo of its own, and each site links to the other. How
  `auster.build` is published from here is not decided yet.
- Identity: the same account that manages 1launcher manages this repo. How that works is in the
  untracked `CLAUDE.local.md`; read it before running `gh` or pushing.

## Stack
- Decided by the v0.1 plan (`docs/plans/v0.1.md`): llama.cpp's `llama-server` as the engine on macOS,
  bash 3.2 for the installer and Auster's own commands, and JavaScript for Automation (`osascript -l
  JavaScript`) for JSON, the registry, the recipe's test and the QR code (BD17). No Python, `jq` or `git`
  on the household's Mac. `registry.tsv` is the registry (A3).

## How to run things
- **Tests:** `tests/run.sh` runs every test file under `/bin/bash` 3.2 with an empty environment and a
  PATH of what macOS ships less `timeout`, `jq`, `git`, `brew`, `base32` and `python3` (T98).
  `tests/run.sh 47` runs one test's file; `tests/run.sh --mutants` applies each mutant in
  `tests/mutants/` to a copy of the source and requires its test to turn red.
- **Phase 1 and 2 measurements by hand:** `scripts/phase-1/` (see `docs/phase-1.md`, `docs/phase-2.md`).

## Siblings
- **1launcher** (`macgameport/1launcher`) is where the method came from: per-item folders, an installer
  that fetches each piece from its publisher and checks it against a fixed sha256, a release branch
  with tags, plans checked before building. **It is not the guide for Auster's design** (`SPEC.md`,
  "Auster stands on its own"). Look there to see how something was done once, then decide from
  Auster's own principles and measurements, and write the rule out here in full.

## Conventions
- `.claude/`, `CLAUDE.local.md` and `private/` are never tracked. Personal rules sync into
  `.claude/rules/` on session start; notes about accounts go in `CLAUDE.local.md`.
- **Internal notes live in `private/`:** funding, naming, the original concept note, and a bundle of
  the history from before it was restarted. Nothing from there goes into a tracked file, and tracked
  files do not name the owner's other projects. `private/` exists only on the Studio.
- Tracking: SPEC.md build-status table is the roadmap; discrete work items go in GitHub Issues on
  `macaiport/auster`.
- **No details of the owner's machines or network in tracked files:** addresses, firewall state, VPNs,
  open ports, host names. They go in `private/phase-1-local.md`. (A write-up was stopped for this on
  2026-11-26.)
- **The repo is public** (`macaiport/auster`, since 2026-11-26). Whatever is tracked is published the
  moment it is pushed, commit messages included: nothing internal goes into either.

## Places outside the repo
- **`~/Library/Developer/Auster/phase-1/`**, phase 1's workspace (since 2026-11-26): the engine build,
  model files, keys made for tests, and run logs. Outside the repo because model files are 14 to 44 GB
  and the repo is public. It is not the data root; section B of the v0.1 plan decides that. Phase 2's
  first step uses it too (`runs/p2-first-step/`). Remove it when phase 2 no longer measures by hand.

## Deliberate deviations from sibling-repo practice
- **No phases, no SPEC.md** (from 1launcher, declined 2026-11-25). The work here is phased, and
  SPEC.md holds the order (agreed 2026-11-26; it differs from the concept's roadmap).
