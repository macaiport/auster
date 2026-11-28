# `auster report`: a report the person reads and sends

> **Status: planned, 2026-11-28. Not yet checked.** For the beta, as a v0.1.x update taken through the
> built-in update after v0.1.0 (`SPEC.md`, "First beta"). It takes up `docs/plans/local-layer.md` T1,
> "Sharing a report back, by a person's choice", in its smallest form: from the records v0.1 already
> writes, before the local layer and its telemetry exist. Asked for by the owner on 2026-11-28.

## 1. Why

Every figure behind the curated list was measured on one development Mac. The beta puts Auster on a few
other Macs, and the project wants to know how it went on them: which build section C chose, how fast it
writes, whether its test or a server check failed, whether the engine job faulted, and whether updates
took. Today a tester could only paste what the installer printed, and its question shows the Mac's
`.local` name, its home address and the router's hardware address (`docs/phase-2.md` section 13).

A report built from a fixed list of fields answers the project's questions and carries nothing else.

## 2. The principle (RD1, the owner's)

`README.md` says: "Nothing is fetched or installed without a yes, and nothing about the household is sent
anywhere." `auster report` sends nothing either: it writes a file, and the person sends it or not. But a
report the project asks testers to send is something about the household leaving the Mac, so the
principle should say so plainly. T1 proposes the words (LD15 in the local-layer plan):

> Nothing is fetched or installed without a yes, and nothing about the household leaves the Mac unless a
> person has read it and sent it.

`README.md` line 34 is the one place to change; `docs/plans/local-layer.md` principle 1 and LD15 point
here once it is decided. The owner decides; recommended yes.

## 3. The command

