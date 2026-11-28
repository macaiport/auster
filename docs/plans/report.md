# `auster report`: a report the person reads and sends

> **Status: planned, 2026-11-28; check-it'd 2026-11-28 — build-ready-with-fixes (pass 1b), fixes folded.**
> For the beta, as a v0.1.x update taken through the built-in update after v0.1.0 (`SPEC.md`, "First
> beta"). It takes up `docs/plans/local-layer.md` T1, "Sharing a report back, by a person's choice", in its
> smallest form: from the records v0.1 already writes, before the local layer and its telemetry exist.
> Asked for by the owner on 2026-11-28. Code is cited by function name, as it stands at commit `ab5ff78`.

## 1. Why

Every figure behind the curated list was measured on one development Mac. The beta puts Auster on a few
other Macs, and the project wants to know how it went on them: which build section C chose, how fast it
writes, whether its test or a server check failed, whether the engine job faulted, and whether updates
took. Today a tester could only paste what the installer printed, and its question shows the Mac's
`.local` name, its home address and the router's hardware address (`docs/phase-2.md` section 13).

A report built from a fixed list of fields answers the project's questions and carries nothing else.

## 2. The principle (RD1, the owner's)

`README.md` says: "Nothing is fetched or installed without a yes, and nothing about the household is sent
anywhere." `auster report` sends nothing: it writes a file, and the person sends it or not. But the
project will ask testers to send one, so the principle should say so. T1's words ("nothing leaves the Mac
unless a person has read it and sent it") reach too far: v0.1 already lets GitHub see the Mac's address
and the time at every check, and Hugging Face at a download (v0.1 plan, D3.10), with no one sending
anything; and the command cannot know whether a person has read what it showed. "Sends nothing about
the household" would strain against the same fact, since a request shows the household's public address.
Proposed instead:

> Nothing is fetched or installed without a yes. Auster's own requests carry nothing about the household
> beyond what any download shows, and a report leaves the Mac only when a person sends it themselves,
> after Auster has shown it to them in full.

At the build, `README.md`'s principle takes these words; `docs/plans/local-layer.md` principle 1, T1 and
LD15 point here; and the v0.1 plan's D3.10 ("Trust, and what this sends") gains a bullet: `auster report`
writes `~/auster-report.txt` and sends nothing. The owner decides; recommended yes.

## 3. The command

`auster report`, one command with no arguments, read-only, which works while the engine is stopped (like
`status`; `common/auster`'s header lists it with them):

1. **Reads; never writes into the data root, and takes no lock,** like `au_status`. It runs
   `au_root_check` first, and a data root that fails it gives exit 1 with nothing read. Every record is
   read through a reader v0.1 already has: `au_line_read` (`scripts`, `offer`, `tried`), `au_desc_read`,
   `au_entry_read`, `au_hold_read`, `au_mac_read`, `au_start_read`, `au_stopped_read`, `au_key_list` and
   `au_probe_read`. Where a reader leaves the match to its caller (`au_line_read` says so, and a folder
   name under `builds/` comes from a glob), the report matches the value itself, by the pattern section 4
   gives, before any use.
2. **One rule for a record that does not read,** since not every reader says so by its return code
   (`au_mac_read` says `absent` for a file it cannot read, `au_stopped_read` says `yes` with the reason
   `unknown`, `au_hold_read` says `unreadable`, and all three return 0): no file at all (`[ -e f ] || [ -L
   f ]` false) gives `none`; a file present whose reader returns 1, or says `absent` or `unreadable`, or
   for `stopped` the reason `unknown`, gives `unreadable`; one whose reader returns 2 or says `newer` gives
   `newer`. The report shows those words, never a record's bytes. (A link to a folder anywhere in the data
   root, or a file in place of a folder `au_root_check` expects, fails `au_root_check`: exit 1.)
3. **Builds the report from the field list alone** (section 4): each line is a key from the list and a
   value the report's own code makes from a matched value, a count or a band. Nothing from a record but
   a value matched whole by its pattern, and nothing from a log or a command's output, goes into it. Every command it runs has its standard error sent to
   `/dev/null`, so nothing but the report and its fixed words reaches the screen.
4. **Shows it in full** on standard output, then a blank line and the fixed words of rule 6.
5. **Writes the report alone,** without the words, to `~/auster-report.txt` (RD2), replacing an earlier
   one: the home folder must pass `au_dir_ok`; a folder already at that name refuses; the bytes go to a
   temporary file made by `mktemp` in the home folder (0600 from its creation) and are moved into place
   with `mv -f -h`, so that a link at that name is replaced and never followed (measured: without `-h`,
   macOS `mv` moves the file into a folder a link names; with it, the link is replaced; a real folder at
   the name still takes the file into it, which is why that refuses first). The temporary file is removed
   on any exit, by `auster_main`'s own EXIT trap, added to rather than replaced.
6. **Says what to do with it,** in fixed words that name the file as `~/auster-report.txt` (never the
   full path, which would show the account name): "Nothing was sent. The report above is in the file
   auster-report.txt in your home folder (in Finder: Go, Home). If you want to share it with the Auster
   project, read it first, then email that file to <address> (RD3). It holds only the lines above."
7. **Opens nothing and fetches nothing.** No network, no `open`, no Mail. Over SSH it is the same.
8. **When the file cannot be written,** the report is still shown, and these words take the place of
   rule 6's: "Nothing was sent, and the report could not be written to ~/auster-report.txt: <reason>. If
   you want to share it with the Auster project, copy the lines above into an email to <address>." The
   reason is one of: "a folder has that name"; "Auster does not write into this home folder" (`au_dir_ok`
   refuses it); "the file could not be written" (`mktemp` or `mv` failed).
9. **Exit codes:** 0, shown and written; 1, nothing was read (no data root, which `status` answers with
   0, deliberately not here: there is nothing to report; or a data root that fails `au_root_check`), or
   the file could not be written (rule 8); 2, usage.

## 4. The fields

Plain text, one field a line: the key, a tab, the value. **The list is one file in the repo,
`docs/report-fields.tsv`:** each line a key and the pattern its value must match. The tests read it, and
auster.build publishes it (RD4); a field not in it is never added on the Mac.

**The Mac's block, once, in this order:**

| Key | Value | From | What it tells the project |
|---|---|---|---|
| `report` | `auster-report 1` | constant | the report's own format number (D3.1's rule) |
| `auster` | the version and the line, `v0.1.0 release`; or `none` (no stamp: an install that has not finished), `unreadable`, `newer` | `_update/scripts` (`au_line_read`, 4 fields); the line matched to `^(release|tag)$`, the version to `AU_RE_VERSION` | which versions testers run, and how they installed |
| `week` | the ISO week the report was made, `2026-W48` | `date -u +%G-W%V` | when, to the week; no day, no time, no time zone |
| `mac` | `laptop`, `desktop`, or `unreadable` when `pmset` fails | `pmset -g batt`: `laptop` when it lists an internal battery, the installer's own rule (`au_step4_measure` in `common/driver.sh`); `hw.model` reads `MacNN,N` on laptops and desktops alike | whether a lid can stop always-on |
| `chip` | `Apple M5 Max`, or `other` | `sysctl -n machdep.cpu.brand_string`, matched whole to `^Apple M[1-9][0-9]?( Pro| Max| Ultra)?$` | the speeds the registry should give for each chip |
| `memory` | GB of 1,024 MiB, the nearest of 8, 16, 18, 24, 32, 36, 48, 64, 96, 128, 192, 256, 512 (a tie goes up); `other` below 6 or above 768; or `none`, `unreadable`, `newer` | `mac`'s `memory-bytes` (`au_mac_read`'s `AU_MAC_LINES`), compared in whole bytes | whether section C's limits hold on other Macs |
| `gpu-limit` | the GPU limit as the nearest whole percent of memory, half up (`81` for 53,084 MiB of 64 GiB); `unreadable` when either figure is 0 or the limit exceeds the memory; or `none`, `newer` | `mac`'s `gpu-mib` and `memory-bytes`, in whole numbers: `(gpu × 1,048,576 × 200 + memory) / (2 × memory)` | the GPU share section C works from, as last measured |
| `macos` | the major version, `27`; or `unreadable` when `sw_vers` fails or its answer does not match | `sw_vers -productVersion`, matched to the `mac` record's pattern, up to the first dot | the floor (BD15), as the Mac is now |
| `keep-awake` | `yes` or `no`; or `none`, `unreadable`, `newer` | `mac`'s `keep-awake` | whether households let Auster keep the Mac awake (BD10) |
| `sleep` | `never`, `allowed`, or `unreadable` | `pmset -g`, read as `au_status` reads it | always-on |
| `disk-free` | `under 50 GB`, `50 to 99 GB`, `100 to 249 GB`, `250 GB or more` (GB of 1,000,000,000, as `au_bytes`; each band includes its lower edge); or `unreadable` | `df -k` of the data root: line 2, field 4, matched to `^[0-9]{1,15}$` | the disk rule (C6) |
| `devices` | `0`, `1`, `2 to 3`, `4 to 7`, `8 or more` | `au_key_list`, counted (Auster's own key is not a device) | the number of people a Mac serves |
| `probe` | the probe's result and its speed, rounded as `speed`, `ok 76`; the result alone when it has no speed; `none` (no record, or a result of `-`), `unreadable`, `newer` | `_update/engine` (`au_probe_read`: `ok`, `slow`, `open`, `broken`, `failed`, `down`, `stopped`) | health under memory pressure (BD19) |
| `stopped` | `no`, `household`, `open`, `unreadable` (a record that cannot be read), `newer` | `builds/stopped` (`au_stopped_read`; never its time) | how often a server is stopped, and why |
| `newest-known` | the version `offer` holds; or `none`, `unreadable`, `newer` | `_update/offer` (`au_line_read`, 2 fields; the version matched to `AU_RE_VERSION`) | whether checks reach the release |
| `last-check` | the ISO week of `tried`; or `none`, `unreadable`, `newer` | `_update/tried` (`au_line_read`, 1 field, matched as `common/updates.sh` matches its times, and `unreadable` above 253,402,300,799, the end of the year 9999; then `date -u -r`) | whether checks run |
| `unchecked-programs` | `yes` when `jobs/previous/` exists, else `no` | `jobs/previous/` | an update whose programs never passed a check |

**Each recipe's block, after the Mac's,** for every folder under `builds/` whose name matches
`AU_RE_RECIPE` and which holds `serving`, `kept/`, `failed/` or `hold`, in the order of their names. So a first install whose test failed, which leaves
`failed/` and no `serving`, is still reported. (A folder whose name does not match is skipped, as `au_ready`
skips it; unlike `au_ready`, the report does not require `serving`.)

| Key | Value | From | What it tells the project |
|---|---|---|---|
| `recipe` | the recipe id, `rmmsi4vdvxsr4` | the folder's name, matched | which recipe (a public, opaque id, A1) |
| `build` | the build id; or `none` (no `serving`), `unreadable`, `newer` | `serving` (`au_desc_read`) | which build section C chose here |
| `setting` | people and context, `4 32768`; or as `build` | `serving`'s launch line | whether the settings fit households |
| `speed` | the writing speed, half up to whole tokens a second and at least 1; `unchecked` while it is the string `0`, as `au_status` reads it (no check has passed since the switch); or as `build` | `serving`'s launch line, rounded on its decimal string | the registry's speeds (B3 step 13) |
| `start` | the engine job's last start code alone: `starting`, `keys`, `engine-hash`, `not-home`, `no-network`; or `none`, `unreadable`, `newer` | `builds/<recipe>/start` (`au_start_read`'s `AU_ST_CODE`) | engine job faults |
| `kept` | the count of entries that read, then `, N unreadable` and `, N newer` when any are: `2`, `2, 1 unreadable` | `kept/` (`au_entry_read`) | whether settings and builds change |
| `failed` | as `kept`, then each entry that reads as its build id and the ISO week of its name's date, `b7adwcqnfap56@2026-W48`, space-separated, in the order of their names, at most 16, then `and N more`: `1 b7adwcqnfap56@2026-W48`. A name whose date `date -j -u -f %Y-%m-%dT%H:%M:%SZ` refuses (a month of 13, an hour of 24) counts as unreadable; `date` puts right a 31 February or a second of 60, which the pattern allows | `failed/` (`au_entry_read`) | which builds fail their test, on which Macs |
| `held` | the count; or `none` (no `hold`), `unreadable`, `newer` | `hold` (`au_hold_read`) | how often a rollback leaves a build behind |

