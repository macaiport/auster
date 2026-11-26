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
  questions 1, 3 and 4 in the concept. 1launcher, whose pattern this copies, uses bash installers
  (a shared `common/install-core.sh` and a per-game `install.sh`) and Swift for its launcher window
  and app builders.

## How to run things
- Nothing to run yet: no build, no tests.

## Siblings
- **1launcher** (`macgameport/1launcher`) is the pattern: per-game folders, an installer that
  fetches each piece from its publisher and checks it against a fixed sha256, double-clickable apps,
  the 14unch3r window, and a daily update check. Read its `CLAUDE.md` before building an equivalent
  here.

## Conventions
- `.claude/`, `CLAUDE.local.md` and `private/` are never tracked. Personal rules sync into
  `.claude/rules/` on session start; notes about accounts go in `CLAUDE.local.md`.
- **Internal notes live in `private/`:** funding, naming, the original concept note, and a bundle of
  the history from before it was restarted. Nothing from there goes into a tracked file, and tracked
  files do not name the owner's other projects. `private/` exists only on the Studio.
- Tracking: SPEC.md build-status table is the roadmap; discrete work items go in GitHub Issues on
  `macaiport/auster`, as in 1launcher.
- **The repo is public** (`macaiport/auster`, since 2026-11-26). Whatever is tracked is published the
  moment it is pushed, commit messages included: nothing internal goes into either.

## Deliberate deviations from sibling-repo practice
- **No phases, no SPEC.md** (from 1launcher, declined 2026-11-25). The work here is phased, and
  SPEC.md holds the order (agreed 2026-11-26; it differs from the concept's roadmap).