`auster report` (B6's list gains one command, no arguments):

1. **Reads; never writes into the data root, and takes no lock,** like `auster status`
   (`common/auster`, `au_status`, line 1931). Every value comes through the readers v0.1 already has, each
   matching its values whole within a bound (D3.1 "Reading"): `au_line_read` (line 372), `au_desc_read`
   (505), `au_entry_read` (553), `au_hold_read` (561), `au_mac_read` (582), `au_start_read` (666),
   `au_key_list` (1532) and `au_probe_read` (1795). A record that does not read gives `unreadable` for
   its fields, never its raw text.
2. **Builds the report from the field list alone** (section 4): each line is a key from the list and a
   value made by the report's own code from a matched value, a count or a band. No text from a record, a
   log or a command's output is copied into it, so no field outside the list can appear.
3. **Shows it in full,** then writes it to `~/Desktop/auster-report.txt` by rename, mode 0600 (RD2),
   replacing an earlier one.
4. **Says what to do with it,** in fixed words: "Nothing was sent. If you want to share this report with
   the Auster project, read it first, then email the file to <address> (RD3). It holds only the lines
   above."
5. **Opens nothing and fetches nothing.** No network, no `open`, no Mail. It works the same over SSH.
6. **Exit codes:** 0, shown and written; 1, Auster is not installed here (no data root), or the file
   could not be written (the report is still shown, and the words say so); 2, usage.

## 4. The fields

Plain text, one field a line, the key, a tab, the value. The list below is published (on auster.build,
RD4), and a field not on it is never added on the Mac.

| Key | Value | From | What it tells the project |
|---|---|---|---|
| `report` | `auster-report 1` | constant | the report's own format number (D3.1's rule) |
| `auster` | the version and the line, `v0.1.0 release` | `_update/scripts` (`au_line_read`) | which versions testers run, and how they installed |
| `week` | the ISO week the report was made, `2026-W48` | `date -u +%G-W%V` | when, to the week; no day, no time, no time zone |
| `mac` | `laptop` or `desktop` | `pmset -g batt`: `laptop` when it lists an internal battery, the installer's own rule (`common/driver.sh` lines 385 to 386; `hw.model` reads `MacNN,N` on laptops and desktops alike, `Mac17,14` on the development Mac) | whether a lid can stop always-on (B3's question says so) |
| `chip` | `Apple M5 Max`, or `other` | `sysctl -n machdep.cpu.brand_string`, matched whole to `^Apple M[1-9][0-9]?( Pro| Max| Ultra)?$` | the speeds the registry should give for each chip |
| `memory` | a standard size in GB: the nearest of 8, 16, 18, 24, 32, 36, 48, 64, 96, 128, 192, 256, 512 | `mac`'s memory (`au_mac_read`) | whether section C's limits hold on Macs other than the development one |
| `gpu-limit` | the GPU limit as a whole percent of memory, `81` | `mac`'s GPU limit and memory | the GPU share section C works from, on each Mac |
| `macos` | the major version, `27` | `mac`'s macOS version | the floor (BD15) |
| `keep-awake` | `yes` or `no` | `mac` | whether households let Auster keep the Mac awake (BD10) |
| `sleep` | `never` or `allowed` | `pmset -g`, read as `au_status` reads it (line 2009) | always-on |
| `disk-free` | a band: `under 50 GB`, `50 to 100 GB`, `100 to 250 GB`, `250 GB or more` | `df -k` of the data root | the disk rule (C6) |
| `recipe` | the recipe id, `rmmsi4vdvxsr4` | the folder under `builds/` that has `serving` | which recipe (a public, opaque id, A1) |
| `build` | the build id | `serving` (`au_desc_read`) | which build section C chose here |
| `setting` | people and context, `4 32768` | `serving`'s launch line | whether the settings fit households |
| `speed` | the writing speed in whole tokens a second, or `0` before a check passed | `serving`'s launch line | the registry's speeds (B3 step 13) |
| `start` | the engine job's last start code: `starting`, `keys`, `engine-hash`, `not-home`, `no-network`, or `none` | `start` (`au_start_read`), the code alone | engine job faults |
| `probe` | the probe's result and speed in whole tokens a second, `ok 76`, or `none` | `_update/engine` (`au_probe_read`) | health under memory pressure (BD19) |
| `stopped` | `no`, `household` or `open` | `builds/stopped` | how often a server is stopped, and why |
| `kept` | a count | `kept/` entries that read (`au_entry_read`) | whether settings and builds change |
| `failed` | a count, then for each its build id and week: `1 b7adwcqnfap56 2026-W48` | `failed/` entries' names and descriptors | which builds fail their test, on which Macs |
| `held` | a count | `hold` (`au_hold_read`) | how often a rollback leaves a build behind |
| `devices` | a band: `1`, `2 to 3`, `4 to 7`, `8 or more` | `au_key_list`, counted | the number of people a Mac serves |
| `newest-known` | the version `offer` holds, or `none` | `_update/offer` | whether checks reach the release |
| `last-check` | the week of `tried`, or `none` | `_update/tried` | whether checks run |
| `unchecked-programs` | `yes` when `jobs/previous/` exists, else `no` | `jobs/previous/` | an update whose programs never passed a check |

With several recipes (fixtures only, BD14), the recipe's lines repeat for each, in the order of their ids.

## 5. Never in a report

The text of a question, an answer or a memory (v0.1 records none); the name of a person or a device; a
key, or any part of one; an address, the `.local` name, the host name, the router or its hardware
address, the Wi-Fi; the account name; any path; a serial number or anything else that names this one
Mac; a day, a time of day or a time zone; a log line. **No install id:** two reports from one Mac cannot
be joined by anything Auster puts in them.

Section 3's rule 2 is what enforces this, and T120 tests it with every one of those values planted in a
fixture data root.

## 6. Where a report goes (RD3)

To an address of the project's, given on auster.build's support page and in the command's words. The
person sends it from their own mail, and so the project learns their address; the support page says so,
and says that reports are read by the project, used only to improve Auster, never published one by one,
and deleted on request. A collector the command posts to after a yes is a later step
(`docs/concepts/central-services.md`), and so is anything that hides the sender.

## 7. Decisions

