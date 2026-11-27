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

### 9. How much irrelevant memory a build takes (for the local-layer plan)

Phase 1's 56 household questions, asked with the recipe's system prompt followed by "Things the household
has asked you to remember:" and 0, 20, 80 or 300 invented facts about invented relatives and neighbours
(their colours, cars, hobbies, books, foods, plants, teams, cats, allergies and instruments). The facts
avoid weekdays, times, numbers and every subject of the questions, so none can help or bear on an answer.
About 0, 165, 610 and 2,260 words. Each model served at four people × 32K with fitting off, temperature
0, one run each. A reply "names a remembered fact" when it contains one of 78 words found only in the facts.

| Facts added | none | 20 | 80 | 300 |
|---|---|---|---|---|
| Order 2, Magistral Small | 53 | 52 | 53 | 53 |
| Order 1, Mistral Small 4 | 50 | 52 | 43 | 47 |

No reply named a remembered fact. Order 1's losses at 80 facts were all in the answer's form: correct
answers without the requested `Answer:` line (questions 3, 4, 7, 52), a JSON list instead of an object
(38), and the literal `<answer>` (53). Its score with no facts, 50, differs from this morning's 53 on the
same questions (section 3) on questions 9, 22 and 23: one run is not enough to compare builds closely.
The facts, the system prompts, the replies and the word list are in the workspace's `runs/p2-memory/`.

### 10. Wrong memories, and notes behind pointers (for the local-layer plan)

Two measurements the local-layer plan asked for after section 9 (its M10 and M3a), run the same way:
each build served at four people × 32K with fitting off, the household's system prompt, temperature 0,
one question at a time. Every condition ran three times, with the remembered facts or the index shuffled
differently each time, and the same shuffles for both builds. The questions, facts and topics are
invented and kept beside the scripts in `scripts/phase-2/` (`memory-wrong.json`, `memory-layers.json`).
`memory-run.py` serves a build and runs `memory-wrong.py` (A) and `memory-layers.py` (B) against it; both
grade with `quiz.py`, imported unchanged.

