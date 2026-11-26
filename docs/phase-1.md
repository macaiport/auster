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
| 7 | Staying up | The Mac does not sleep when idle. Restart after a power cut is off. FileVault is on. SSH answers | Fine for phase 1's measurements. The restart question is the plan's AD15 |

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

### What the recipe needs, from steps 1 to 3

- **The engine:** build `b12359`, fetched and checked by sha256, with `--offline`, `--no-slots`,
  `--cors-origins` set to its own address, `--api-key-file`, and the Jinja engine on.
- **The model file, and beside it a template file and a system prompt**, each pinned by sha256. The
  registry line of the v0.1 plan already has a template hash. The system prompt needs one too.
- **A way to set the chat page's system prompt.** The server takes default page settings from
  `--ui-config-file`. Whether that can set a system prompt is not yet tried.
- **Revoking a key restarts the engine.** About 1.3 s with the model in memory. Phase 6's front door
  could avoid it.
- **Hashing uses `openssl`,** four to five times faster than `shasum` here.

## Not done yet in phase 1

- The one MLX measurement, of model A.
- Models B (Mistral Small 4 at about 3 bits, 44.4 GB) and C (Apertus 70B at 4 bits, 43.7 GB).
- Two devices on the home network, and an iPad. The server has so far listened on this Mac only.
- A cold start from disk, and what the Mac does after a restart (the plan's AD15).
- Whether `--ui-config-file` can set the chat page's system prompt.

## Sizes of the candidates

| | Build | Size |
|---|---|---|
| A | Magistral Small 2509, Q4_K_M (Mistral's own GGUF) | 14.3 GB |
| A | the same, Q8_0 | 25.1 GB |
| A | the same for MLX, 4-bit (a third party's build) | 14.1 GB |
| B | Mistral Small 4, IQ3_S | 44.4 GB |
| C | Apertus 70B Instruct 2509, Q4_K_M | 43.7 GB |

Model A at Q4_K_M has been downloaded (step 2). Nothing else has.
