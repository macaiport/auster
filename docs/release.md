# Releasing Auster

How a version of Auster is released: the rulesets that protect what installed Macs read, and the steps of each
release. It follows `docs/plans/v0.1.md`, D3.9 (releases and published names), D3.10 (trust) and AD10, and was
written with U9 on 2026-11-28. Every step here is the owner's: nothing in this repo changes a GitHub setting,
makes a tag or moves `release` by itself.

What installed Macs read, once a day, is `CHANGELOG.md` and `registry.tsv` on the branch `release`, and an
update runs `install.sh` from it. So `release` moves only to a commit that a `v` tag names, after the release
gate has passed that commit. A `v` tag is a fixed name for one version that anyone may install by name; it is
never moved. No tag is ever named `release`.

## Before the first release

These hold before `release` first moves, and need doing only once.

1. **The name's checks are settled** (D3.9). Several names that can never move once anyone has installed
   carry the name Auster: the data root's path, the job labels, the marked line in `~/.zprofile`. **Done
   2026-11-28:** the owner's searches found no prior art, no legal clearance is sought, and the name stays.
2. **The two rulesets are set and shown active** (AD10; D8, exit criterion 5). They stop `release` being
   rewound or deleted and a pushed `v` tag being moved or deleted, by anyone, while they stand. They do not
   stop `release` moving forward or a new tag being made (D3.10): that is the gate's job, and the owner's.

   In the repository's settings on GitHub, under Rules, then Rulesets, two new rulesets, each with its
   enforcement **Active** and **nobody** on its bypass list:

   | Ruleset | Kind and target | Rules |
   |---|---|---|
   | release: no force push, no deletion | branch ruleset; include by pattern `release` | Restrict deletions; Block force pushes |
   | v tags: no update, no deletion | tag ruleset; include by pattern `v*` | Restrict updates; Restrict deletions |

   The same through GitHub's API, run by the owner with the project's account (`gh auth status` must name it):

   ```bash
   gh api -X POST repos/macaiport/auster/rulesets --input - <<'EOF'
   {"name": "release: no force push, no deletion", "target": "branch", "enforcement": "active",
    "bypass_actors": [], "conditions": {"ref_name": {"include": ["refs/heads/release"], "exclude": []}},
    "rules": [{"type": "non_fast_forward"}, {"type": "deletion"}]}
   EOF
   gh api -X POST repos/macaiport/auster/rulesets --input - <<'EOF'
   {"name": "v tags: no update, no deletion", "target": "tag", "enforcement": "active",
    "bypass_actors": [], "conditions": {"ref_name": {"include": ["refs/tags/v*"], "exclude": []}},
    "rules": [{"type": "update"}, {"type": "deletion"}]}
   EOF
   ```

   **The read-back,** recorded at the foot of the plan (exit criterion 5): the list, then each ruleset by the id
   the list gives. Each must show `"enforcement": "active"` and `"bypass_actors": []`, with the rules above.

   ```bash
   gh api repos/macaiport/auster/rulesets
   gh api repos/macaiport/auster/rulesets/<id>
   ```

   What follows from them: **a tag once pushed cannot be moved or deleted while the rule stands, a mistyped one
   included.** So the gate comes before the push of a tag, every time.

## Each release

The version is `v<a>.<b>.<c>`, here `vX.Y.Z`. Work from a clean checkout of `main` with the project's account.

1. **The release commit, on `main`.** In `CHANGELOG.md`, the heading `## Unreleased` becomes
   `## vX.Y.Z (YYYY-MM-DD)`, the date the tag is made, and each change under it opens with one bold sentence
   saying what a household will notice. The first line of `registry.tsv` names `vX.Y.Z`, and so does
   `AUSTER_SELF_VERSION` in `install.sh`. A fact line that the last release holds is never edited or removed,
   and a later judgement is added below the earlier ones (A3). Commit.
2. **The tests:** `tests/run.sh` ends with `test files failed: 0`.
3. **The gate, before the tag:** `tools/release-gate vX.Y.Z` (for the first release,
   `tools/release-gate v0.1.0 --first-release`). It fetches `origin`, reads the commit's own files, asks
   every question of D3.9 and names each failure. Before the tag, the one failure left is
   `there is no tag vX.Y.Z here`. Anything else is fixed with a new commit, and the gate run again.
4. **The tag, and the gate again:** `git tag -a vX.Y.Z -m vX.Y.Z`, then the same `tools/release-gate` line,
   which must end with `release-gate: every question passes`. Until it is pushed, a wrong tag can still be
   deleted (`git tag -d vX.Y.Z`).
5. **Before the move** (UL10, D3.9): the tagged commit is taken by an update on one Mac that has Auster
   installed, with that Mac's real figures, starting the engine through the new job programs and each new
   build at the household's setting. Until `release` moves, `install.sh update` would fetch the old commit, so
   the tag's own driver is run from a clean copy of its tree, as `install.sh` hands over to it (its contract,
   in `install.sh`'s header), the way the first real install was run (`docs/phase-2.md`, section 13):

   ```bash
   T=$(mktemp -d) && git archive vX.Y.Z | tar -x -C "$T"
   /bin/bash "$T/common/driver.sh" update --commit "$(git rev-parse 'vX.Y.Z^{commit}')" --line release --version vX.Y.Z
   ```
6. **Publish,** in this order:

   ```bash
   git push origin main
   git push origin vX.Y.Z
   git push origin 'vX.Y.Z^{commit}:refs/heads/release'
   ```

   The last line creates `release` at the first release and moves it forward after that; the ruleset refuses
   anything that is not a fast-forward.
7. **The release page,** whose text is the tag's section of `CHANGELOG.md`, copied by a command and never
   typed in:

   ```bash
   git show vX.Y.Z:CHANGELOG.md | awk -v h='## vX.Y.Z (' 'index($0, h) == 1 { p = 1; next } /^## / { p = 0 } p' \
     | gh release create vX.Y.Z --verify-tag --title vX.Y.Z --notes-file -
   ```

8. **After the move:** one installed Mac is looked at within the day (D3.9); after the first move, UL11 as well.
   On `main`, a new `## Unreleased` heading goes back on top for the next changes.

## What the gate asks

`tools/release-gate` prints its questions with `tools/release-gate` and no arguments, and its test is
`tests/t39-release-gate.sh` (T39). In short: the tag names the commit; no tag is named `release`; every other
`v` tag is older; the changelog's first heading is the tag's, in its one form, with every change opening with
a bold sentence; `AUSTER_SELF_VERSION` is the tag; the registry gate (`tools/check-registry`) passes with the
tag, the commit's assets and the release's registry; each model and engine a build uses is what its publisher
offers; and no build uses an engine that no released build used, since the comparison of a new engine's
`--help` that D3.9 asks for is not part of the gate yet.
