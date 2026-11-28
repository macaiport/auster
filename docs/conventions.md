# Auster's conventions

> **Status: written 2026-11-28 at the owner's request; checked the same day for accuracy against the code
> and Apple's documentation (Review log), and corrected.** One page of decisions already made,
> collected so that the app, the site, the report and whatever comes next follow the same ones. Each points
> to where it was decided; this page records them and decides nothing new. When a decision changes, change it
> where it was made, then here.

## 1. On the Mac

### Where each thing goes

| What | Where | Mode | Decided in |
|---|---|---|---|
| Everything Auster keeps: programs, builds, models, engines, keys, records, logs | `~/Library/Application Support/Auster/`, the data root, with a marker file `.auster-data-root` | 0700, this account's; every folder in it, at any depth, this account's and writable by nobody else; no link in it may lead to a folder, outside an engine's unpacked tree (links to files are read as absent) | v0.1 plan B1, D3.1 (ownership) |
| The `auster` command | the data root's `bin/` | 0755 inside the 0700 root | B3 step 3, B6 |
| Device keys and the engine's key file | the data root's `keys/` | 0600 each, in a 0700 folder | B7 |
| Model files and engine archives | the data root's `store/`, named by sha256, read-only | 0444 | D3.1 |
| The two background jobs | `~/Library/LaunchAgents/local.auster.engine.plist` and `local.auster.check.plist`; the folder made when missing; each file written as a hidden `.<label>.plist.new.<pid>` beside it, then renamed into place | the account's | B4, B5 |
| Whether each job is switched on | launchd's own record, by label, written by `launchctl enable` and `disable`; macOS keeps it outside the home folder, and `auster remove` leaves both labels marked enabled, since it can set that record but not delete it | macOS's | B4, B8 |
| The line that lets Terminal find `auster`, on the person's yes | the end of `~/.zprofile`, marked "added by Auster", written through a hidden `~/.zprofile.auster-new.<pid>` renamed into place, and removed by `auster remove` where it is unchanged (the file itself deleted when nothing else is left in it) | as it was; 0644 when Auster creates the file | B6 |
| The app (planned) | `~/Applications/Auster.app` | the account's; `~/Applications/` made 0700 when missing | `docs/plans/app.md` |
| A report (planned) | `~/auster-report.txt`, shown in full first | 0600 | `docs/plans/report.md` |
| A run's own temporary files | a folder made by `mktemp` in `$TMPDIR` named `auster-<what>.XXXXXX`, deleted on any exit, an interruption included (`common/driver.sh`'s `AU_RUN`, `install.sh`'s `AUSTER_TMP`, and those of `auster`'s server check, `people`, `cleanup`, the check job and the recipes' lines). In `common/auster`, `au_tmp` adds each folder to `AU_TMPS` in the same command that makes it, and the EXIT traps of `bin/auster` and of the driver (`au_cleanup`) delete them all. `common/updates.sh` sets its trap only while its folder exists, so a check stopped while curl waits still ends at once (T136, T137) | 0700 | the code; B1 says what Auster writes outside the data root |
| `Update Auster.command`, which `auster update` opens in Terminal | a folder of its own made by `mktemp`, which outlives the command that made it; the `.command` file deletes itself and its folder when it ends | 0700 | `common/updates.sh` |

**Never written:** the Desktop and Documents (iCloud's Desktop and Documents may upload them, and macOS
guards them with a prompt); `/Applications`, `/usr/local` or anything else that needs an administrator,
since Auster runs as the person and nothing in it runs as root (AD15); iCloud Drive.

### Names

- **Identifiers:** the jobs' labels `local.auster.engine` and `local.auster.check`, which, like the data
  root's path and the `.zprofile` line, can never change once anyone has installed (D3.9); and the app's
  `local.auster.app` (`docs/plans/app.md`), which joins that list when the app ships.
- **Ids in records:** minted, opaque, never reused; a person sees a label and a date (A1, A2, D3.1).
- **Files a person sees:** plain English with spaces and capitals (`Update Auster.command`, `Auster.app`);
  files only Auster reads: lower case with hyphens.

### Apple's conventions, and where Auster differs

