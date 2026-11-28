# Keep the model and the engine out of Time Machine

> **Status: planned, 2026-11-28; not yet checked.** Asked for by the owner on 2026-11-28 ("do both and check
> them"), after `docs/conventions.md` found that Auster does not follow Apple's convention that data which
> can be downloaded again is kept out of backups. For v0.1.0: testers' Macs should not back up 14 to 44 GB
> they never need restored.

## 1. What changes

Every run that makes or checks the data root's folders (B3 step 3, `au_step3_root`, at a first install and at
every update) asks Time Machine to leave out two of them:

- **`store/`**: the model files and engine archives, by sha256 (44.4 GB and 16.9 MB for the household
  recipe's first build).
- **`engines/`**: the engines unpacked from those archives.

With `tmutil addexclusion <folder>`, once for each, after the folder exists. Nothing else is left out: the
keys, `builds/` (`serving`, `kept/`, `failed/`, `hold`), the programs, the logs and `_update/` are small and
are what a restored Mac needs.

## 2. Measured on the development Mac, macOS 27.2.1, 2026-11-28

In a scratch folder inside a folder Time Machine backs up (the system's `$TMPDIR` is already left out, so a
test there proves nothing):

- `tmutil addexclusion <folder>` as the person, with no `sudo`, exits 0, and `tmutil isexcluded` then says
  `[Excluded]` for the folder and for a file inside it. It is the "sticky" kind: an extended attribute
  (`com.apple.metadata:com_apple_backup_excludeItem`) on the folder itself, not a setting in Time Machine's
  list, which `-p` would write and which needs an administrator.
- It survives a rename of the folder, and a `cp -R` copy carries it.
- Asked again for a folder already left out, it exits 0, so every run can ask without checking first.
- For a folder that does not exist it fails (`Error (100002)`), so it is asked only after the folder is made.
- `tmutil removeexclusion <folder>` undoes it.

## 3. What a restored Mac does

A Mac restored from a Time Machine backup has the data root without `store/` and `engines/`'s contents.
Nothing new is needed for that:

- The engine job refuses to start with its files missing (`engine-hash`), and `auster status` says that
  pasting the installer line again fetches them (U6's third part).
- The next update, or that paste, finds the build in use's files missing and fetches them again before
  anything else (`docs/plans/v0.1.md` D3.6, "A changed file of the build in use is fetched again"; a missing
  file counts as changed, T117).

## 4. When it cannot be done

When `tmutil` fails (it is missing, or refuses), the run goes on: nothing about the server depends on it.
One sentence says so, once, in that run's words: "Time Machine could not be told to leave out the model and
the engine, so it may back them up (about <size>)." `tmutil`'s own output is discarded, since it holds the
data root's path.

Other backup software may not read Time Machine's mark; the guide says so. It is not Auster's to change.

## 5. The question says so

The install's question (B3 step 6) gains one line, so that the person knows before saying yes:

    Backups     Time Machine leaves out the model and the engine (44.4 GB): a Mac restored from a backup
                fetches them again when the installer line is pasted.

An update's question does not repeat it.

## 6. Decisions

| # | Question | Recommended |
|---|---|---|
| BK1 | Leave `store/` and `engines/` out of Time Machine | Yes |
| BK2 | The question's line (section 5) | Yes |
| BK3 | Which release | v0.1.0; Macs already installed get it at their next update, since every run asks again |

## 7. Tests

Under T98's bare tools, with a new stub `tests/stubs/tmutil` that logs its arguments to `STUB_LOG` and never
reaches the real `tmutil` (which would mark the test's own folders); `STUB_CMD_DIR` makes it fail.

| Test | What | Mutants |
|---|---|---|
| T135 | A first install asks `tmutil addexclusion` for exactly the data root's `store/` and `engines/`, each after it exists, and for nothing else (not the data root, not `keys/`, not `builds/`); an update asks again; `install.sh --check` asks for nothing in the real data root; with the stub failing, the install goes on to its end, exit 0, and says the one sentence once, with no path in it; the question shows section 5's line at a first install and not at an update | (a) leave out the whole data root; (b) stop the run when `tmutil` fails; (c) ask only at a first install; (d) ask before the folder exists; (e) print `tmutil`'s own output |

## 8. Exit criteria

1. BK1 to BK3 decided by the owner.
2. T135 passes, its mutants are seen red (`tests/run.sh --mutants 135`), and the whole suite is green.
3. On the development Mac, after the update that brings it: `tmutil isexcluded` says `[Excluded]` for the
   real data root's `store/` and `engines/`, and `[Included]` for `keys/` and `builds/`.

## 9. Phase, release and rollback

Phase 2, for v0.1.0. It changes one step's folders and the question's words; no record, no job, no program
of the server. Going back is `tmutil removeexclusion` on the two folders, or nothing at all: a Mac that
backs them up loses nothing but space.

**What a build touches:** `common/driver.sh` (`au_step3_root`, the question in `au_facts`), `tests/stubs/tmutil`,
`tests/t135` and its mutants, `docs/plans/v0.1.md` (B1, B3 steps 3 and 6, D3.10), `docs/conventions.md`,
`SPEC.md`, `CHANGELOG.md`, and this plan's as-built header.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|

Key paths: `common/driver.sh` (`au_step3_root`, `au_facts`), `common/auster-engine` (its start check),
`tests/stubs/`, `docs/plans/v0.1.md` B1, B3, D3.6, D3.10.
