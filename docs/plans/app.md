# The Auster app: a double-clickable Auster with its icon

> **Status: planned, 2026-11-28. Its first check found it needed rework, and it was rewritten the same day;
> not build-ready until a re-check of the rewrite passes.** Asked for by the owner on 2026-11-28 ("yes plan it"), after his
> word that the app icon in `docs/brand/app-icon/` is to be Auster's icon on the Mac. For the beta: in
> v0.1.0 if it is built and checked in time, otherwise a v0.1.x through the built-in update (`SPEC.md`,
> "First beta"). The concept's "double-clickable results" (`docs/concept.md`) in their smallest form; phase
> 4's launcher window is the larger one. Code is cited by function name at `de6b9f4`.

## 1. What it is

`~/Applications/Auster.app`: an app with Auster's icon that opens the chat page on this Mac when it is
double-clicked. It can be kept in the Dock and found by Spotlight and Launchpad, like any app. It is not a
second program: what it does is `auster open --app`, a new command, so there is one place that knows how.

Nothing else changes for the household's other devices. The app is how a person at the Mac reaches what the
Mac already serves.

## 2. Where it goes, and why not the Desktop

**`~/Applications/`**, the account's own Applications folder: macOS lists it in Launchpad and Spotlight, it
needs no administrator, and it is not synced to iCloud. **Not the Desktop:** with iCloud's Desktop and
Documents turned on (the development Mac has it on: `docs/plans/report.md`, RD2) a file there is uploaded to
iCloud, and macOS guards the Desktop with a permission prompt. **Not `/Applications`:** it needs an
administrator, and Auster runs as the person (AD15).

