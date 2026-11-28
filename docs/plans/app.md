# The Auster app: a double-clickable Auster with its icon

> **Status: planned, 2026-11-28. Not yet checked.** Asked for by the owner on 2026-11-28 ("yes plan it"),
> after his word that the app icon in `docs/brand/app-icon/` is to be Auster's icon on the Mac. For the
> beta: in v0.1.0 if it is built and checked in time, otherwise a v0.1.x through the built-in update
> (`SPEC.md`, "First beta"). The concept's "double-clickable results" (`docs/concept.md`) in their
> smallest form; phase 4's launcher window is the larger one. Code is cited by function name at `b82dfb5`.

## 1. What it is

`~/Applications/Auster.app`: an app with Auster's icon that opens the chat page on this Mac when it is
double-clicked. It can be kept in the Dock and found by Spotlight and Launchpad, like any app. It is not a
second program: everything it does is `auster open`, a new command, so there is one place that knows how.

Nothing else changes: the server, its jobs and the household's other devices go on as before. The app is
how a person at the Mac reaches what the Mac already serves.

## 2. Where it goes, and why not the Desktop

**`~/Applications/`**, the account's own Applications folder: macOS lists it in Launchpad and Spotlight, it
needs no administrator, and it is not synced to iCloud. **Not the Desktop:** with iCloud's Desktop and
Documents turned on (the development Mac has it on: `docs/plans/report.md`, RD2) a file there is uploaded to
iCloud; and macOS guards the Desktop with a permission prompt. **Not `/Applications`:** it needs an
administrator, and Auster runs as the person (AD15).

`~/Applications/` is made, mode 0700, when it does not exist. A link in its place, or an `Auster.app` that
is not Auster's (section 5), is left alone and the install says so in one sentence; the server is not
affected.

## 3. What the app holds

A folder of four files, written by the installer from the tree, with nothing compiled and nothing fetched:

| File | What |
|---|---|
| `Contents/Info.plist` | the app's description: its name `Auster`; its identifier `local.auster.app` (beside the jobs' `local.auster.engine` and `local.auster.check`); its program `Auster`; its icon `Auster`; its kind, an application (`APPL`); the oldest macOS it runs on, Auster's floor (BD15); and `LSUIElement`, so that it shows no window and no menu of its own while it runs, which is a moment |
| `Contents/MacOS/Auster` | its program, a bash script of one command, mode 0755: `exec "$HOME/Library/Application Support/Auster/bin/auster" open` |
| `Contents/Resources/Auster.icns` | the icon, copied from the tree (AP2) |
| `Contents/PkgInfo` | `APPL????`, which older parts of macOS still read |

The tree keeps these as `common/app/Info.plist`, `common/app/Auster` and `common/app/Auster.icns`, so
that they are Auster's own programs (D3.1): compared byte for byte like the others, put in place by an
update that changes them (B3 step 6), and covered by T98's gate on the source. The icon is copied there
from `docs/brand/app-icon/`, whose README names the script that draws it; `docs/brand/` stays the
original.

**Made here, so not blocked.** macOS checks an app with Gatekeeper when it carries the quarantine mark a
browser or `curl` with that option puts on a download. The installer writes these files itself, with
`cp` from a tree `curl` fetched into a temporary folder without the mark, so the app carries none and
opens without a warning. The program is a script, run by `/bin/bash`, which macOS signs; the app itself is
not signed. Both are to be measured on the development Mac before the build (section 8, exit criterion 2):
that a script app with no signature opens, on macOS 27, with no prompt, and shows its icon in Finder and
the Dock.

**One look.** An `.icns` file has one look; an icon that follows light and dark is a different kind of file,
made in Apple's Icon Composer, which has not been made (`docs/brand/README.md`). AP3 picks one.

## 4. `auster open`