**A. Memories that matter but are wrong.** Twenty household questions ("Which day does our green bin go
out?") whose answer is only in the remembered facts, which follow "Today is 26 November 2026." Each
question was asked in four conditions, its correct fact worded the same, date included, in all four:

- **clean:** the correct fact ("From 1 October: the green bin goes out on Tuesdays.") among 20 filler
  facts from section 9's set, taken from subjects no question asks about;
- **replaced:** an older fact on the same subject beside it ("From 1 March: the green bin goes out on
  Thursdays.");
- **wrong person:** the same attribute for someone else ("Aunt Dorothea drives a red hatchback" beside
  "Uncle Godfrey drives a blue estate", asked about Aunt Dorothea);
- **near miss:** the same person or thing with a neighbouring fact that does not answer ("Mum takes two
  sugars in her tea" beside "three sugars in her coffee", asked about her tea). Another person's sugars
  would have been the wrong-person case again.

Each distractor carries the pattern of its own value, so a reply that gives it ("gave the wrong fact") is
told apart from a plain miss. The facts' dates are taken out of a reply before grading, so that the 1 of
"1 October" is never read as an answer.

| Correct of 60 (three runs of 20) | Clean | Replaced | Wrong person | Near miss |
|---|---|---|---|---|
| Order 2, Magistral Small | 60 (20, 20, 20) | 39 (13, 14, 12) | 60 (20, 20, 20) | 60 (20, 20, 20) |
| Order 1, Mistral Small 4 | 59 (20, 19, 20) | 37 (11, 11, 15) | 58 (20, 19, 19) | 59 (20, 20, 19) |

| Gave the wrong fact, of 60 | Replaced | Wrong person | Near miss |
|---|---|---|---|
| Order 2 | 20 (7, 5, 8), and 1 naming both | 0 | 0 |
| Order 1 | 19 (8, 7, 4), and 4 naming both | 1 (0, 0, 1), and 1 naming both | 0 |

Order 1's two other misses: the right fact without the `Answer:` line (clean), and "One sugar", which is
neither fact (near miss).

**Which of the two dated facts a build gave followed where they sat in the list, not their dates.** The
replaced condition again, split by position:

| Where the newer fact sat | Answers | Order 2: newer, older, both | Order 1: newer, older, both |
|---|---|---|---|
| After the older one | 34 | 31, 2, 1 | 26, 5, 3 |
| Before the older one | 26 | 8, 18, 0 | 11, 14, 1 |

Order 2 sometimes said so in words: "Today is 26 November 2026, which is after 1 March 2026. Therefore,
the green bin goes out on Thursdays." Order 1's answers naming both merge the two facts ("Mondays and
Wednesdays", "Red and silver").

**B. Notes behind pointers.** An index of 15 topics in the system prompt, one line each with an opaque
pointer ("- [r8kd] The car: tyres, servicing and the MOT"), after a line saying that only the index is
shown and each topic's notes are kept separately under its pointer. The notes, three or four facts a
topic, are held by the script. Twelve questions, each answered only in one topic's notes ("What pressure
do the car's front tyres need?": 39 psi). The index was shuffled for each question and run, the same way
in every condition:

1. **index only:** a right answer is impossible;
2. **tool:** an `open_detail(pointer)` tool is offered; the script answers each call with that topic's
   notes (or "No topic has the pointer …") and asks again, for up to four rounds;
3. **reminder:** no tool; after the first answer, the same request as in condition 1, the script asks
   once more: "These details exist for topic X: <notes>. Check them before you answer.", with the
   question's `Answer:` tail;
4. **fetched first:** the right topic's notes are added to the system prompt before the question.

In conditions 3 and 4 the script names the right topic itself. They measure what a build does with the
right notes, not whether Auster's matching would find them.

| Correct of 36 (three runs of 12) | Index only | Tool | Reminder | Fetched first |
|---|---|---|---|---|
| Order 2 | 0 | 34 (11, 12, 11) | 36 (12, 12, 12) | 36 (12, 12, 12) |
| Order 1 | 0 | 25 (9, 9, 7) | 27 (9, 9, 9) | 36 (12, 12, 12) |

With the index only, what each build said instead. The reminder's first pass gave the same reply, byte
for byte, in all 36 for both builds.

| Of 36 | Invented an answer | Said it lacked the notes, or pointed to them | No answer (the literal `<answer>`) |
|---|---|---|---|
| Order 2 | 25 | 11 | 0 |
| Order 1 | 23 | 11 | 2 |

The invented answers are ordinary guesses stated as facts: 32 psi, "every three months", "the study",
"Grandma Hester does not eat nuts". A reply counts as pointing when its `Answer:` line holds only a
pointer or a topic's index line. Order 1 often put the pointer in front of an invented value ("[m3vq] The
ferry leaves at 9:30 AM"), which counts as invented. The classes come from
`memory-layers.py --reclassify`, and all 72 were checked by eye.

The tool condition:

| Of 36 | Called the tool | Opened the right topic | Then right | Right, but no `Answer:` line |
|---|---|---|---|---|
| Order 2 | 36 | 34 | 34 | 0 |
| Order 1 | 36 | 29 | 25 | 4 |

- Both builds called the tool for every question, nearly always once. Order 2's two wrong opens were the
  allotment for "On which day are the tomatoes fed?", which the topics leave plausible.
- **Order 1 opened a wrong topic seven times and then answered from it** ("Grandma Hester does not eat
  meat", from the dog's notes). Two were the same allotment. Five came when the right topic was the last
  line of the index: it was last in 7 of the 36 questions, and order 1 opened it in 2 of those, against
  27 of the other 29. One question went four rounds without an answer, the pointer sent as a whole index
  line.

The reminder: order 2 was right in all 36. Of order 1's nine misses, **five kept the invented first
answer** with the right notes in front of it ("1 to 1.5 bar", after quoting the notes' heating times
back), three took the wrong line from the notes or left it out (the vet's name, asked how often the dog
is wormed), and one had the right content and `Answer: <answer>`.

Time per question, mean, every request included:

| Wall clock, tokens written | Index only | Tool | Reminder | Fetched first |
|---|---|---|---|---|
| Order 2 | 1.33 s, 35 | 0.94 s, 24 | 1.92 s, 61 | 0.60 s, 17 |
| Order 1 | 0.55 s, 25 | 0.68 s, 29 | 0.83 s, 45 | 0.30 s, 12 |

The prompts were short, 360 to 490 tokens, so the time is mostly writing. A tool question took two
requests (order 1, 2.1 on average); a reminder always takes two. Index only is slower than fetched first
because invented answers run longer.

What the figures show:

- **Both builds latch on to an out-of-date fact, and on nothing else measured here.** Given an older and
  a newer fact on the same subject, each gave the older one in about a third of answers, choosing by
  position in the list rather than by the date written in each. The wrong person and the near miss cost
  almost nothing on either build.
- **An index alone draws an invented answer more often than "I don't know"**: two times in three, on
  both builds.
- **With the right notes put in front of it, each build was right every time,** and fastest.
- **Following pointers, and being reminded, worked on order 2 and not reliably on order 1,** the larger
  build. As in section 9, which build suffers is not predicted by its size.

What they do not show:

- Facts here are one line each, every question names its person exactly, a request carries at most one
  distractor, and the list is 22 facts long. Not tested: pronouns and nicknames, "Mum" as seen by
  different people, several out-of-date versions of one fact, long lists, facts a model inferred.
- Whether Auster's own matching finds the right topic: the reminder and fetched conditions were given it.
- Small counts behind some findings: order 1's wrong opens are 7 cases and its last-line pattern rests on
  7 questions. The position effect in A is large but comes from 26 and 34 answers.
- Noise: one run moves by about three questions in 56 (section 9). Here the replaced condition's three
  runs spread from 12 to 14 of 20 (order 2) and 11 to 15 (order 1), and A's other conditions moved by
  at most one. In B, order 1's tool runs spread from 7 to 9 of 12, the rest by at most one. The
  irrelevant-fact quiz of section 9 has still not been repeated.
- Everything ran at temperature 0 only.

The replies, with the facts or index order each request carried, the server logs and the counts are in
the workspace's `runs/p2-memory-2/` (`order1-*`, `order2-*`). The index-only classes in the run logs
(`order*-run.txt`) come from a first, cruder classifier that counted a pointer in front of an invented
value as pointing; `reclassify.txt` and the summary files hold the final ones.

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
