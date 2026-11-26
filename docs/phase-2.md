# Phase 2 log: v0.1, the household recipe

Phase 2 builds v0.1 from [`docs/plans/v0.1.md`](plans/v0.1.md). Its first step settles the facts the
plan's D12 lists as open, where they can be settled on the development Mac. Everything here ran on build
`b12359`, on `127.0.0.1` only, with the logs and replies kept in the phase 1 workspace's
`runs/p2-first-step/` folder.

## First step: the open facts of D12 (2026-11-26)

### 1. The recipe's test, twice, at temperature 0

The twelve questions A7 names, taken from phase 1's set (`scripts/phase-1/questions.json`, numbers 49 to
52, 35 to 38, 3, 10, 45 and 47), asked with the recipe's system prompt at the recipe's largest setting,
four people at 32,768, with fitting off. Graded by `scripts/phase-1/quiz.py`, whose rules the recipe's
test carries over (A7).

| | Run 1 | Run 2 | Verdicts the same | Replies the same, byte for byte |
|---|---|---|---|---|
| Order 1, Mistral Small 4 | 12 of 12 | 12 of 12 | yes | 12 of 12 |
| Order 2, Magistral Small | 12 of 12 | 12 of 12 | yes | 11 of 12 |

Order 2's one differing reply is the bill split (question 3): the same working with the unknown named
`x` once and `A` once, and the same answer, 24. **Temperature 0 is not byte-for-byte repeatable with
four slots, so the test must grade answers, never compare replies.** It already does.

### 2. Tool calls

One request with a tool `add_to_list` (a list name from an enum, and an array of items), and the question
"Add milk and eggs to the shopping list.", twice for each build, at temperature 0.

| | Both runs |
|---|---|
| Order 1 | `finish_reason` `tool_calls`; one call, `add_to_list`, arguments that parse as JSON: `{"list": "shopping", "items": ["milk", "eggs"]}` |
| Order 2 | the same, and no reasoning text before the call |

**Both builds return a well-formed tool call** through the engine with `--jinja` and the recipe's
template. Whether the recipe's test should ask one stays the plan's choice (A7).

### 3. Order 1's temperature

Phase 1's 56 household questions, with the recipe's system prompt, graded by `quiz.py` (which now takes
`QUIZ_TEMPERATURE`).

| Temperature | Correct of 56 |
|---|---|
| 0 | 53 |
| 0.3 | 51, 53, 52 (three runs) |
| 0.7 | 50, 51, 51 (three runs) |

**Order 1 answers best at 0**, and no worse than at 0.3 on any run. The plan's 0.3 was chosen without a
measurement (A6); this says 0, or at most a small value, for the household's questions.

### 4. The speed question

"Count from 1 to 300, one number per line.", `max_tokens` 128, temperature 0, the rate the engine
reports (A5):

| | Three runs |
|---|---|
| Order 1, 4 × 32K | 79.5, 79.6, 80.1 tok/s |
| Order 2, 4 × 32K | 35.1, 36.6, 36.8 tok/s |

Each set lies within 5 %, so half of the baseline (B5's `slow`) is far from noise.

### 5. Whether the chat page sends a temperature of its own

The engine's own chat page, with the recipe's UI config, sent one question; the engine's log at
`-lv 4` shows the sampling it used. Started with `--temp 0.7 --top-p 0.95`, the page's request ran at
0.700 and 0.950; started again with `--temp 0.3 --top-p 0.9`, at 0.300 and 0.900. **The chat page sends
no sampling values of its own** (at its default settings), so the engine's `--temp` and `--top-p` reach
the household's chats.

### 6. Two engines side by side

Order 2 served at 4 × 32K with fitting off (34,447 MiB on the GPU), and a second engine of the same model
started beside it, as a side-by-side update would start its candidate.

**Run 1, a candidate that fits by section C's sum,** one person at 8,192: 34,447 + 14,822 + 1,024 =
50,293 MiB, within the limit of 53,084.

- Both answer. Alone, each writes at about 35 tok/s; writing at the same time, 20.2 and 20.0 tok/s.
- **The candidate believed the whole GPU was free:** its fitting reported 53,083 MiB of free device
  memory, with 34,447 MiB already held by the serving engine. The engine's own view of free memory does
  not see another process, so **section C's sum is the only guard** when two engines share a Mac.

**Runs 2 and 3, a candidate that does not fit by the sum,** one person at 40,960, fitting off: 34,447 +
19,974 = 54,421 MiB, about 1.3 GiB over the limit, though well inside the Mac's memory.

- The candidate came up, `/health` 200, and answered every request with HTTP 500, "Compute error".
- **So did the engine already serving,** which had answered at 35 tok/s a moment before. In run 3 no
  request was sent to the candidate at all: loading it was enough.
- **The serving engine did not recover.** With the candidate stopped, it went on answering HTTP 500 to
  every request, its process alive. Only a restart brings it back.

What this means for the plan, for the owner to weigh:

- An update that runs a side-by-side test must restart the serving engine and make the server check
  after any test that may have overflowed, not only check that its process is alive (D3.6's present
  wording).
- **Anything else on the Mac that takes GPU memory past the limit** (another model, a game, a 3D
  application) can leave the household's engine answering HTTP 500 until it is restarted. The check job
  sees it as `failed`, but by decision (D2.2, BD11) it never restarts the server, so the household waits
  for a person and a notification that comes after two failed probes. Whether the check job should
  restart an engine that answers 500 while its process is alive is a new decision.

### 7. A QR code from JavaScript for Automation

A JavaScript for Automation script, reading the text on its standard input, made a QR code with Core
Image's `CIQRCodeGenerator` (correction level M): 31 × 31 modules for a 47-character test string (not a
key), drawn as 18 lines of half-block characters, in 0.11 s. Read back from the same image with Core
Image's `CIDetector`, it decoded to the exact text. **The drawing needs nothing but what macOS ships.**
Whether an iPad's camera reads it from Terminal, with Terminal's own line spacing, still needs the iPad.

### 8. Router mode

Build `b12359` offers `--models-dir`, `--models-preset` (an INI file of per-model settings),
`--models-max` (default 4), `--models-memory-margin` and `--models-autoload`. v0.1 does not use router
mode, and nothing in V6, V7 or U5 rests on how it behaves; that test waits for the phase that would use
it.

### Still open, and why

These need the owner, another device or another Mac, or a lasting change to this Mac:

- Whether an iPad's camera reads the QR code from Terminal (section 7).
- Whether `launchctl enable` after `bootout` leaves a label in launchd's list of overrides: the check
  itself writes a lasting entry into this Mac's launchd settings.
- The engine's speeds and start times under launchd with `ProcessType` `Interactive`: a launchd job on
  this Mac, with the owner's word.
- The firewall's questions, a `.local` name with IPv6 from an iPad, `launchctl` over SSH, FileVault over
  SSH, the GPU in a daemon, a first notification on a fresh account, and older macOS versions.
- The 12 GiB left for the rest of the Mac, on the 36 GB MacBook (UL6).
- How long a warm-up question must be after a cold start: it needs the file cache emptied, which takes
  an administrator (`sudo purge`).