`~/Applications/` is made, mode 0700, when it does not exist, and is never deleted: it is a standard folder
that other software uses too. Before anything is read or written in it, it must pass `au_dir_ok` (a folder,
not a link, this account's, writable by nobody else); otherwise the app is not written and one sentence says
so. The server is not affected either way.

## 3. What the app holds

A folder of four files, from the tree's `common/app/`, with nothing compiled and nothing fetched:

| File | What |
|---|---|
| `Contents/Info.plist` | its name `Auster`; its identifier `local.auster.app` (beside the jobs' `local.auster.engine` and `local.auster.check`); its program `Auster`; its icon `Auster`; its kind, an application (`APPL`); `LSMinimumSystemVersion`, Auster's floor (BD15, a test holds the two equal); and `LSUIElement`, so that it shows no window and no Dock tile of its own while it runs, which is a moment |
| `Contents/MacOS/Auster` | its program, a bash script, mode 0755: `"$HOME/Library/Application Support/Auster/bin/auster" open --app`, and when that cannot run at all (no `bin/auster`, or one too old to know `open`), one alert with a fixed sentence held in the app itself: "Auster could not open its page. In Terminal, `auster status` says why." |
| `Contents/Resources/Auster.icns` | the icon (AP2, AP3) |
| `Contents/PkgInfo` | `APPL????`, which older parts of macOS still read |

**The app is not one of Auster's own programs** (B3 step 6). Those live in the data root, are kept in
`jobs/previous/` and put back by `auster rollback`, and changing one restarts the server for its check; none
of that fits the app, and it would break things: `au_rollback_programs` keeps only names like `auster` or
`check.js` and deletes the rest, and on a Mac's usual case-insensitive disk the app's program `Auster` and
`bin/auster` share a name (measured: copied into one folder, they leave one file, `auster`, holding the
app's script). So the app has its own step (section 5), nothing of it goes into `jobs/previous/`, and a
rollback leaves it as it is; the program's fallback alert covers a `bin/auster` that does not know `open`.

**Made here, so not blocked** (measured on the development Mac, macOS 27.2.1, 2026-11-28, in a scratch
folder): a bundle like this, unsigned (`codesign`: "code object is not signed at all") and with no
quarantine mark, opened with `open` and `open -a` with no prompt, though `spctl --assess` rejects it ("no
usable signature"): Gatekeeper asks only about what carries the quarantine mark. `install.sh` fetches the
tree with `curl` and unpacks it with `tar`, which give it no mark, so the app carries none. A file that did
carry it would keep it through `cp`, `cp -X` and `ditto --noextattr` (measured), so a test asserts that no
file of the written app carries `com.apple.quarantine`.

**Its icon shows at once** (measured): a bundle made this way shows its own icon in Finder without `touch`
or `lsregister`, and `LSUIElement` made it a `UIElement` while it ran (`lsappinfo`). Replacing the icon file
inside an existing bundle left the old icon showing until the bundle's folder was touched (measured), so an
update touches it (section 5).

**One look.** An `.icns` file has one look; an icon that follows light and dark is a different kind of file,
made in Apple's Icon Composer, which has not been made (`docs/brand/README.md`). AP3 picks one.

## 4. `auster open`

A new command. It opens the chat page **on this Mac**, at `http://127.0.0.1:<port>/`, with `open` (the
person's default browser), never with a key in the address. The port is `serving`'s (`au_serving_read`).

**The engine must allow that page's origin, and today it does not** (measured on the development Mac's real
install, 2026-11-28): a request carrying `Origin: http://127.0.0.1:8484` is refused with 400 before the key
is looked at, and so is its preflight, because the engine's `--cors-origins` lists only its home address
and its `.local` name (B4 step 8). Browsers send `Origin` on a page's POSTs, so the page would open and
never answer. So **the engine job adds `http://127.0.0.1:<port>` to its origins**: B4 step 8's "its own two
addresses" becomes three. Another page on this Mac on another port is still refused, since its origin
differs. This is a change to the engine job's program, so the update that brings it restarts and checks the
server, as B3 step 6 does for any program.

It opens the page only when the page can answer. In order, each with one fixed sentence (never one of
`status`'s, whose words can hold the home address or a device's name) and exit 1:

1. Auster is not installed here (`au_ready`): "Auster is not installed on this Mac."
2. The engine is stopped (`builds/stopped`): "Auster's server is stopped. In Terminal, `auster start`
   starts it."
3. The engine job's last start is `not-home` or `no-network` (`au_start_read`): "This Mac is not on its home
   network, and Auster's server only runs there."
4. The server does not answer `GET http://127.0.0.1:<port>/health` within 5 s: "Auster's server is not
   answering. In Terminal, `auster status` says why."

Otherwise it opens the page and exits 0.

- **From the app** (`--app`, which only the app's program passes), each sentence is shown in one
  `display alert` instead of printed, with its value passed to `osascript` as an argument (`on run argv`),
  never written into the script, and no `tell application`, so no permission prompt (measured: an argument
  holding quotes, `&` and `$(...)` ran nothing). `osascript`'s standard error is discarded: from inside an
  app it writes a sandbox warning and still succeeds (measured).
- **Over SSH** (`au_ssh`: `SSH_CONNECTION` or `SSH_TTY`) there is no screen to open a page on: it opens
  nothing, says "Open http://127.0.0.1:<port>/ in a browser at this Mac.", and exits 1.
- `auster key add this-mac` draws a QR code this Mac cannot read, so its words for a name that is this Mac's
  name `auster key copy` instead (section 6).

## 5. Written, updated and removed

The app's own step, never part of B3 step 6, and never a reason to restart the server:

- **Where:** after step 14 at a first install (the keys shown, so only after a passed server check); after
  the programs step on an update; and by `auster app` (AP5), which refuses when Auster is not installed.
- **Whether:** `~/Applications/` must pass `au_dir_ok`. An `Auster.app` that is a link, or whose `Contents`
  or `Contents/Info.plist` is a link, or whose identifier (read with `plutil -extract CFBundleIdentifier raw
  -o -` from a file of at most 8 KiB, matched whole to `^local\.auster\.app$`) is not Auster's, is left
  alone, with one sentence. On an update, an app that is missing is not put back: the person moved it to the
  Trash, and `auster app` puts it back.
- **How, when there is none:** the four files are written into `~/Applications/.Auster.app.new.<pid>`, each
  written with `cat` into a file made by `mktemp`, then the folder renamed to `Auster.app`.
- **How, when Auster's is there:** each of the four files that differs from the tree's is renamed into place
  inside it, then the bundle's folder is touched so that a changed icon shows. The folder keeps its identity,
  so a Dock item pointing at it is not broken (to be measured: section 8). An interruption leaves each file
  either old or new, every one whole.
- **Leftovers:** each run deletes `~/Applications/.Auster.app.new.*` folders that are not links and whose
  `Info.plist` names `local.auster.app`.
- **The question** (B3 step 6) names it: "...and an app named Auster in the Applications folder of your home
  folder." No new question is asked.
- **`auster remove`** deletes the app at its **first** yes, with the two jobs, since without them it opens
  nothing; that yes's sentence names it. It never deletes an app that is not Auster's (the same checks as
  above), never through a link, and never `~/Applications/`. B8's sentence "Nothing else on the Mac was
  touched by Auster" names the app. `install.sh remove` never meets one, since the app comes after step 14.

## 6. A key for this Mac's browser

The chat page asks for a key in its settings, once per browser (B7). The engine applies its key on every
address it listens on, `127.0.0.1` included (`common/auster-engine`'s launch line; `docs/phase-1.md` step
3), and a key-free loopback would open the server to every program and every account on the Mac, so this
Mac's browser needs a key of its own, as any device does.

**`auster key copy <name>`** puts that device's key on **this Mac's clipboard only**, through a small program
in JavaScript for Automation, `clipboard.js` (one of Auster's own programs, beside `bin/auster`):

- the key read on its standard input from `keys/<id>`, its trailing newline dropped, never an argument and
  never printed;
- the clipboard prepared with `NSPasteboardContentsCurrentHostOnly`, so that Universal Clipboard does not
  carry it to the person's other Apple devices (`pbcopy` cannot ask for this: it would offer the key to every
  nearby device on the person's Apple Account, which B7's one key per device forbids);
- the key as plain text, with the markers `org.nspasteboard.ConcealedType` and
  `org.nspasteboard.TransientType`, which clipboard managers that follow nspasteboard.org leave out of their
  history (measured: the write and the read-back worked on a scratch pasteboard);
- then the words: "The key for this-mac is on this Mac's clipboard only, not your other devices'. Paste it
  into the chat page's settings as its API key, then press Return here and it is cleared. Do not let the
  browser save it as a password." On Return, the clipboard is cleared if it still holds what was written
  (its change count is the same).

It refuses an unknown or revoked name, a name that is a path, and over SSH (the clipboard would be the
Mac's, with nobody at it). If the clipboard cannot be written, it says so and exits 1, never claiming the key
is there.

**What T84 does not reach:** the clipboard is not a stub log or a file, so "no key leaves the Mac" holds here
by the host-only option, which section 8 measures, not by T84.

**The browser:** its localStorage is per origin, so the page at `127.0.0.1:<port>` keeps its own key and
conversations, apart from the `.local` page's, and a change of port leaves them behind. A browser's sync
carries history and bookmarks, which here hold only `127.0.0.1`.

## 7. Decisions

| # | Question | Recommended |
|---|---|---|
| AP1 | Whether the app is in the beta | Yes: in v0.1.0 if built and checked in time; otherwise the first v0.1.x |
| AP2 | Where the tree keeps the app's files | `common/app/` (four files), written by the app's own step, not as Auster's programs; the icon copied from `docs/brand/app-icon/`, and a test holds the two copies equal |
| AP3 | The icon's one look | The light tile, `Auster-light.icns`, since most app icons on a Mac are light whatever the mode; the owner decides |
| AP4 | The app's words when it cannot open the page | One `display alert` with section 4's fixed sentences, by argument |
| AP5 | A way to put the app back | `auster app`, which writes it as section 5 does |
| AP6 | `auster key copy` | Yes, to this Mac's clipboard only, concealed, and cleared on Return (section 6). If section 8 finds the host-only option does not keep the key off another device, the key is shown once as text on `au_qr_show`'s alternate screen, to be typed, never copied |
| AP7 | The engine's third origin, `http://127.0.0.1:<port>` | Yes (section 4); without it the page at `127.0.0.1` cannot answer |

## 8. Measured before the build

Made on the development Mac, recorded in `docs/phase-2.md`, before any code (exit criterion 2):

**Already measured, 2026-11-28** (sections 3, 4 and 6): the bundle opens unsigned with no prompt; its icon
shows without `touch`; `LSUIElement` holds; an argument to `display alert` runs nothing; the engine refuses
the `127.0.0.1` origin today; the host-only, concealed clipboard write works on a scratch pasteboard;
`pbcopy`, `open`, `osascript`, `plutil` and `xattr` are on the bare PATH.

**Still to measure, at the Mac, in the real `~/Applications`:**
1. With an iPhone or iPad on the same Apple Account nearby and Handoff on, a key written by `clipboard.js`
   does not arrive there; and Spotlight's clipboard history on macOS 27, if it is on, does not list it.
2. The clear on Return empties the clipboard.
3. The app is listed by Spotlight and Launchpad.
4. Kept in the Dock, the app survives an update that changes its icon, and shows the new one.
5. Renaming files inside the app from Terminal is not stopped by macOS's App Management protection.
6. Started by a real double-click, the alert shows in front.
7. With the third origin added, the page at `http://127.0.0.1:<port>/` answers a question.

A measurement that fails stops the part of the plan it carries: 1 sends AP6 to its alternative; 4 or 5 sends
section 5 back to the whole-bundle rename, measured to show a new icon at once; 7 stops the app until the
origin is understood.

## 9. Tests

Each under T98's bare tools. **Stubs:** `osascript` logs `display alert` and its arguments to
`STUB_ALERT_LOG` (apart from `STUB_NOTIFY_LOG`, which tests count) and never shows it; it runs no
`clipboard.js`, writing its standard input to `STUB_CLIP` (outside the test's home) instead, and its
arguments to `STUB_LOG` but never its input; `open` is read from `STUB_LOG` for a URL. **Helpers:**
`make_home` gains `--applications`, `--applications-link`, `--app-foreign` and `--app-link`, passed through
`install_env`; `app_run` runs the app's program as the app runs it (`env -i HOME=... PATH=<bare>`, standard
input from `/dev/null`).

| Test | What | Mutants |
|---|---|---|
| T129 | A first install writes `~/Applications/Auster.app`: the four files byte for byte the tree's `common/app/`, `Info.plist` passing `plutil -lint`, the program mode 0755 by `stat`, no file carrying `com.apple.quarantine`, the folder made 0700 when it was missing, after the server check passed; a failed check (as T107 stages one) writes no app and no `.Auster.app.new.*`. `common/app/Auster.icns` equals the file AP3 names in `docs/brand/app-icon/`; `LSMinimumSystemVersion` equals BD15's floor; the tree's app files hold no address, `.local` name or 32-hex string | (a) write it before the check; (b) the program not executable; (c) another icon; (d) a floor that differs |
| T130 | Staged before the install or `auster app`: a link at `Auster.app` to a folder holding a sentinel; an `Auster.app` whose identifier is another's; `Contents/Info.plist` a link to a genuine Auster plist elsewhere; `~/Applications` a link, and group-writable: each is left as it is, the sentinel too, with one sentence, and the install goes on to its end. Leftovers: an Auster `.Auster.app.new.<pid>` is deleted; one that is not Auster's, and a link, are left | (a) replace an app that is not Auster's; (b) follow the link; (c) accept a group-writable folder; (d) trust a linked `Info.plist` |
| T131 | `auster open` opens exactly `http://127.0.0.1:<serving's port>/` (the whole URL) and nothing else, exit 0, while `/health` answers; not installed, stopped, `not-home`, `no-network` and not answering each open nothing, print their one sentence and exit 1; over SSH (`SSH_CONNECTION`, then `SSH_TTY`) nothing is opened and the address is given. `auster open --app` and `app_run` do the same with each sentence as one `display alert` and nothing printed; plain `auster open` never alerts. With `bin/auster` missing, and with one that does not know `open`, the app shows its own fixed alert | (a) the home address in place of 127.0.0.1; (b) open while stopped; (c) open while `not-home`; (d) a key in the address; (e) the alert from the plain command; (f) the words printed from the app; (g) the sentence written into the script |
| T132 | An update with `common/app/` changed rewrites only the files that differ, touches the bundle, and makes no engine restart (the kickstarts counted); with it unchanged the app is untouched (`snapshot` equal); with the app removed nothing is put back and `~/Applications/` is not made; `auster rollback` of the programs leaves the app and `jobs/previous/auster` is byte for byte the old `bin/auster`; `auster app` puts back a removed app and refuses when Auster is not installed | (a) count the app as a program (a restart logged); (b) put back an app the person removed; (c) rewrite every file on every update; (d) no touch after a changed icon |
| T133 | `auster remove` deletes Auster's app at its first yes and names it in that yes's sentence; a foreign `Auster.app` and a link named `Auster.app` are left, the link's target's sentinel too; `~/Applications/` is never deleted, even empty; a missing app is not an error | (a) delete an app that is not Auster's; (b) delete `~/Applications/` when empty; (c) delete the app only at the second yes |
| T134 | `auster key copy <name>` with two devices: `STUB_CLIP` equals the named device's `keys/<id>` less its newline, byte for byte; `clipboard.js` got it on standard input, and no argument, no output and no stub log holds it; an unknown name, a revoked one and a path refuse with nothing written; over SSH it refuses without running `clipboard.js`; a failing write is reported, exit 1. T84's run gains `key copy` and `auster open`, with the positive control that `STUB_CLIP` holds the key, while its search of every output and log finds none | (a) print the key; (b) pass it as an argument; (c) copy the wrong device's key; (d) claim it is on the clipboard when the write failed; (e) no host-only option (`clipboard.js`'s source); (f) no clear on Return |
| T98 | Its source check reads `common/app/Auster` and `common/app/Info.plist` as well as `common/*` | (b) `python3` in the app's program, red |
| T135 | The engine job's `--cors-origins` holds `http://127.0.0.1:<port>` beside its two home origins (T70's arguments) | (a) the third origin missing |

## 10. Exit criteria

1. AP1 to AP7 decided by the owner (AP3 before T129 is written).
2. Section 8's measurements still to make, made at the Mac and recorded in `docs/phase-2.md`; one that fails
   applies its fallback before any code.
3. T129 to T135 pass and T98's case; `tests/run.sh --mutants 129 130 131 132 133 134 135 98` ends with `0
   not`; the whole suite green.
4. On the development Mac's real install, at the screen: the app opens the chat page; `auster key copy`
   gives this Mac's browser a key that the page accepts; the page answers. Then a screenshot of the app in
   the Dock and the page, read by the owner against a list: the page and the Dock show no home address,
   `.local` name, device name or key (the address bar shows `127.0.0.1:<port>`, by design); and `grep -rF`
   of the installed app and of `logs/` for the home address, the `.local` name and each key finds nothing.

## 11. Phase, release and rollback

Phase 2, for the beta. It adds the app, three commands (`open`, `app`, `key copy`), `clipboard.js`, and a
third origin for the engine; it changes no record and no step of the server but B4 step 8's origins. Going
back is a later version without it: the app's own fallback alert covers a `bin/auster` that no longer knows
`open`, and moving the app to the Trash removes it; nothing depends on it.

**What a build touches:** `common/app/` (four files); `common/auster` (`open`, `open --app`, `app`, `key
copy`, the `key add` words, `au_usage`, `auster_main`'s dispatch, `au_remove` and `au_left`, the header);
`common/clipboard.js` (new, one of Auster's programs: `AU_PROGRAMS`); `common/auster-engine` (the third
origin); `common/driver.sh` (the app's step at a first install and after the programs step, the question's
words); `tests/stubs/osascript`, `tests/helpers.sh` (`make_home`, `stub_env`'s two logs, `app_run`);
`tests/t98-source-check.sh`; `tests/t84`, `t70`, `t129` to `t135` and their mutants; `docs/plans/v0.1.md`
(B3, B4 step 8, B6, B7, B8, D3.1, D3.10); `docs/phase-2.md`; `SPEC.md`; `CHANGELOG.md`; this plan's
as-built header.

## Review log

| Date | Pass | Lenses | Method | Models | Read against | Verdict |
|---|---|---|---|---|---|---|
| 2026-11-28 | 1, the whole plan | platform and builder (a bundle built and opened in a scratch folder, its icon rendered, the alert and the clipboard tried); security, privacy and architecture; test plan | three agents; the engine's origins measured by hand on the real install (no key used) | Opus for platform and security, Sonnet for the test plan; fold by Opus 5.5 | Auster `de6b9f4` | needs-rework from two lenses, build-ready-with-fixes from one; rewritten: the app out of Auster's programs, the key to this Mac's clipboard only, `--app`, open only when the page can answer, the engine's third origin (found by measurement), the stubs and mutants |

Key paths: `common/auster` (`au_status`, `au_ssh`, `au_ready`, the key commands, `au_qr_show`, `au_remove`,
`au_rollback_programs`), `common/auster-engine` (its launch line and origins), `common/driver.sh`
(`AU_PROGRAMS`, B3 step 6), `install.sh` (how the tree is fetched), `docs/brand/app-icon/`,
`docs/plans/v0.1.md` B3, B4, B6, B7, B8, D3.1, D3.10.