A new command, read-only, with no arguments. It opens the chat page **on this Mac**, at
`http://127.0.0.1:<port>/`, with `open` (the person's default browser). The engine listens on `127.0.0.1`
as well as on the home address (B4), so this works whatever the home network is, and the app and the
command name no address, `.local` name or anything else of the household's.

- The port is `serving`'s (`au_desc_read`), as `au_status` reads it.
- While the engine is stopped (`builds/stopped`) or Auster is not installed, nothing is opened: the words say
  why, as `status` would, and name `auster start`. Run from the app, there is no Terminal to show words in,
  so the app shows them in one dialog (AP4).
- Over SSH there is no screen to open a page on: the command says so and gives the address to open at the
  Mac.
- It never puts a key in the address. A browser on this Mac needs a key, as any device does (B7): see
  section 6.

## 5. Install, update and removal

- **The first install** writes the app after step 14 (the keys shown), and only after a passed server
  check, so that the icon never stands for a server that does not answer. It is written as a whole: the
  four files into `~/Applications/.Auster.app.new.<pid>`, then renamed into place. An `Auster.app` already
  there is replaced only when it is Auster's: its `Info.plist` names `local.auster.app`. Otherwise it is
  left alone.
- **An update** puts the app in place as it puts Auster's other programs (B3 step 6), so the app and
  `bin/auster` are always of one version. One that is missing, the person having moved it to the Trash,
  is not put back by an update: removing it is the person's choice, and `auster app` (AP5) puts it back.
- **A rename over a folder:** an existing app is moved aside to `.Auster.app.old.<pid>`, the new one renamed
  into place, then the old one deleted, so that an interruption leaves one of the two whole.
- **`auster remove`** deletes `~/Applications/Auster.app` when it is Auster's, never following a link, and
  `~/Applications/` itself only when Auster made it and it is empty. B8's list of what remove leaves names
  the app when it is not Auster's.

## 6. A key for this Mac's browser

The chat page asks for a key in its settings, once per browser (B7). The household's devices get theirs as a
QR code; a browser on the Mac itself has no camera to read one, and a key should not be shown as text where
it lands in Terminal's scrollback. So:

- **`auster key add <name>`** already makes a key for a new device (for example `this-mac`).
- **`auster key copy <name>`**, a new command, puts that key on the clipboard with `pbcopy`, reading it from
  `keys/<id>` on its standard input, and never prints it. The words: "The key for this-mac is on the
  clipboard. Paste it into the chat page's settings as its API key, then copy something else, so that it
  does not stay there." (AP6)
- The install's words, and `auster open`'s the first time, say this in one line.

## 7. Decisions

| # | Question | Recommended |
|---|---|---|
| AP1 | Whether the app is in the beta | Yes: in v0.1.0 if built and checked in time; otherwise the first v0.1.x |
| AP2 | Where the tree keeps the app's files | `common/app/`, as Auster's own programs, with the icon copied from `docs/brand/app-icon/` |
| AP3 | The icon's one look | The light tile, `Auster-light.icns`, since most app icons on a Mac are light whatever the mode; the owner decides |
| AP4 | The app's words when it cannot open the page | One dialog through `osascript`'s `display alert`, the only one the app shows: the same sentence `auster open` says |
| AP5 | A way to put the app back | `auster app`, which writes it as an install does |
| AP6 | `auster key copy` | Yes, as section 6; the alternative is a key shown as text, which Auster has avoided so far |

## 8. Tests

Each under T98's bare tools, with the stubs (`open` and `osascript` logged and never run). Numbered after
the report plan's T121 to T128.

| Test | What | Mutants |
|---|---|---|
| T129 | A first install writes `~/Applications/Auster.app`: the four files, byte for byte the tree's `common/app/` (with `Info.plist` checked by `plutil -lint`), the program mode 0755, the folder made 0700 when it was missing; only after the server check passed; a failed check writes no app | (a) write it before the check; (b) the program not executable; (c) another icon |
| T130 | An app already there: Auster's is replaced whole (an interruption between the renames leaves one whole app); one whose `Info.plist` names another identifier, a link at `Auster.app`, and a link in place of `~/Applications/` are each left as they are, with one sentence, and the install goes on to its end | (a) replace an app that is not Auster's; (b) follow the link |
| T131 | `auster open` opens `http://127.0.0.1:<serving's port>/` with `open`, and nothing else; while stopped, or not installed, nothing is opened and the words name `auster start`; over SSH (`SSH_CONNECTION` set) nothing is opened and the address is given; the app's program, run as the app runs it, does the same, with the words through one `display alert` | (a) the home address in place of 127.0.0.1; (b) open while stopped; (c) a key in the address |
| T132 | An update with a changed `common/app/` puts the app in place with the programs, and `jobs/previous/` keeps the old app; `auster rollback` of the programs puts it back; an update with the app missing does not put it back; `auster app` does | (a) leave the old app after an update; (b) put back an app the person removed |
| T133 | `auster remove` deletes Auster's app, never one that is not Auster's, never through a link, and `~/Applications/` only when Auster made it and it is empty | (a) delete an app that is not Auster's; (b) delete a `~/Applications/` with something else in it |
| T134 | `auster key copy <name>` hands `keys/<id>` to `pbcopy` (a stub that records its input) and prints no part of it; an unknown name refuses; T84's search for every key in every output, extended to it, finds none | (a) print the key; (b) pass it as an argument |

**Measured by hand before the build, on the development Mac** (exit criterion 2): a script app made by
`cp`, unsigned and with no quarantine mark, opens on macOS 27 with no prompt; its icon shows in Finder,
Spotlight and the Dock; and `LSUIElement` keeps it out of the Dock while it runs.

## 9. Exit criteria

1. AP1 to AP6 decided by the owner.
2. Section 8's measurements made on the development Mac and recorded in `docs/phase-2.md`, before any code.
3. T129 to T134 pass, every mutant seen red, the whole suite green, T98's source check included.
4. On the development Mac's real install: the app opens the chat page, `auster key copy` gives this Mac's
   browser a key that the page accepts, and a screenshot of the app in the Dock and the page shows no
   address, name or key.

## 10. Phase, release and rollback

Phase 2, for the beta. It adds files beside Auster's programs and two commands; it changes no record, job or
step of the server. Going back is `auster rollback` of the programs, which takes the app with them, and
removing it by hand is moving it to the Trash: nothing depends on it.

**What a build touches:** `common/app/` (three files), `common/auster` (`auster open`, `auster app`, `auster
key copy`, the words, the header), `common/driver.sh` (the app at the first install, in B3 step 6's
programs, and in remove), `tests/stubs/` (`pbcopy`, and `osascript`'s `display alert`), `tests/t129` to
`t134` and their mutants, `docs/plans/v0.1.md` (B3, B6, B7, B8 and D3.1 name the app), `SPEC.md`,
`CHANGELOG.md` and this plan's as-built header.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|

Key paths: `common/auster` (`au_status`, the key commands, `au_qr_show`), `common/driver.sh` (B3 step 6's
programs, `au_remove`), `install.sh` (how the tree is fetched), `docs/brand/app-icon/`, `docs/plans/v0.1.md`
B3, B6, B7, B8 and D3.1.
