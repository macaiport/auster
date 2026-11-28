# Keep the model and the engine out of Time Machine

> **Status: planned, 2026-11-28; check-it'd 2026-11-28 — build-ready-with-fixes (pass 1), fixes folded.** Asked for by the owner on 2026-11-28 ("do both and check
> them"), after `docs/conventions.md` found that Auster does not follow Apple's convention that data which
> can be downloaded again is kept out of backups. For v0.1.0: testers' Macs should not back up 14 to 44 GB
> they never need restored.

## 1. What changes

Every run that makes or checks the data root's folders asks Time Machine to leave out two of them, at the
**end** of `au_step3_root` (B3 step 3): after the lock is taken and after the refusal of a newer version's
records, so that a run refused for either changes nothing, and so that both folders exist whether this run
made them or not. The runs that reach it: a first install (before its question; on a no, the folders go with
everything else the run made), a second paste, `auster update` and `auster people`. Not `install.sh
--check`, whose data root is a temporary one (the call is skipped there), and not `remove`, which never
reaches step 3.

- **`store/`**: the model files and engine archives, and each build's template, system prompt and test, by
  sha256 (44.4 GB and 16.9 MB for the household recipe's first build's model and archive).
- **`engines/`**: the engines unpacked from those archives.

With one call, `tmutil addexclusion <store> <engines>`, both of its outputs discarded (its error, which
names the path, is on standard error, and a line is on standard output too). The step prints nothing: it
records `AU_TM=ok` or `AU_TM=failed` for section 4 and 5. Nothing else is left out: the
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
- For a folder that does not exist it fails with exit 162 (`Error (100002)`, on standard error with the
  path, and `Command exited with status 100002.` on standard output), so it is asked only once the folder
  exists. Two folders in one call are both left out; with one missing, the other still is.
- A folder or file made inside one later is left out too, so `engines/<sha256>/`, which step 9 renames into
  place, is covered.
- `tmutil removeexclusion <folder>` undoes it.
- It works with a bare environment (`env -i PATH=/usr/bin:/bin`), and `man tmutil` says only the `-p` and
  `-v` kinds need root and Full Disk Access.
- **No Time Machine destination is set up on the development Mac,** so that a real backup skips the folders
  rests on `man tmutil` ("tells Time Machine not to back up a file, directory, or volume during future
  backups"), not on a backup made.

## 3. What a restored Mac does

A Mac restored from a Time Machine backup has the data root without `store/` and `engines/` at all, since a
folder left out is not in the backup. The code already handles that (read at `99e5065`):

- `au_root_check` accepts the two folders missing, and step 3 makes them again (and asks again).
- The engine job refuses to start with its folder missing (`engine-hash`), and `auster status` says that
  pasting the installer line again fetches the file again; its words say a file "has changed", which is
  true enough of one that is missing.
- The next update, or that paste, finds the build in use's model, archive, unpacked engine, template, system
  prompt and test missing (`au_update_files`, by `au_store_has` and `au_engine_whole`), and the repair
  fetches the archive and the model and unpacks the engine again, through the update's question and its
  disk rule (`docs/plans/v0.1.md` D3.6, "A changed file of the build in use is fetched again"). T117 tests a
  changed file, not a missing one; T135 adds the missing case.

Its limits, which a restored Mac shares with any repair: the template, system prompt and test come back only
from the release tree's `assets/`; a model the publisher no longer offers cannot be fetched again (the
repair's known limit); and `auster rollback` cannot go back to a kept build, whose files are gone too (it
checks them first, and says so).

## 4. When it cannot be done

When `tmutil` fails (it is missing, or refuses), the run goes on: nothing about the server depends on it.
It is said once, and never claimed otherwise:

- **At a first install,** in the question (section 5), in place of its usual line: "Backups     Time Machine
  could not be told to leave out the model and the engine, so it may back them up (about <size>)." The size
  is `au_bytes` of the chosen build's model and archive sizes (fields 29 and 22 of the report), known by the
  question; the unpacked engine is not in the registry, so the figure is "about".
- **At an update, a second paste or `people`,** right after step 3: "Time Machine could not be told to leave
  out the model and the engine, so it may back them up."
- `tmutil`'s own output is never shown: it holds the data root's path.

Other backup software may not read Time Machine's mark; the guide says so. It is not Auster's to change.

## 5. The question says so

