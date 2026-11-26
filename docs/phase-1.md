# Phase 1 log: the household assistant, by hand

Everything done by hand on the development Mac, in order, with what was measured. Phase 2 turns this
list into the installer (`SPEC.md`, phase 1, exit criterion 5). The Mac is a Mac Studio, M5 Max, 64 GB,
macOS 27.2.1.

**Rule for this phase: the checks Auster will make are made by hand first, and nobody's word is taken
for them.** That includes the owner's. Before each download or measurement the step below is run again
and its numbers recorded.

## Step 0. The checks before anything is fetched (2026-11-26, 03:40)

| | Check | Measured | Verdict |
|---|---|---|---|
| 1 | Free disk | 422.2 GB free now; 459.0 GB counting what macOS can clear; 1,995 GB in all | Room for every candidate at once (about 142 GB), leaving about 280 GB |
| 2 | Memory | 64 GB installed. 53,084 MiB (55.7 GB) usable by the GPU, all of it free. The system reports 84% of memory free | Room for model A at any of its sizes |
| 3 | Nothing competing | No game, no Wine, no model running; the processor 98% idle. **Another project's session on this Mac was busy** | Fine for a download. A measurement waits until that session is idle |
| 4 | The publisher still offers the pinned file | `Magistral-Small-2509-Q4_K_M.gguf` at commit `429b90d8…`: size 14,334,432,256 and hash `d3a024d2…a43434`, both equal to what was recorded | Pass |
| 5 | The engine | llama.cpp 0.3.0 installed; 1.0.0 on offer | To be updated before the first measurement |
| 6 | Port and jobs | Nothing listens on 8080; no Auster launch job exists | Pass |
| 7 | Staying up | Sleep, restart after a power cut and FileVault checked; this Mac's settings are kept out of the repo | Fine for phase 1's measurements. The restart question is the plan's AD15 |

What this step showed about the check Auster needs:

- **"Free" has two readings.** macOS reported 37 GB more as available once it counts what it can clear.
  The rule has to say which it uses. Earlier the same day the two readings were 63.5 GB and 98.6 GB.
- **Free disk changes without Auster doing anything.** It went from 64 GB to 422 GB in a few hours
  because the owner cleared space. A figure taken at the question can be wrong by the download, which is
  why the plan works room out again before the download starts (D3.6 step 3).
- **The publisher is asked before the download, not trusted from a note.** The size and hash matched,
  a few hours after they were first read.
- **Another project on the same Mac matters to a measurement and not to a download.** Auster cannot see
  that for a household; the guide should say when measurements are worth taking.

## Step 1. The engine (2026-11-26)

The engine is placed in phase 1's workspace, `~/Library/Developer/Auster/phase-1/engine/`, not taken
from Homebrew: other projects on this Mac use Homebrew's copy, and the v0.1 plan leans towards Auster
fetching a numbered build itself (BD2). This step is that fetch, by hand.

| | What was done | Result |
|---|---|---|
| 1 | Asked GitHub's API for release `b12359`, the build that version 1.0.0 is | Published 2026-11-13, marked prerelease. `llama-b12359-bin-macos-arm64.tar.gz`, 16,907,811 bytes, sha256 `82b00abc…ccde75` |
| 2 | Fetched it with curl: HTTPS only, redirects HTTPS only | 16,907,811 bytes in 0.8 s. sha256 equal to GitHub's |
| 3 | Unpacked it | One folder, `llama-b12359/`, holding the programs and their libraries side by side |
| 4 | Looked at the signature | Signed ad hoc by the linker, no team. No quarantine mark on the archive or the programs |
| 5 | Ran it | `1.0.0-dev (build 12359, commit b1b770d90)`. Sees the GPU: Apple M5 Max, 53,084 MiB |

What the help of this build says about running it for a household:

- **Built-in tools are off by default** (`--tools`: "do not enable in untrusted environments"). Auster
  leaves them off.
- **Cross-site requests are allowed from any website by default** (`--cors-origins`: `*`). Auster sets
  it to the server's own address.
- **The slot monitor is on by default** (`--slots`). Whether one person can read another's
  conversation through it is tested in step 3.
- **`--offline`** stops the engine reaching the network. Auster uses it.
- The default port is 9931.

## Step 2. Model A fetched and verified (2026-11-26, 03:45)

