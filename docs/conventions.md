# Auster's conventions

> **Status: written 2026-11-28 at the owner's request; not yet checked.** One page of decisions already made,
> collected so that the app, the site, the report and whatever comes next follow the same ones. Each points
> to where it was decided; this page records them and decides nothing new. When a decision changes, change it
> where it was made, then here.

## 1. On the Mac

### Where each thing goes

| What | Where | Mode | Decided in |
|---|---|---|---|
| Everything Auster keeps: programs, builds, models, engines, keys, records, logs | `~/Library/Application Support/Auster/`, the data root, with a marker file `.auster-data-root` | 0700, this account's, writable by nobody else; nothing else in it may be a link out | v0.1 plan B1, D3.1 (ownership) |
| The `auster` command | the data root's `bin/` | 0755 inside the 0700 root | B3 step 3, B6 |
| Device keys and the engine's key file | the data root's `keys/` | 0600 each, in a 0700 folder | B7 |
| Model files and engine archives | the data root's `store/`, named by sha256, read-only | 0444 | D3.1 |
| The two background jobs | `~/Library/LaunchAgents/local.auster.engine.plist` and `local.auster.check.plist` | the account's | B4, B5 |
| The line that lets Terminal find `auster`, on the person's yes | the end of `~/.zprofile`, marked "added by Auster" and removed by `auster remove` where it is unchanged | as it was | B6 |
| The app (planned) | `~/Applications/Auster.app` | the account's; `~/Applications/` made 0700 when missing | `docs/plans/app.md` |
| A report (planned) | `~/auster-report.txt`, shown in full first | 0600 | `docs/plans/report.md` |
| A run's own temporary files | a folder made by `mktemp` in `$TMPDIR`, deleted on any exit | 0700 | B3 |

**Never written:** the Desktop and Documents (iCloud's Desktop and Documents may upload them, and macOS
guards them with a prompt); `/Applications`, `/usr/local` or anything else that needs an administrator,
since Auster runs as the person and nothing in it runs as root (AD15); iCloud Drive.

### Names

- **Identifiers:** the jobs' labels `local.auster.engine` and `local.auster.check`, and the app's
  `local.auster.app`. Like the data root's path and the `.zprofile` line, these can never change once anyone
  has installed (D3.9).
- **Ids in records:** minted, opaque, never reused; a person sees a label and a date (A1, A2).
- **Files a person sees:** plain English with spaces and capitals (`Update Auster.command`, `Auster.app`);
  files only Auster reads: lower case with hyphens.

### Apple's conventions, and where Auster differs

| Apple's convention | What Auster does | Why |
|---|---|---|
| An app's data in `~/Library/Application Support/<name or bundle identifier>/` | `~/Library/Application Support/Auster/` | Followed, by the app's name |
| Per-user background jobs in `~/Library/LaunchAgents/` | Followed | |
| Per-user apps in `~/Applications/` | Followed (planned) | |
| Data that can be downloaded again is kept out of backups | **Not yet:** the model and the engine, 44 GB for the household recipe's first build, are backed up by Time Machine with everything else | To be fixed: `docs/plans/backup.md` |
| Identifiers in reverse-DNS form of a domain the developer controls | `local.auster.*`, the form used without such a domain | No permanent name depends on keeping a domain; and collisions under `local.auster.` are very unlikely. Settled now because these can never change after v0.1.0 |
| Apps signed with a Developer ID and notarized | The app (planned) is unsigned: the Mac writes it itself, and macOS opens it with no prompt (measured, `docs/plans/app.md` section 3) | The owner registers as an Apple Developer in the week of 2026-11-30. How a signed app would reach a Mac through the installer, which fetches a git tree, is not known yet, and is a plan of its own |
| Logs in `~/Library/Logs/`, where Console looks | The data root's `logs/` | Under the data root's ownership rule with everything else (D3.1) |
| Secrets in the Keychain | Device keys are files, 0600 | The engine reads its keys from a file (B7) |

## 2. Words

How Auster speaks to a person, in Terminal, in a notification, in an alert or in the README:

- **Fixed sentences,** written in the code, never assembled from what a record or a program printed. A value
  goes into one only after it matches its pattern (D3.5).
- **Say what happened, then the way on:** which command, or "pasting the installer line again". Name the
  way back when there is one, and only when it would work (`docs/plans/v0.1.md` D3.6, "The words after it").
- **Never in a notification, an alert or a report:** an address, the `.local` name, a device's name, a key, a
  path in the home folder. In Terminal the home address appears only where the person needs it (the
  install's last line, `auster status`).
- **Plain words,** no jargon a household would need to look up. Numbers with commas (`32,768`); sizes as
  Finder gives them (GB of 1,000); memory as About This Mac gives it (GB of 1,024 MiB) (`au_commas`,
  `au_bytes`, `au_memory` in `common/auster`).
- **A claim about what runs where is a measurement,** with the Mac it was measured on (`README.md`'s
  principles).
- **Exit codes:** 0 done; 1 refused or answered no; 2 usage; 3 not everything was done; 4 the server is
  down; 5 an install stopped (`common/auster` and `common/driver.sh` headers).

## 3. Look

The mark, the app icon and their colours, light and dark, are in [`docs/brand/`](brand/README.md). Its copy is
taken from the website's, which is the original; the lettered logos stay with the website. The mark and the
icon come under this repository's MIT licence.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|