| Apple's convention | What Auster does | Why |
|---|---|---|
| An app's data in `~/Library/Application Support/<bundle identifier>/`, for example `com.example.MyApp` | `~/Library/Application Support/Auster/`, by the product's name | **Differs:** a path a person can read and type in Terminal (the `.zprofile` line, `auster remove`'s words); fixed for good by D3.9 |
| Per-user background jobs in `~/Library/LaunchAgents/` | Followed | |
| Per-user apps in `~/Applications/`, which apps write only when the person directs it | In place, followed (planned). The install's question names the app, which is the person's direction for the first one; an update that changes only the app rewrites it without asking (`docs/plans/app.md` section 5) | An update is something the person said yes to, and the app is theirs to move to the Trash, which an update respects |
| Data that can be downloaded again is kept out of backups (Apple's guidance, written for iOS backups; carried over here to Time Machine) | Followed: `store/` and `engines/` (the model and the engine, 44 GB for the household recipe's first build) are left out of Time Machine at every install and update, and the install's question says so, or says it could not be done | `docs/plans/backup.md`; a Mac restored from a backup fetches them again at the next paste or update (T135) |
| Identifiers in reverse-DNS form, Apple's examples using the developer's own domain (`com.example.*`); a job's label must be unique | `local.auster.*`. Apple names no form for a developer without a domain; `local.` is common for hand-made launchd jobs, and no one can own it as a domain, since `.local` is reserved for the home network (RFC 6762) | No permanent name depends on keeping a domain, and collisions under `local.auster.` are very unlikely. Settled now because these can never change after v0.1.0 |
| Apps signed with a Developer ID and notarized | The app (planned) is unsigned: the Mac writes it itself, and macOS opens it with no prompt (measured in a scratch folder, `docs/plans/app.md` section 3; the real `~/Applications` is still to measure, its section 8) | The owner registers as an Apple Developer in the week of 2026-11-30. How a signed app would reach a Mac through the installer, which fetches a git tree, is not known yet, and is a plan of its own |
| Logs in `~/Library/Logs/`, where Console looks | The data root's `logs/` | Under the data root's ownership rule with everything else (D3.1) |
| Secrets in the Keychain | Device keys are files, 0600 | The engine reads its keys from a file (B7) |

## 2. Words

How Auster speaks to a person, in Terminal, in a notification, in an alert or in the README:

- **Fixed sentences,** written in the code, never assembled from what a record or a program printed. A value
  read from a record, or printed by a program (`sw_vers`, `id -un`, a version in the rule file), goes into one
  only after it matches its pattern (D3.1, "Reading"; D3.5 for notifications). Fetched release notes appear
  only through the notes cleaner (D3.5).
- **A program's own sentences are never printed.** Where another of Auster's programs says why it failed, it
  also gives a code, and the program that tells the person answers that code with a sentence of its own: the
  rule file's `failed` line, answered by `au_update_why` (T141).
- **curl's numbers:** a website's answer (the HTTP code) is named only once it matches `^[0-9]{1,3}$`, and
  never as 000, which curl gives when there was no answer. curl's exit code is never shown. It is put into
  words: the address could not be found, the connection was cut, it did not answer in time
  (`au_fetch_said`, `install.sh`'s `auster_install_unreached`, the update's `.command` file; T138, T139).
- **Record codes** come at the end of a fixed sentence, in parentheses, so that they can be looked up, and
  never alone: "it started the engine (starting)". `auster status`'s start and probe lines, and the server
  check's reason when it is not answered (`au_start_words`, `au_probe_words`, `au_server_check`; T142, T143).
- **Figures a program prints,** capability.js's among them, are matched as whole numbers before a sentence
  names them or bash's arithmetic takes them, since arithmetic on a value that is no number runs what it
  holds (`a[$(...)]`). One that does not match gets a sentence that names no figure (`au_whole`,
  `au_choice_whole` in `common/driver.sh`; T144).
- **Times** read `2026-11-28 14:05:09 UTC` (`au_tried_when`, and the time the engine was stopped).
- **Say what happened, then the way on:** which command, or "pasting the installer line again". Name the
  way back when there is one, and only when it would work (`docs/plans/v0.1.md` D3.6, "The words after it").
- **Never in a notification, an alert or a report:** an address, the `.local` name, a device's name, a key, a
  path in the home folder. In Terminal the home address appears only where the person needs it: the
  install's question and its last line, `auster network`, and `auster status` when macOS has changed the
  Mac's `.local` name.
- **Logs** (the data root's `logs/`) may hold the home address and the data root's path: they are Auster's
  own record, inside the data root, never notified and never put into a report.
- **Names found in the data root** (a folder's or an entry's name) are printed as found: only this account
  can make them (D3.1, ownership); a name used to find something is matched first.
- **Plain words,** no jargon a household would need to look up. Numbers with commas (`32,768`); sizes as
  Finder gives them (GB of 1,000); memory as About This Mac gives it (GB of 1,024 MiB) (`au_commas`,
  `au_bytes`, `au_memory` in `common/auster`).
- **A claim about what runs where is a measurement,** with the Mac it was measured on (`README.md`'s
  principles).
- **Exit codes:** 0 done; 1 refused or answered no; 2 usage; 3 not everything was done; 4 the server is
  down; 5 an install stopped after writing (`common/auster` and `common/driver.sh` headers; D3.9 fixes 1 to
  5); 130 or 143 when interrupted.

## 3. Look

The mark, the app icon and their colours, light and dark, are in [`docs/brand/`](brand/README.md). Its copy is
taken from the website's, which is the original; the lettered logos stay with the website. The mark and the
icon come under this repository's MIT licence.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-28 | 1, the whole page | accuracy: every path, mode, label, citation and rule against the code and plans; Apple's conventions against Apple's own pages | one agent | Opus; fold by Opus 5.5 | Auster `99e5065` | accurate-with-fixes; folded: Apple's Application Support convention (by bundle identifier, so Auster differs), `local.` (not Apple's form), `~/Applications` written only when the person directs it, the link rule, where the home address appears, sources and modes corrected |
| 2026-11-28 | 2, the code against sections 1 and 2 | an audit of every sentence a person sees and every write outside the data root | one agent | Opus | Auster `277307b` | consistent-with-fixes: the faults (a device key left in `$TMPDIR` by an interrupted server check, numbers without commas, unmatched values, missing traps) go to the code; the deliberate cases are now listed here (launchd's record, the LaunchAgents folder, the hidden files beside a target, every temporary folder, logs, names found in the data root). The faults were fixed in `9e31e2e` (merged `aa11fe6`; T136 to T142), and the rules that fix made are now in section 2 (a program's own sentences, curl's numbers, record codes, times). Three of the same kind were left for a second pass, `5fd8c23` (merged `87238d9`): the server check's unanswered reason now says each start code in words (T143); capability.js's figures are matched in `au_refusal`, `au_facts`, step 5 and the choices of an update and of `people` (T144); an unreadable `e_mac` cannot be reached through registry.js, which prints only 0 to 99, so it stays untested |