| | What was done | Result |
|---|---|---|
| 1 | Fetched `Magistral-Small-2509-Q4_K_M.gguf` from `mistralai/Magistral-Small-2509-GGUF` at commit `429b90d8…`, with no login, HTTPS only, resumable | 14,334,432,256 bytes in 444 s: 32.3 MB/s, about 7.4 minutes |
| 2 | Compared the size, then the sha256 | Both equal to the publisher's. Renamed from `.part` only after both matched, and made read-only |
| 3 | Hashed it twice, to time it (AD13) | `shasum -a 256`: **24.5 s**. `openssl dgst -sha256`: **5.4 s**, the same hash. Both runs probably read from memory, since the file had just been written. Auster should hash with `openssl` |
| 4 | Read the file's own metadata | Architecture `llama`, 40 layers, 8 key-value heads of 128. **Its context limit is 40,960 tokens.** Mistral's card says 128K, with quality falling past 40K; this file says 40K. **It carries no chat template and no licence field** |

## Step 3. Speed, memory, keys and the chat page (2026-11-26, 03:53 to 04:30)

Measured with `scripts/phase-1/measure-server.sh` and `llama-bench`, on the loopback address only, with
`--offline`. No game or other model was running. One sample of the GPU read 98% busy with nothing of ours
running, and five samples a moment later read 0%; a single sample is not a reliable measure, and the
speeds agreed across runs.

**Speed** (`llama-bench`, three repetitions each):

| | Empty context | At 16K of context |
|---|---|---|
| Reading a prompt of 512 tokens | 992 tok/s | 651 tok/s |
| Reading a prompt of 4,096 tokens | 943 tok/s | 632 tok/s |
| Writing 128 tokens | **38.1 tok/s** | **30.7 tok/s** |

At 38.1 tok/s the whole 14.3 GB file is read 38 times a second: about 546 GB/s, 89% of this Mac's
614 GB/s. Writing is limited by memory bandwidth, as the Devstral trial found.

Through the server, one person: a 1K prompt read at 684 to 914 tok/s, an 8K prompt at 854, a 33K prompt
at 638; answers written at 37.1, 34.1 and 25.5 tok/s.

**Two people at once** (four slots): each got **31.2 tok/s**, so 62 tok/s together. Two people do not
halve the speed.

**Memory:** 19.7 GiB resident with a 40,960-token context, whether one slot has all of it or four
slots share it. That is the file (13.35 GiB) plus **160 KiB per token of context** (6.25 GiB at 40K):
40 layers × 8 heads × 128 × 2 (keys and values) × 2 bytes. `footprint` reports 6.6 GB, which leaves out
the file's pages. For the capability rule: memory ≈ file size + 160 KiB × context, for this model.

**Time to answer:** the server answered `/health` 1.3 to 2.9 s after it started, with the file already
in memory. A cold start from disk was not measured: it needs `sudo purge`. A short question then took
0.07 s to its first token.

**Keys** (`--api-key-file`):

| Request | Answer |
|---|---|
| No key, or a wrong key | 401 |
| Key A, key B | 200 |
| `/health` with no key | 200 |
| `/props`, `/v1/models` with no key | 401 |
| The chat page `/` with no key | It loads, then asks for a key |
| Key B removed from the file, server still running | **Still 200.** The server reads the file once |
| The same, after a restart (1.3 s) | 401 for B, 200 for A |

So **revoking a key means a restart**, about 1.3 s with the model in memory.

**The slot monitor** (`/slots`, on by default) answers any household key with every slot's state:
whether it is busy, how many tokens its last prompt had, and its settings. It does not show what was
said. It still tells one person when another is using the server, so Auster runs with `--no-slots`
(which then answers 501).

**Cross-site requests:** with `--cors-origins` set to the server's own address, a page from another
origin is not allowed. The default is any origin.

**The chat template.** This was the largest finding:

1. **With no template, chat is broken.** The file has none, and the server sent the question to the
   model as raw text (8 tokens). The model wrote 200 tokens about "Mistral 7B".
2. **`--chat-template mistral-v7-tekken` alone is worse.** With the Jinja engine on, which is the
   default, the name is taken as the text of a template, and the model is given its name as the prompt.
3. **`--no-jinja --chat-template mistral-v7-tekken` works for the API,** but the engine's own chat page
   sends a `tools` field and is refused ("tools param requires --jinja flag").
4. **Mistral publishes no template for this model.** Its card says so, and recommends its own Python
   server, `mistral-common`, in front of llama.cpp. That would add Python.
5. **llama.cpp's repository ships `mistralai-Ministral-3-14B-Reasoning-2512.jinja`** at this build (6,206
   bytes, git blob `beb4d612…`, sha256 `39f03c38…`; fetched and checked against GitHub's hash). Given the
   same conversation with a system prompt, it renders exactly the same text as the built-in
   `mistral-v7-tekken`. Without one, it inserts a default that is **exactly Magistral's own published
   system prompt**. It separates the model's `[THINK]` reasoning from the answer. The chat page works
   with it.

   The other candidate, `Mistral-Small-3.2-24B-Instruct-2506.jinja`, renders the same with a system
   prompt, but its default says "You are Mistral Small 3" with a 2023 knowledge date. It is not used.