## 5. Never in a report

The text of a question, an answer or a memory (v0.1 records none); the name of a person or a device; a
key, or any part of one; an address, the `.local` name, the host name or the computer's name, the router
or its hardware address, the Wi-Fi network; the account name; any path; the model identifier, a serial
number, the boot session or anything else that names this one Mac; a day, a time of day or a time zone; a
log line; a record's raw bytes.

**No id made to join reports.** Reports from one Mac can still be matched by its figures (its chip,
memory and GPU limit, its failed builds) and by the sender's address, and the project does not try to.
The local-layer plan's T1 says "cannot be joined" and is corrected to these words at the build.

Section 3's rules 1 to 3 are what keep this. T120 tests it with each of those values planted, and T125
tests it without any list: two Macs that differ only in private values give byte-identical reports.

## 6. Where a report goes (RD3), and what the support page says

To an address of the project's, given on auster.build's support page and in the command's words. The
person sends it from their own mail. The support page, dated and tied to the report's format number, says:

- **Who reads reports,** by name and how to reach them; the legal basis is the person's consent, which
  they can take back.
- **What the mail carries beyond the report:** the sender's address and display name, and headers that
  give the exact time and time zone and may give the household's public address. None of it is used, and
  it is kept only as the mail service keeps it.
- **Who else holds the mail:** the mail host of the project's address, and any forwarding service.
- **How long:** until the end of the beta, then deleted; sooner on request.
- **Not published one by one, not shared or sold, and never combined with other data** such as a GitHub
  account. During the beta no figures are published, since with few testers a figure for one chip can
  point at one person.