| # | Question | Recommended |
|---|---|---|
| RD1 | The principle's new words (section 2, LD15) | Yes, as T1 words them |
| RD2 | Where the file goes | `~/Desktop/auster-report.txt`, so that a person finds it to attach; over SSH it is still shown in full |
| RD3 | The address reports go to | A project address at auster.build, forwarded; the owner names it. Until then the words name auster.build's support page |
| RD4 | Where the field list is published | auster.build, generated from section 4 of this plan |
| RD5 | Which release | The first v0.1.x after v0.1.0 that the beta can take, after U8 or with it |
| RD6 | The recipe's test, question by question | Not in the first report: v0.1 keeps a test's result only while the run lasts (`common/driver.sh` line 816, in the run's own folder). A record of it is a change to the install and the update, and a plan of its own |

## 8. Tests

Each runs under T98's bare tools, against a fixture data root, with the stubs of `sysctl`, `pmset` and
`sw_vers` (`tests/stubs/`).

| Test | What | Mutants |
|---|---|---|
| T119 | On an installed fixture, `auster report` shows every field of section 4 in order, each value of its form (the memory 64, the GPU limit 81 from a 53,084 MiB limit, the week from a stubbed date, the speed rounded, the devices banded), writes the same bytes to `~/Desktop/auster-report.txt` with mode 0600, and exits 0; the data root is byte-identical after it, no lock is taken, and no stub logs a network call or an `open` | (a) a field missing; (b) the exact memory in bytes; (c) the day in place of the week; (d) write into the data root; (e) call `open` |
| T120 | A fixture planted with a sentinel in every place section 5 names: a device name, a key, the `.local` name, the router's address and hardware address, the start record's address and boot session, the account name, a path in `$HOME`, a serial number from the `sysctl` stub, a log line: none of the sentinels is in the report, and every line's key is in section 4's list | (a) copy the start record's address; (b) a device's name in place of the count; (c) the time of `tried`; (d) a field not on the list; (e) add `hw.model` |
| T121 | Each record unreadable or absent in turn (`serving`, `mac`, `start`, `_update/engine`, `scripts`, `offer`, `tried`, a `kept/` and a `failed/` entry, `hold`): its fields say `unreadable` or `none`, never its bytes, and the rest of the report is right; a record of a newer format says `newer`. No data root: exit 1, nothing written | (a) print a record's raw line when it does not read; (b) stop at the first unreadable record |
| T122 | `~/Desktop` missing or not writable: the report is shown in full, the words say it could not be written, exit 1; an earlier report is replaced by rename, never truncated in place | (a) exit 0 when not written; (b) write in place |
| T123 | The chip: `Apple M5 Max` and `Apple M1` pass; `Apple M5 Max (Virtual)` and an empty brand give `other`. The memory: 17,179,869,184 bytes gives 16; 38,654,705,664 gives 36; the bands' edges for the disk and the devices | (a) pass the brand string unmatched; (b) round the memory down to a power of two |
| T124 | `auster report` is in `auster`'s usage and in T114's table of commands; with an argument, exit 2 | (a) accept an argument |

## 9. Exit criteria

1. RD1 to RD3 decided by the owner, and `README.md`'s principle reworded if RD1 is yes.
2. T119 to T124 pass, every mutant seen red, the whole suite green under T98.
3. Section 4's list published where RD4 says, matching the code's fields one for one.
4. Run once on the development Mac's real install, the report read line by line by a person against
   section 5 before anyone is asked to send one.
5. Released as a v0.1.x and taken by the development Mac through the built-in update.

## 10. Phase, release and rollback

Phase 2, during the beta (`SPEC.md`). It adds one command and changes no record, no job and no step of
the install or the update, so going back is a later version without it, or `auster rollback` of the
programs; nothing on the Mac depends on it, and the only file it writes is the one on the Desktop.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|

Key paths: `common/auster` (the readers and `au_status`), `common/auster-check` (`_update/engine`'s
form), `common/driver.sh` (what the install records), `README.md`, `docs/plans/local-layer.md` T1 and
LD15.