**Reasoning is a matter of the system prompt.** With Magistral's reasoning prompt, a short household
question took 7 s to the first word of the answer and 8.6 s in all, after 1,095 characters of thinking.
With a plain one ("You are the household assistant for a family. Answer briefly and plainly.") it took
0.16 s to the first word and 1.4 s in all. The chat page sends no system prompt, so the template's
reasoning default applies: a dinner question took 18 s and 665 tokens, most of them thinking.

**The chat page's system prompt** (tried later the same day). `--ui-config-file` with
`{"systemMessage": "..."}` reaches the page through `/props` (`ui_settings`). On a browser that had never
opened the page, the dinner question was answered directly: 60 tokens in 1.6 s, with no reasoning. On a
browser that had opened the page before, its own saved settings won, with an empty system prompt, and the
model reasoned at length. This test ran without a key: the permission system declined to put a key into
the transcript again, and keys had already been tested through the API.

Two more things the page does:

- **It keeps the key in the browser's local storage, in plain text** (`LlamaUi.config`). On a shared
  family iPad, anyone using that browser can read it.
- **`/props`, which any key holder can read, gives the model's full path on disk,** and with it the
  Mac's account name.

### What the recipe needs, from steps 1 to 3

- **The engine:** build `b12359`, fetched and checked by sha256, with `--offline`, `--no-slots`,
  `--cors-origins` set to its own address, `--api-key-file`, and the Jinja engine on.
- **The model file, and beside it a template file and a system prompt**, each pinned by sha256. The
  registry line of the v0.1 plan already has a template hash. The system prompt needs one too.
- **The chat page's system prompt, set by the server** with `--ui-config-file`. The guide says how to
  reset a device whose browser has saved settings of its own.
- **One key for each device, not each person,** since the page stores it on the device in plain text.
  Whether that is good enough for a household is a decision for section B.
- **Revoking a key restarts the engine.** About 1.3 s with the model in memory. Phase 6's front door
  could avoid it.
- **Hashing uses `openssl`,** four to five times faster than `shasum` here.

## Step 4. Model B, Mistral Small 4 (2026-11-26, 04:35 to 05:25)

> Corrected the same day: some figures in steps 4 and 6 and in the table of the three were first
> written as GiB when they were MiB divided by 1,000. They are now MiB divided by 1,024.

**Fetched** with `scripts/phase-1/fetch-model.sh`: `Mistral-Small-4-119B-2603-UD-IQ3_S.gguf` from
`unsloth/Mistral-Small-4-119B-2603-GGUF` at commit `bd93c721…`, the build Mistral's own card links to.
The checks first: 379 GiB free, and the publisher's size and hash equal to its API's. 44,407,639,744
bytes in 1,971 s (22.5 MB/s, sharing the line with model C's download). sha256 equal; hashing took
**18.3 s** with `openssl`.

**The file:** architecture `mistral4`, 36 layers, 128 experts with 4 used per token and one shared,
compressed attention (a 256-wide latent). Context stated as 1,048,576. Licence field Apache-2.0. **It
carries its own chat template** (14,121 characters, with tools, reasoning and a default system prompt).

**Memory, from the engine's own report** (`-lv 4`; the process's resident size is not a reliable
measure for this model: it read 3.0 GiB in one run and 44.3 GiB in another):

| | Model A | Model B |
|---|---|---|
| Weights on the GPU | 13.0 GiB (13,302 MiB) | 40.9 GiB (41,923 MiB) |
| Context cache per token | 160 KiB | **22.5 KiB** |
| In all at 32K | about 18.3 GiB | about 41.8 GiB |
| In all at 128K | not possible: 40K is the file's limit | **about 44.1 GiB** |

So **model B fits this Mac at about 3 bits with a long context**, leaving about 7.8 GiB of the 51.8 GiB
the GPU may use. The review's arithmetic ("a 119B model does not fit at 4 bits") stands; at 3 bits it
does, with room.

**Speed** (`llama-bench`):

| | Empty context | At 16K of context |
|---|---|---|
| Reading a prompt of 512 / 4,096 tokens | 1,701 / 1,305 tok/s | 433 / 402 tok/s |
| Writing 128 tokens | **81.2 tok/s** | **50.5 tok/s** |

Through the server: one person wrote at 77.9 tok/s after a 1K prompt, 60.9 after 8K, 36.6 after 31K.
**Two people at once got 59.6 tok/s each**, with four slots sharing a 128K context. Ready 2.4 to 2.6 s
after a start with the file in memory; 19.4 s the first time, with most of it on disk. A short question's
first token came 0.5 to 1.0 s after it was asked. Keys, the slot monitor and cross-site requests behave
as for model A.