- **Access and deletion,** and how to ask.
- **Not in public:** a report is never to be pasted into an issue or a discussion, which ties it to a
  GitHub account. A report that shows anything not on the published list is not to be sent at all, and
  is reported through GitHub's private vulnerability reporting (`SECURITY.md`) instead.

A collector the command posts to after a yes is a later step (`docs/concepts/central-services.md`), and
so is anything that hides the sender.

## 7. Decisions

| # | Question | Recommended |
|---|---|---|
| RD1 | The principle's new words (section 2) | Yes, as section 2 gives them |
| RD2 | Where the file goes | `~/auster-report.txt`, the home folder itself. Not `~/Desktop`: on a Mac with iCloud's Desktop and Documents turned on (the development Mac has it on: `~/Desktop` carries `com.apple.file-provider-domain-id`, and iCloud Drive holds a link to it), a file written there is uploaded to iCloud before the person has decided anything; and macOS guards the Desktop with a permission prompt, which over SSH may refuse the write |
| RD3 | The address reports go to | A project address at auster.build; the owner names it and who reads it. Until then the words name auster.build's support page |
| RD4 | Where the field list is published | auster.build, from `docs/report-fields.tsv` |
| RD5 | Which release | The first v0.1.x after v0.1.0 that the beta can take: after U8, or with it |
| RD6 | The recipe's test, question by question | Not in the first report: v0.1 keeps a test's result only while the run lasts (`au_candidate_test`, in the run's own folder). A record of it is a change to the install and the update, and a plan of its own |

## 8. Tests

Each runs under T98's bare tools and a stub environment that sets `STUB_LOG`, against a fixture data root
staged by a new `tests/report-helpers.sh`: `job_install` (`tests/job-helpers.sh`) for one recipe, with
`kept/`, `failed/` and `hold` copied from `tests/fixtures/records/two/`, `check_job` for `_update/engine`,
`release_says` with `check_job` for `offer` and `tried`, and `auster key add` for more devices; and, for
several recipes, `records_fixture three` copied into a test home's data root (`$HOME/Library/Application
Support/Auster`, the one `au_identity` sets, so that `AU_DATA` cannot be set from outside). The host name
and the Wi-Fi name can only be planted through `STUB_CMD_DIR` (the `scutil` stub's host name is fixed, and
`networksetup` answers only `-listallhardwareports`). The
report's keys and value patterns come from `docs/report-fields.tsv`, never restated in a test.

**Stubs this needs:** `tests/stubs/sysctl` answers `machdep.cpu.brand_string` from `STUB_CPU_BRAND`
(default `Apple M5 Max`; set empty, an unknown oid, as `STUB_ARM64` does); a new `tests/stubs/df` answers
`df -k PATH` from `STUB_DF_KB` and passes through to `/bin/df` when it is unset, so that the install tests'
disk rule (C6) is unchanged.

| Test | What | Mutants |
|---|---|---|
| T119 | On an installed fixture, `auster report`: standard output is the report, a blank line and rule 6's words, exactly; standard error is empty; `~/auster-report.txt` holds the report alone, its bytes a prefix of standard output, mode 0600 under `umask 0`; every key is `docs/report-fields.tsv`'s, in its order, each value matching its pattern; the values are those of the fixture (memory `64`; GPU limit `81` from 53,084 MiB; speed `37` from 36.9; macOS `27` from `27.2.1`; the week from `STUB_NOW`; devices `1`); exit 0. A snapshot (`snapshot`, `tests/helpers.sh`) of the whole home folder before and after differs only by `auster-report.txt`. With a live run holding `builds/updating` (`stale_lock` naming the test's own shell) the same report is shown and the lock file is unchanged. `STUB_LOG` holds only `id` and `ps` (`au_identity`, before any command), `sysctl`, `pmset`, `sw_vers`, `date` and `df`: no `curl`, `nc`, `open`, `osascript`, `launchctl`, `arp`, `scutil`, `networksetup`, `route`, `ipconfig` or `caffeinate` | (a) a field missing; (b) the memory in bytes; (c) the day in place of the week; (d) write into the data root; (e) call `open`; (f) truncate the GPU limit; (g) truncate the speed; (h) the full macOS version; (i) take the lock; (j) write elsewhere in the home folder; (k) two keys swapped; (l) the words written into the file; (m) a field not in the list |
| T120 | Planted, each as a long unique string: a device name; a key; the `.local` name (in `builds/local-name` and the `scutil` stub); the computer's name and host name (stubs); the router's address and hardware address (the `mac` record and the stubs); the Wi-Fi name (`networksetup` stub); the start record's address, boot session and time; the probe record's two addresses; `mac`'s `measured` time; a day and a time of day in `kept/` and `failed/` names, `tried` and `stopped`; the account name (`id` stub); the home folder's path; `STUB_HW_MODEL` and `STUB_BOOT_SESSION`; a serial-like string as the chip brand (which gives `other`); a log line; a folder `builds/r<sentinel>/` holding `kept/`, and a stamp whose line field is a path. With `TZ=Pacific/Auckland` and `STUB_NOW` a Sunday 23:30 UTC, the week is the UTC Sunday's. Also scanned for the real `id -un`, `hostname`, the real serial (`ioreg -rd1 -c IOPlatformExpertDevice`), `$TMPDIR`, `NZ`, `+13` and `+1300`. None appears in standard output, standard error or the file | (a) copy the start record's address; (b) a device's name in place of the count; (c) `tried`'s time; (d) add `computer` from `scutil --get ComputerName`; (e) add `hw.model`; (f) local time for the week; (g) copy the recipe folder's name unmatched |
| T121 | Each record absent, then unreadable (with a sentinel in its bytes), then of a newer format, in turn, and then all at once: `serving`, `mac`, `start`, `stopped`, `_update/engine`, `scripts`, `offer`, `tried`, `hold`, a `kept/` and a `failed/` entry: each field gives the value section 4 names for that state, the rest of the report is right, and no sentinel appears. Hostile values (control characters and escape sequences, a value past its bound, a link to a file or a folder in a record's place, no final newline) give `unreadable`; a link to a folder anywhere, or a file in place of `kept/` or `failed/`, gives exit 1 (`au_root_check`). A `failed/` name with a month of 13 is counted as unreadable; a `kept/` or `failed/` entry of a newer format is counted as newer. No data root: exit 1, nothing written; a data root that fails `au_root_check`: exit 1, nothing read | (a) print a record's raw line when it does not read; (b) stop at the first unreadable record; (c) treat an absent record as unreadable |
| T122 | The file: an earlier report is replaced by rename (a second hard link to it keeps the old bytes); a link at that name, to a file and to a folder, is replaced by a regular file and its target untouched; a folder at that name refuses (exit 1, the report shown, nothing moved into the folder); a home folder that fails `au_dir_ok` refuses; no temporary file is left after a failed write; each failure's words exact | (a) exit 0 when not written; (b) write in place; (c) `mv` without `-h`; (d) leave the temporary file |
| T123 | The arithmetic and the bands, each at its edges: the chip (`Apple M5 Max`, `Apple M1`, `Apple M10` pass; `Apple M0`, `Apple M100`, `Apple M5 Max (Virtual)`, a brand with a tab, and an empty brand give `other`); the memory from the `mac` record (16 from 17,179,869,184 bytes and from 1 MiB less; 36 from 38,654,705,664; `other` at 4 GiB and at 1 TiB); the GPU limit (0, above the memory); the speed (0.4 gives 1, `0.0` gives 1, `0` gives `unchecked`); `sw_vers`, `pmset` and `df` failing (`STUB_CMD_DIR`) give `unreadable`; the GPU limit above the memory gives `unreadable`; `tried` past the year 9999 gives `unreadable`; the disk bands from `STUB_DF_KB` one below, at and one above each edge; the devices at 0, 1, 2, 3, 4, 7 and 8; the week at 2027-01-01, which is `2026-W53` | (a) pass the brand unmatched; (b) round the memory down to a power of two; (c) `<=` for `<` at a disk edge; (d) a devices band off by one; (e) `%Y` for `%G` |
| T124 | `auster report x` exits 2 with `au_usage`'s text, which names `report`, and `STUB_LOG` holds no `pmset`, `df`, `sw_vers` or `date`; `auster report` works while `builds/stopped` exists | (a) accept an argument |
| T125 | Two fixtures with the same figures and every private value different (device names, keys, the `.local` name, the router, the start record's address, boot session and time, the probe record's addresses, logs, `measured`, the days and times within one ISO week in `kept/` and `failed/` names, `tried` and `stopped`, the stubs' names, router and boot session, the home folder, and the account name by `STUB_USER` alone, since `STUB_UID` must stay the files' owner): the two reports are byte-identical. One fixture reported twice in the same week: byte-identical | (a) a `$RANDOM` token; (b) an id made from `keys/` or the data root's path; (c) the router's hardware address; (d) the `.local` name from `scutil` |
| T126 | A first install whose test failed (`failed/` and no `serving`, no keys): the recipe's block is there, `build` `none`, `failed` names the build; `devices` `0`. Several recipes (`records_fixture three`): one block each, in the order of their ids, the Mac's block once | (a) report only folders with `serving`; (b) repeat the Mac's block per recipe |

## 9. Exit criteria

1. RD1 to RD3 decided by the owner; `README.md`'s principle, the local-layer plan's principle 1 and T1,
   and the v0.1 plan's D3.10 changed as section 2 says.
2. T119 to T126 pass, every mutant seen red (`tests/run.sh --mutants`), the whole suite green, T98's
   source check included.
3. `docs/report-fields.tsv` published where RD4 says; the tests already hold the code to it.
4. Run once on the development Mac's real install, and the report read line by line by a person against
   section 5 before anyone is asked to send one. The tracking issue records that it was read, its number
   of fields and that no private value was in it; the report itself is kept in `private/`, since section 6
   keeps reports out of public places.
5. Released as a v0.1.x (RD5) and taken by the development Mac through the built-in update, `auster
   status` naming the new version.

## 10. Phase, release and rollback

Phase 2, during the beta (`SPEC.md`). It adds one command and changes no record, no job and no step of
the install or the update, so going back is a later version without it, or `auster rollback` of the
programs; nothing on the Mac depends on it, and the only file it writes is `~/auster-report.txt`.

**What a build touches:** `common/auster` (the command, its helpers for the sizes, percent, rounding,
bands and weeks, `auster_main`'s `report:1`, `au_usage`, the header's list of commands and of those that
work while stopped); `tests/stubs/sysctl`, a new `tests/stubs/df`; `tests/report-helpers.sh`; `tests/t119`
to `t126` and their mutants; `docs/report-fields.tsv`; and the documents of exit criterion 1, `SPEC.md`,
`CHANGELOG.md` and this plan's as-built header.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-28 | 1, the whole plan | privacy, security and architecture; correctness and builder (gates run: `tests/run.sh 114` and `98`); test plan | three agents; the iCloud finding measured on the development Mac by hand | Opus for privacy and builder, Sonnet for the test plan; fold by Opus 5.5 | Auster `ab5ff78` | build-ready-with-fixes; folded: RD2 to the home folder; the principle's words; the reading rule and every field's value for absent, unreadable and newer; recipes found by their folders; the rounding and the bands; the file's writing; the field list as a file; T125 and T126; the support page |
| 2026-11-28 | 1b, pass 1's fold | one fitted lens: every name and pattern the fold uses, the arithmetic and `date` run, `mv -h` measured in a scratch folder, `au_dir_ok` on a real home, contradictions, each mutant | one agent | Opus; fold by Opus 5.5 | Auster `ab5ff78` | build-ready-with-fixes; folded: the reading rule for readers that return 0, the failure words, `STUB_LOG`'s identity calls, several recipes staged in a test home, the report kept out of the public issue, the GPU limit above memory and newer entries, links to folders, the principle's words again. **check-it'd 2026-11-28 — build-ready-with-fixes (pass 1b)** |

Key paths: `common/auster` (the readers, `au_status`, `au_root_check`, `au_dir_ok`, `auster_main`,
`au_usage`), `common/auster-check` (`_update/engine`'s form), `common/driver.sh` (`au_step4_measure`,
`au_candidate_test`, what the install records), `tests/stubs/`, `README.md`, `docs/plans/local-layer.md`
T1 and LD15, `docs/plans/v0.1.md` D3.10.
