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
- Identity: the same account that manages 1launcher manages this repo. How that works is in the
  untracked `CLAUDE.local.md`; read it before running `gh` or pushing.

## Stack
- Not decided yet. The engine for each recipe, the installer path and the registry format are open
  questions 1, 3 and 4 in the concept. 1launcher, where the pattern began, uses bash installers
  (a shared `common/install-core.sh` and a per-game `install.sh`) and Swift for its launcher window
  and app builders.

## How to run things
- Nothing to run yet: no build, no tests.

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
  and the repo is public. It is not the data root; section B of the v0.1 plan decides that. Remove it
  when phase 1 is done.

## Deliberate deviations from sibling-repo practice
- **No phases, no SPEC.md** (from 1launcher, declined 2026-11-25). The work here is phased, and
  SPEC.md holds the order (agreed 2026-11-26; it differs from the concept's roadmap).