B writes twice as fast as A when the context is short, because only 4 of its 128 experts are read for
each token. Its advantage shrinks as the context grows.

## Step 5. A small quiz: does B at 3 bits answer worse than A? (2026-11-26)

`scripts/phase-1/quiz.py`: 15 household questions with exact answers (portions, oven times, a train
journey, a bill split, a school-term date, two that test following an instruction), at temperature 0,
with the same plain household system prompt, graded by the program.

| | Correct | Written | Time | Wrong |
|---|---|---|---|---|
| A, Magistral Small, 4-bit | 13 of 15 | 716 tokens | 21 s | the oven time (16:30 for 16:45); the term date (13 April for 10 April) |
| B, Mistral Small 4, about 3 bits | 13 of 15 | 228 tokens | 5 s | the term date: it asked for the year instead of answering; and "Carrots, broccoli, spinach." failed the grader on its full stop, which a person would accept |

**Fifteen questions cannot rank two models this close, and this is not a benchmark.** What it shows is
narrower: B at about 3 bits is not obviously worse than A at 4 bits on plain household questions, and it
answers in a third of the words and a quarter of the time. A larger graded set is needed before the
recipe's model is chosen.

## Step 6. Model C, Apertus 70B (2026-11-26, 04:35 to 05:40)

**Fetched** with the same script: `Apertus-70B-Instruct-2509-Q4_K_M.gguf` from
`unsloth/Apertus-70B-Instruct-2509-GGUF` at commit `aff98136…`. 43,721,598,624 bytes in 3,077 s
(14.2 MB/s, sharing the line with model B for most of it). sha256 equal; hashing took **17.0 s**.

**The file:** architecture `apertus`, 80 layers, 8 key-value heads of 128. **Its context limit is
65,536 tokens.** It carries its own chat template (14,244 characters, with tools; no reasoning marks).
**No licence field** in the file; the publisher's card says Apache-2.0.