The install's question (B3 step 6, `au_facts`) gains one line when `AU_TM` is `ok`, so that the person
knows before saying yes (and section 4's line when it is `failed`):

    Backups     Time Machine leaves out the model and the engine (44.4 GB): a Mac restored from a backup
                fetches them again when the installer line is pasted.

An update's question does not repeat it.

## 6. Decisions

| # | Question | Recommended |
|---|---|---|
| BK1 | Leave `store/` and `engines/` out of Time Machine | Yes |
| BK2 | The question's line (section 5), and section 4's words when it cannot be done | Yes |
| BK3 | Which release | v0.1.0; Macs already installed get it at their next update, since every run asks again |

## 7. Tests

Under T98's bare tools, with a new stub `tests/stubs/tmutil` (`stub_begin`, so it logs to `STUB_LOG`) that
behaves as `tmutil` does, argument by argument: for `addexclusion`, an existing folder gives nothing and exit
0, and anything else gives the real error on standard error, `Command exited with status 100002.` on
standard output, and exit 162; `STUB_TMUTIL_FAIL=1` makes every call fail that way; any other verb is
`stub_untold`. (The tests' data roots are under the system's `$TMPDIR`, already left out, so the stub is for
the log and the failing case, not for safety.) The file is `tests/t135-<name>.sh`, its mutants
`tests/mutants/T135a` on, each headed `# file: common/driver.sh`.

| Test | What | Mutants |
|---|---|---|
| T135 | A first install asks `tmutil addexclusion` once, for exactly the data root's `store/` and `engines/`, after the lock, and for nothing else (not the data root, not `keys/`, not `builds/`); a second paste, an update and `people` ask again; `install.sh --check` asks nothing (no `tmutil` in `STUB_LOG`) and its question still shows section 5's line; a run refused for a held lock asks nothing. With `STUB_TMUTIL_FAIL=1`: a first install's question shows section 4's line with "about" and the size, and never section 5's; an update says section 4's update sentence once; each goes on to its end, exit 0, with no path and no `tmutil` output on screen. **A restored Mac:** after an install, `store/` and `engines/` deleted whole; an update answered yes makes both again and asks for them, names model, engine, unpacked, template, system prompt and test in its question, fetches the model and the archive, unpacks the engine, passes its server check, exit 0 | (a) leave out the whole data root; (b) stop the run when `tmutil` fails; (c) ask only for a folder this run made; (d) ask before the folder exists; (e) print `tmutil`'s own output; (f) ask in `--check` too; (g) section 5's line when the call failed |

## 8. Exit criteria

1. BK1 to BK3 decided by the owner.
2. T135 passes, its mutants are seen red (`tests/run.sh --mutants 135`), and the whole suite is green.
3. On the development Mac, after the update that brings it: `tmutil isexcluded` says `[Excluded]` for the
   real data root's `store/` and `engines/`, and `[Included]` for `keys/` and `builds/`.

## 9. Phase, release and rollback

Phase 2, for v0.1.0. It changes one step's folders and the question's words; no record, no job, no program
of the server. Going back is `tmutil removeexclusion` on the two folders, or nothing at all: a Mac that
backs them up loses nothing but space.

**What a build touches:** `common/driver.sh` (`au_step3_root`, the question in `au_facts`, the update's
sentence after step 3), `tests/stubs/tmutil`,
`tests/t135` and its mutants, `docs/plans/v0.1.md` (B1, B3 steps 3 and 6, D3.10), `docs/conventions.md`,
`SPEC.md`, `CHANGELOG.md`, and this plan's as-built header.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|

Key paths: `common/driver.sh` (`au_step3_root`, `au_facts`), `common/auster-engine` (its start check),
`tests/stubs/`, `docs/plans/v0.1.md` B1, B3, D3.6, D3.10.
| 2026-11-28 | 1, the whole plan | builder and platform: every run that reaches step 3, the restored-Mac path read through the code, `tmutil` measured in a backed-up scratch folder, the stub and each mutant | one agent | Opus; fold by Opus 5.5 | Auster `99e5065` | build-ready-with-fixes; folded: the result recorded at step 3 and said in the question (the blocker: the question would have claimed the exclusion after a failure, and step 3 cannot know the size), the call placed after the lock and skipped in `--check`, the restored Mac's limits, exit 162, a stub that behaves as `tmutil` does, the restored-Mac case in T135. **check-it'd 2026-11-28 — build-ready-with-fixes (pass 1)** |