**Memory** (the engine's own report):

| Context | Weights on the GPU | Context cache | In all | Ready after |
|---|---|---|---|---|
| 16K | 40.1 GiB | 5.0 GiB | about 45.3 GiB | 3.3 s |
| 32K | 40.1 GiB | 10.0 GiB | about 50.4 GiB | 3.8 s |
| 48K | **36.4 GiB**, part moved off the GPU | 13.7 GiB | about 50.4 GiB | 8.9 s |

**320 KiB of cache per token**, twice model A's. At 32K it sits just under the 51.8 GiB the GPU may use
(`recommendedMaxWorkingSetSize` = 55,662.79 MB). **At 48K the engine moved part of the model off the GPU
by itself** to make room, which slows it, and said so only at debug level. Auster's capability rule has
to refuse that, not find it afterwards. With C loaded, the whole Mac had 5 to 9% of its memory free.

**Speed** (`llama-bench`, two repetitions):

| | Empty context | At 8K of context |
|---|---|---|
| Reading a prompt of 512 / 4,096 tokens | 301 / 273 tok/s | 223 / 212 tok/s |
| Writing 128 tokens | **11.6 tok/s** | **10.8 tok/s** |

Through the server: 12.3 tok/s after a 1K prompt, 11.2 after 6K; **two people at once got 10.1 tok/s
each**. 11.6 tok/s × 43.7 GB is about 510 GB/s: limited by memory bandwidth, like A.

**The quiz:** the program counted 12 of 15. One of the three it marked wrong was the grader's fault: C
wrote "Answer:" twice on one line and the grader read the first number (1260) instead of the last (105).
Its two real mistakes: 10 days after a Wednesday is a Wednesday (it is a Saturday), and the term date
(13 April for 10 April). 926 tokens in **79 s**. The grader now reads the last "Answer:" and accepts a
trailing full stop; the counts in this file were made before that change and are read again by hand here.

## Step 7. The home network and an iPad (2026-11-26)

Model B, with four slots sharing a 128K context, `--ui-config-file` setting the household system prompt,
`--no-slots`, `--offline`, and `--cors-origins` set to its own address. The details of this Mac's
network are kept out of this public file.

**Where it listened.** The server was bound to the Mac's one home-network address, not to every
interface: it answered there and not on `127.0.0.1`. A Mac usually has several network interfaces,
tunnels among them. Whether the Mac's firewall would have asked or stopped anything depends on how the
household has set it, so **binding to one address, and the keys, must be treated as the only barriers.**

**From the network side,** checked from the Mac against that address: no key 401; the iPad's key 200;
the second device's key 200; the chat page loads as a browser asks for it.

**Getting the key onto the iPad, without it passing through anything but the two devices:**

| Tried | Result |
|---|---|
| The Mac's clipboard, for Universal Clipboard | **Did not work** for the owner, twice. The server logged requests with a wrong key meanwhile |
| A QR code of the key, made with Core Image on the Mac, shown in Preview, scanned with the iPad's Camera | **Worked.** The image was readable by the owner's account only, and was deleted after |

The image file was deleted, but Preview kept showing it until the window was closed by hand. Closing it by
AppleScript timed out (`-1712`), most likely on a permission prompt, and quitting Preview would have
closed the owner's other documents. **Showing a key on screen needs a window Auster opens and closes
itself.**

**On the iPad: "it's working and quick"** (the owner). From the server's log:

| | Prompt | Read in | Written |
|---|---|---|---|
| First question | 294 tokens | **5.4 s** (54 tok/s) | 14 tokens at 78 tok/s |
| Second | 16 new tokens | 0.10 s | 12 tokens at 74 tok/s |
| Third | 19 new tokens | 0.12 s | 36 tokens at 76 tok/s |

**The first question after a start is slow to read:** 5.4 s for 294 tokens, against 0.1 s for each
later one. That is most probably the model's weights still being read from disk on first use. The
guide should say so, or Auster can warm the model up after a start.

What the recipe needs from this step:

- **A way to hand a device its key:** a QR code in a window Auster opens and closes, shown only on the
  Mac, never sent anywhere.
- **A QR that signs the device in, not just gives it the key, needs phase 6's front door.** Checked the
  same day: the chat page reads only `q`, `model` and `load` from its address, never a key. Serving a
  pairing page of Auster's own through the engine (`--path`) removes the engine's chat page (`/` answers
  404) and puts the pairing page behind the key (401). A pairing page on another port is another origin
  and cannot hand the key to the chat page. A front door could serve `/pair#<key>` at the chat page's own
  address, store the key, and wipe it from the address and the browser's history, which a household's
  devices may share. Until then: a QR of the key alone, or one QR for the address and one for the key.
- **The address to listen on, chosen with care,** whatever the Mac's firewall setting.
- **Plain HTTP for now.** The key crosses the home Wi-Fi unencrypted. HTTPS needs a certificate the
  household's devices trust: a decision for section B.

## Step 8. The one MLX measurement, of model A (2026-11-26, 13:20 to 13:50)

**The build:** `lmstudio-community/Magistral-Small-2509-MLX-4bit` at commit `bb18789f…`, the most-used MLX
build of model A (MLX's own community build needs a login). 15 files, 14.12 GB, fetched in 422 s; every
large file checked against its sha256 and every small one against its git hash, none failing.

**The engine:** Apple's `mlx` 0.32.5 and `mlx-lm` 0.32.2, pinned, in a throwaway Python 3.12 environment
in the workspace (389 MB). The plan preferred the Swift stack; it has no ready command to run, and the
work on the GPU is MLX's either way. Python is not something Auster would ship; this was a measurement.
MLX sees the same 51.8 GiB as the limit for the GPU.

**`mlx_lm.benchmark`, three trials each, against `llama-bench` on Mistral's own Q4_K_M:**

| | llama.cpp | MLX |
|---|---|---|
| Writing 128 tokens after a short prompt | 38.1 tok/s | 37.7 tok/s |
| Writing 128 tokens after 16K | 30.7 tok/s | 31.0 tok/s |
| Reading a prompt of 512 tokens | 992 tok/s | 1,137 tok/s |
| Reading a prompt of 4,096 tokens | 943 tok/s | 1,309 tok/s |
| Reading a prompt of 16,384 tokens | 632 to 943 tok/s, falling as the context fills | 1,190 tok/s |
| Memory at its peak | about 13.8 GiB plus the cache | 13.8 GiB at 512, 16.8 GiB at 16K |

The 16K rows are not quite the same test. `llama-bench` reads 4,096 tokens on top of 16K already held;
MLX reads one 16K prompt and reports its average.

**What it means:** writing is the same, because both are limited by memory bandwidth. MLX reads prompts
about 15 to 50% faster. That matters for long documents and long conversations, and little for ordinary
questions. By the rule agreed before (`SPEC.md`), the gap is not large enough to move MLX ahead of phase
6, and it was not run on model B. A Swift build of MLX inside Auster's own app stays the long-run shape.

## Step 9. A larger quiz: 56 household questions (2026-11-26)

`scripts/phase-1/questions.json`: 56 questions in seven groups (sums 16, times and dates 11, units 7,
following a format 8, reading a house note 6, safety 4, common facts 4), each with one answer checked by
computation before any model saw it. `quiz.py` asks each at temperature 0 with the plain household system
prompt, grades it, and keeps every reply so that a grade can be read again by hand.

The grader was wrong twice, and was fixed and tested on 29 cases that must pass or fail. **"9/4 cups" was
marked wrong** (it read the 9); and an answer such as "1260 / 12 = 105" or "2 1/4" would have been. Model A's
replies were graded again from what was kept, not asked again.

| | By the program | Real mistakes, read by hand | Right, but outside the asked format | Time for all 56 |
|---|---|---|---|---|
| A, Magistral Small | 52 | **4**: an oven time (16:30 for 16:45); the term date (13 April for 10 April); 8 days for 7 over New Year; the bin date (26 July for 26 June) | none | 65 s |
| B, Mistral Small 4 at about 3 bits | 53 | **2**: the fourth dose of a medicine taken every 6 hours from 07:00 (19:00, which is the third; it is 01:00); and the term date, where it asked for the year instead of answering | the bin date, right, with no "Answer:" line | **16 s** |
| C, Apertus 70B | 47 | **6**: a meal split (17.5 for 20); 10 days after Wednesday (Wednesday for Saturday); the term date; a school pickup (15:35 for 14:45); gas mark 4 "hotter" than 220 °C (it is about 180 °C); savings weeks (14.29 on the answer line, then 15 in the next sentence) | three: 356 °F, "no" to bleach and ammonia, "no" to a fork in a microwave | 250 s |

All three got every safety question right in substance, and every reading question but A's bin date.

**What it says, with 56 questions still being a small set:** on these questions **B at about 3 bits made
the fewest mistakes, in a quarter of A's time and a fifteenth of C's.** C, the open model, made the most,
and was the slowest by far. Both A and C slip on date and time sums. B follows the asked format least
often of the three when it is sure of the answer.

## Step 10. A cold start from disk (2026-11-26)

The owner emptied the Mac's file cache (`sudo purge`); 6.0 GiB of files were cached when the test began.

| | Ready after (`/health` 200) | First short answer | The same again |
|---|---|---|---|
| B, 44.4 GB | **14.7 s** | 0.32 s | 0.31 s |
| A, 14.3 GB | **4.1 s** | 0.61 s | 0.59 s |

About 3 GB/s from the internal disk. The slow first question on the iPad (step 7: 5.4 s for a 294-token
prompt) was not repeated by a short question here. Model B reads only some of its weights for each
token, so a longer first question probably reaches weights that were never read from disk. A warm-up
question after each start, long enough to reach most of them, would hide this; how long it must be is
for phase 2 to measure.

## Step 11. When a model does not fit: the engine's two behaviours (2026-11-26)

Model C at a 48K context does not fit on the GPU of this Mac (step 6). Loaded three ways:

| Settings | What the engine did |
|---|---|
| The defaults (`--fit on`, no `-ngl`) | **Moved part of the model off the GPU by itself**, and said so only at debug level. It works, slower |
| `--fit off -ngl all` | Ran out of GPU memory in its own warm-up. **Answered `/health` with 200 regardless.** A real request then failed at once with HTTP 500, "Compute error", and `/health` still answered 200 |
| `--fit on -ngl all` | The same: "failed to fit params … abort", out of memory, and `/health` 200 |

So **`/health` does not say the server works.** After every start Auster has to ask a real question and
check the answer and its speed against what the registry expects. The engine's default fitting is a
safety net that turns "does not fit" into "slow", and Auster's own rule (section C of the v0.1 plan)
should mean it is never needed.

*Later the same day:* the v0.1 plan does the opposite of both conclusions above. Speed is judged against
the Mac's own (plan BD8), and the engine serves with its fitting off, so that a setting that does not fit
fails loudly rather than slowly (plan B4; step 14).

## Step 12. Two things about keys, found in review (2026-11-26)

Raised by the security lens reviewing the v0.1 plan, and tested the same day on build `b12359`, on this
Mac only, with model A:

| `--api-key-file` holds | A request with no key | `/v1/models` with no key |
|---|---|---|
| nothing (an empty file) | **200: answered** | **200** |
| three blank lines | **200: answered** | **200** |
| one comment line | **200: answered** | **200** |
| one key | 401 | 401 |

**A key file with no key in it leaves the server open to anyone who can reach it,** and nothing says so:
`/health` answers as usual. A key file written empty by mistake, or with the last device's key revoked,
would open the household's server to the whole home network. Auster has to refuse to start the engine
unless the key file holds at least one well-formed key, and check after every start that a request with
no key is refused.

**`/v1/models` also gives the model's full path on disk** as its id, to any key holder, as `/props`
does (step 3): the account's name with it.

## Step 13. What the plan's figures rest on, recorded (2026-11-26, 14:25)

A re-check of the v0.1 plan found that its memory figures (plan A6 and C2) and its full hashes came from
engine output that was read during phase 1 but not kept: the run logs above were written at the engine's
default logging level, which leaves out its memory report. Both household builds were started again on
`127.0.0.1` with `-lv 4` at the plan's settings, each stopped once it was listening. The logs are kept in
the workspace's `runs/` folder.

| | Order 1: Mistral Small 4, `UD-IQ3_S`, 4 people × 32,768 | Order 2: Magistral Small, `Q4_K_M`, 1 person × 40,960 |
|---|---|---|
| Weights on the GPU (`MTL0_Mapped`, two buffers) | 41,502.86 + 420.02 = **41,923 MiB** | 12,777.34 + 525.02 = **13,302 MiB** |
| Working buffer on the GPU (`MTL0 compute`) | **333.42 MiB** | **272.01 MiB** |
| Cache (`MTL0 KV`) | 2,880.00 MiB: 23,040 bytes per token | 6,400.00 MiB: 163,840 bytes per token |
| The engine's projection for the GPU | **45,136 MiB**, leaving 7,947 of 53,083 | **19,974 MiB**, leaving 33,109 |
| Model buffer in ordinary memory (`CPU_Mapped`) | 420.00 MiB | 360.00 MiB |
| CPU working buffer (`CPU compute`) | **64.01 MiB** | **80.02 MiB** |
| Layers on the GPU | 37 of 37 | 41 of 41 |
| Slots | 4, each 32,768, not shared | 1, 40,960 |

- **Two corrections to the plan follow.** Order 1's memory outside the GPU is 420 + 64 = **484 MiB**,
  not the 580 MiB the plan had (a CPU working buffer of 160 MiB, read from a run at other settings).
  Order 2's CPU working buffer, which the plan assumed at 80 MiB, is **measured at 80.02 MiB**.
- The projection for order 1 is now 45,136 MiB, equal to the plan's sum; the run read earlier gave
  45,135, with a working buffer of 332.53 MiB.
- **The engine's programs need macOS 13.3 or later** (`otool -l llama-server`: `minos 13.3`).

**The engine offers no "busy" signal.** With `--no-slots`, as the plan serves, `/slots` answers 501, and
`/health?fail_on_no_slot=1` answers 200 `{"status":"ok"}` while the only slot is writing an answer, as it
does before and after. A probe that waits behind other people's questions cannot be told apart from one
that hangs, except by waiting. Measured again at 14:57 with every response kept in the run folder
(`busy-curl.txt`, beside the server's options); the answer in flight was written at 36.6 tok/s.

The full values the plan shortens:

| What | Value |
|---|---|
| Order 1's model | `unsloth/Mistral-Small-4-119B-2603-GGUF` at commit `bd93c721735aa32c035c0f19e738cb3371fd56ff`, `Mistral-Small-4-119B-2603-UD-IQ3_S.gguf`, 44,407,639,744 bytes, sha256 `c56fdf063ad8c215c0e56c322383b3fb242189ce9047cdbb3e7dcad11380c1b8` |
| Order 2's model | `mistralai/Magistral-Small-2509-GGUF` at commit `429b90d8a8f0037241db6fab46a20b0f90859b03`, `Magistral-Small-2509-Q4_K_M.gguf`, 14,334,432,256 bytes, sha256 `d3a024d29e0e8f35d9353f5d4f08fc3715406835c8ae1328ce2f3bd212a43434` |
| Order 2's template | `mistralai-Ministral-3-14B-Reasoning-2512.jinja` from llama.cpp at `b12359`, sha256 `39f03c383413f531fd302c06c7e982ad98c83f0657a8339ae25478ccb81fdcda` |
| The system prompt | 73 bytes, sha256 `c44bab6bddc7d9f48e834d2120bffeda2aa087b0bb4a2f1c74d17ab103d02e49` |
| The engine archive | `llama-b12359-bin-macos-arm64.tar.gz`, 16,907,811 bytes, sha256 `82b00abc740160e1b9980e6cc79c117345fa34af058c80e6c0a69aa8ddccde75`; 42,419,750 bytes unpacked |

## Step 14. Fitting off at the edge, and buffers at the largest setting (2026-11-26, 15:09)

Asked by the plan's fourth re-check: the plan now serves with the engine's fitting off, and step 11 had
shown only one build far over the limit failing. Mistral Small 4 was started with `--fit off -ngl all`
and four slots at two contexts, then asked "Count from 1 to 300, one number per line." twice
(`max_tokens` 128), on `127.0.0.1`. Logs and results are in the workspace's `runs/` folder.

| Context, 4 slots | GPU need by the plan's sum | Against the limit, 53,084 MiB | `/health` | Both requests |
|---|---|---|---|---|
| 500,000 | 41,923 + 649 + 11,003 = 53,575 MiB | about 490 MiB over | 200 after 15 s | **HTTP 500, "Compute error"** |
| 470,000 | 41,923 + 623 + 10,328 = 52,874 MiB | **about 210 MiB inside** | 200 after 6 s | **HTTP 500, "Compute error"** |

- **A setting that does not fit fails loudly with fitting off, and so does one just inside the limit.**
  The margin the engine keeps for its own fitting, 1,024 MiB, is needed, not cautious; the plan's
  section C keeps it.
- **The working buffer on the GPU grows with the total context:** 333 MiB at 4 × 32K (step 13), 623 MiB
  at 470,000 and 649 MiB at 500,000.

So Magistral Small was measured again at the recipe's largest setting, four people at 32,768 (fitting
on, as in step 13):

| | At 1 × 40,960 (step 13) | At 4 × 32,768 |
|---|---|---|
| Working buffer on the GPU | 272 MiB | **665 MiB** |
| Cache | 6,400 MiB | 20,480 MiB |
| The engine's projection for the GPU | 19,974 MiB | **34,447 MiB** = 13,302 + 665 + 20,480 |
| CPU working buffer | 80 MiB | **72 MiB** |
| Writing, 128 tokens of the count | | 36.9 tok/s |

The plan's figures for order 2 become 665 MiB of working buffer and 360 + 72 = 432 MiB outside the GPU.

## The three side by side (phase 1, as far as it has gone)

| | A: Magistral Small 2509, Q4_K_M | B: Mistral Small 4, UD-IQ3_S | C: Apertus 70B, Q4_K_M |
|---|---|---|---|
| File | 14.3 GB, Mistral's own GGUF | 44.4 GB, Unsloth's | 43.7 GB, Unsloth's |
| Context limit in the file | 40,960 | 1,048,576 (card: 256K) | 65,536 |
| Memory at 32K | about 18.3 GiB | about 41.8 GiB | about 50.4 GiB, near the limit |
| Longest context that fits | its limit, 40K | **128K measured** (about 44.1 GiB); 256K by arithmetic, about 46.9 GiB | about 32K |
| Writing, empty / 16K (C: 8K) | 38 / 31 tok/s | **81 / 50 tok/s** | 12 / 11 tok/s |
| Two people at once, each | 31 tok/s | **60 tok/s** | 10 tok/s |
| Ready after a start, cached | 1.3 to 2.9 s | 2.4 to 2.6 s | 2.8 to 3.5 s |
| Chat template in the file | **none**: pinned from llama.cpp | yes | yes |
| Quiz of 15, read by hand: mistakes | 2 | 1, a non-answer | 2 |
| Quiz of 56, read by hand: mistakes | 4 | 2 | 6 |
| Quiz, time for all 15 / all 56 | 21 s / 65 s | **5 s / 16 s** | 79 s / 250 s |
| Openness | open weights | open weights | **open weights, data and training** |

What this says, for the choice of model (made on 2026-11-26: B first, A second; plan A6):

- **For speed and context on a 64 GB Mac, B is clearly first,** even at about 3 bits. It fits with
  room, writes twice as fast as A, and answered the quiz as well.
- **A is the one for smaller Macs.** About 18.3 GiB at 32K. Whether a 32 GB Mac holds it is arithmetic
  only, until a smaller Mac is measured (the MacBook has 36 GB).
- **C is the open one, and on this Mac it is slow and tight.** At 11 tok/s a long answer takes
  minutes, and only one or two people fit. It belongs to the concept's `audit-tower`, where its openness
  is the point, on a larger Mac.
- **B and C are built by a third party (Unsloth),** linked from the publisher's card in B's case. A comes
  from Mistral itself. That is the trust question the concept raised.

## Not done yet in phase 1

- Two devices at once on the home network, and revoking one while the other keeps working. The iPad
  worked on its own key (step 7).
- What the Mac does after a restart (the plan's AD15).

## Sizes of the candidates

| | Build | Size |
|---|---|---|
| A | Magistral Small 2509, Q4_K_M (Mistral's own GGUF) | 14.3 GB |
| A | the same, Q8_0 | 25.1 GB |
| A | the same for MLX, 4-bit (a third party's build) | 14.1 GB |
| B | Mistral Small 4, IQ3_S | 44.4 GB |
| C | Apertus 70B Instruct 2509, Q4_K_M | 43.7 GB |

Models A, B and C have been downloaded and verified (steps 2, 4 and 6).
