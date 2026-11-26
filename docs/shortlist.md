# Phase 1 shortlist: engine and models for the household assistant

> **Researched 2026-11-26** for the Mac Studio (M5 Max, 64 GB). Sizes, licences and access rules were
> read from the Hugging Face API that day. **Nothing here has been run yet.** Speeds marked "estimate"
> are arithmetic from the Devstral trial's bandwidth measurement, not measurements. Criteria, in order:
> privacy and security, then the owner's interest in Mistral and Apertus, then fit on this Mac.

## The budget on this Mac

- **Memory:** 53,084 MiB (55.7 GB) is usable by the GPU (`llama-server --list-devices`).
- **Context is not free.** The one measured reference: a 24B model with a 14.3 GB file used 33.4 GB in
  all at a 128K context.
- **Disk:** 64.2 GB free of 2.0 TB on 2026-11-26 (96.8% used). The owner's planning assumption is at
  least 500 GB free once another project's tests and tidy-up finish, which holds all three candidates
  side by side (about 115 GB). Until then nothing large is downloaded.

## Engine

**Principle (owner, 2026-11-26): each platform gets the engine that is best on it.** The Mac does not
have to run what Windows and Linux will run later. "Best" is decided by measurement.

**Order on the Mac (agreed 2026-11-26):** v0.1 ships on llama.cpp alone. MLX is measured once in
phase 1 on model A, and its builds are added once Auster has its own front door for keys (phase 6),
or right after v0.1 if that measurement shows MLX is much better on model B.

| Engine | Licence | For | Against | Verdict |
|---|---|---|---|---|
| **llama.cpp** | MIT | Already installed (0.3.0; 1.0.0 is current in Homebrew). Keys from a file with one per line, TLS, parallel slots and an offline flag are all in the installed `llama-server --help`. The Devstral trial ran it with every network route denied except its own port. Mistral publishes its own GGUF files for models A and E. | Not the fastest on Apple Silicon by reputation; not measured here. | **The v0.1 engine.** The only one with access control built in |
| **MLX** (`mlx-lm`) | MIT | Apple's own framework, built for this hardware. Its server can store context at fewer bits (`--kv-bits`), which matters when memory is tight. Apertus's card names MLX for on-device use. | **Its server has no keys and no TLS**, and its own source says it "is not recommended for production" (read from `mlx_lm/server.py` on 2026-11-26). A household server on MLX needs a front door that Auster would have to write. It also brings a Python runtime and packages to pin. No MLX build comes from a model's publisher at these sizes. | **Later.** One measurement in phase 1 |
| Ollama | MIT | Simple to install, with a large community. Runs on this Mac alone with nothing exposed by default (it listens on `127.0.0.1`). | For a household server its design pulls the wrong way. **Its local API has no keys:** its own FAQ answers "expose on my network" with a bind address and a proxy in front. Model management (create, pull, push) is on that same open API, which is what made CVE-2026-7482 serious (NVD: rated 9.1, memory of other users' conversations readable; fixed in 0.17.1, long before today's 0.40). **Its Mac app downloads its own updates automatically**, against "nothing without a yes". Cloud models and web search are on until a setting turns them off. | No for v0.1. It would need a front door, its updater off and its cloud features off |
| LM Studio | Closed source | The concept's choice; polished. | The app cannot be audited, and secondhand sources disagree on whether its telemetry is on by default. | No as the base |

MLX builds that exist, for the same models (Hugging Face, 2026-11-26):

| Model | MLX build and size | Against the GGUF |
|---|---|---|
| A, Magistral Small 2509 | `lmstudio-community/Magistral-Small-2509-MLX-4bit` 14.1 GB; 8-bit 25.9 GB | Same sizes. The GGUF is Mistral's own; the MLX build is a third party's. |
| B, Mistral Small 4 | `mlx-community/Mistral-Small-4-119B-2603-OptiQ-2bit` 45.8 GB. The 4-bit build is 67.8 GB and does not fit. | 45.8 GB works out to about 3.1 bits per weight, the same as the 44.4 GB GGUF despite the "2bit" name. |
| C, Apertus 70B | `ssc-dsai/gc-llm-apertus-70b-instruct-2509-4bit-mlx` 39.7 GB, 113 downloads | The GGUF builds are far more widely used. |

**What "best" will be judged on,** proposed: speed (first answer and generation), memory at the working
context, answer quality on the same household questions, and what it takes to make it safe to leave
running (keys, TLS, nothing reaching out).

## Models

All are Apache 2.0 on Hugging Face. Sizes are the published files.

| | Model | Build and size | On this Mac | Why it is here |
|---|---|---|---|---|
| A | **Magistral Small 2509** (24B, Mistral; built on Mistral Small 3.2) | `mistralai/Magistral-Small-2509-GGUF`: Q4_K_M 14.3 GB, Q5_K_M 16.8 GB, Q8_0 25.1 GB | Fits with a wide margin, even at 8-bit. Estimate 30–36 tok/s at Q4, from the same-size Devstral file. | **Mistral publishes this GGUF itself**, the shortest chain from publisher to file. The safe everyday choice. |
| B | **Mistral Small 4** (119.4B, 128 experts with 4 active, 256K context, text and images) | `unsloth/Mistral-Small-4-119B-2603-GGUF`: IQ3_S 44.4 GB, IQ3_XXS 42.8 GB. 4-bit is 69.5–73.8 GB. | **Only below 4 bits.** IQ3_S leaves about 11 GB for context and the 3.4 GB image projector. Speed should be good, since few weights are read per token. | The concept's flagship. What 3 bits costs in answer quality is unknown and must be tested against A. At 4 bits it needs a 96–128 GB Mac. |
| C | **Apertus 70B Instruct 2509** (70.6B, Swiss AI Initiative, 65K context) | `unsloth/Apertus-70B-Instruct-2509-GGUF`: Q4_K_M 43.7 GB, IQ4_XS 38.0 GB | Fits at 4 bits with about 12 GB for context. Estimate about 12 tok/s, since every weight is read per token. | The auditable choice: weights, training data and recipes are all published, with EU AI Act documents. Not access-gated. |
| D | Apertus v1.5 70B (72.0B, July 2026, text and images) | Hobbyist builds only | Not now | **Access-gated:** a Hugging Face login, an acceptable-use policy, and sharing email, username, company and institutional email. An installer cannot fetch it for someone. |
| E | Ministral 3 14B (Mistral) | `mistralai/Ministral-3-14B-Instruct-2512-GGUF`: Q4_K_M 8.2 GB, Q8_0 14.4 GB | Fits easily | Also published as GGUF by Mistral. The candidate for the 36 GB MacBook and smaller Macs. |

## What the search showed about trust

- **Tampered builds sit beside the reputable ones.** A search for Mistral Small 4 returns
  "uncensored", "heretic" and "obliterated" builds, one with 19,024 downloads against 20,583 for the
  build Mistral links to. A recipe has to name the repository and the file's sha256; "find the model
  and fetch it" is not safe.
- **Publisher-made GGUF files exist for A and E only.** B and C come from a third-party quantizer
  (unsloth). Mistral's card for Small 4 links to that build, which is an endorsement of a kind.
- **Gating costs privacy.** Apertus v1.5 asks for contact details before download.
- **Apertus asks its users for upkeep.** Its card advises re-checking every six months for a filter
  that removes personal data from output; none is published yet. Auster's update channel could carry it.

## A nearby project: Osaurus (read 2026-11-26)

`osaurus-ai/osaurus` is a native Swift app for Apple Silicon under the MIT licence (8,211 stars; release
1.0.13 on 2026-11-25). From its README:

- It runs local models through MLX inside the app, on its own Swift stack (`osaurus-ai/vmlx-swift`, MIT).
  It serves OpenAI-, Anthropic- and Ollama-compatible APIs on `127.0.0.1:1337`, and can be exposed on
  the network behind an access key.
- It is an agent harness for one person: agents, memory, tools, channels such as Mail and Slack, and
  sync between that person's own devices.
- Cloud models are a first-class choice beside local ones, including its own paid router.
- It publishes its own quantized builds on Hugging Face. The local families it lists are Gemma, Qwen,
  GPT-OSS, Llama and LFM.
- Anonymous usage analytics and crash reports are on by default and can each be switched off. Builds
  from source have both off.

What that means here:

- **It already has the shape "fewest parts" points to:** the engine inside one native app. Before Auster
  builds a native app or adds MLX (phases 4 and 6), `vmlx-swift` and Osaurus are read as possible parts
  to build on, not only as neighbours.
- **It is not built for what Auster is for:** a server for a household with a key for each person, models
  from a short list pinned by checksum to their publishers, nothing sent anywhere by default, updates
  only on a yes, and choices worked out on each Mac.
- **For one person on one Mac, a local model is already a download.** The concept's "weekend of Terminal
  work" describes the household server, not that case.
- **Not checked:** whether Osaurus takes several per-person keys, how its updates are applied, and
  whether it runs Mistral Small 4 or Apertus.

### A closer look: what Auster could reuse (2026-11-26)

Read from `osaurus-ai/vmlx-swift` and Osaurus's own docs. Nothing was run.

- **`vmlx-swift` is a library, not a server.** MIT. It gathers the Swift MLX pieces: the tensor core, text
  and vision model runtimes, tokenizers, Jinja chat templates, reasoning and tool-call parsing, and
  several kinds of cache. The server, the keys and the app are in Osaurus itself.
- **It has model code for both families of interest:** `Mistral3Text`, `Mistral4VLM`, `Apertus` and
  `Apertus1p5`, the last with image and audio parts. Whether each runs well was not tried.
- **It is young and moving.** Created 2026-05-12, no tagged release, 86 open issues, and a README that
  describes a migration still under way. Anything built on it pins a commit.
- **Its models are in MLX's format.** It does not load GGUF, so Mistral's own GGUF files do not apply.
- **Osaurus updates through Sparkle,** and issues access keys that are scoped to an agent and can be
  revoked. Whether those keys map well onto the people in a household was not tried.

Ways to use it, from least to most:

1. **Measure with it.** Phase 1's one MLX measurement is better taken through this Swift stack than
   through Python's `mlx-lm`, since "fewest parts" rules Python out of anything Auster would ship.
2. **Borrow parts under MIT when their time comes:** chat-template handling, the signing and release
   scripts, the personal-data filter, and the distributed modules for a later `brain-cluster`.
3. **Build Auster's native app on `vmlx-swift`** (phases 4 and 6), writing only the household front door.
4. **Make Osaurus itself the engine of a recipe.** Against: analytics on by default in its releases, cloud
   models in the same app, its own updater, and its own model builds.

v0.1 stays on llama.cpp: it needs no server written, and it has model files made by the publisher.

## Proposed order of measurement

1. Model A on llama.cpp 1.0.0 with Mistral's GGUF: keys, a client, restart behaviour. Then the same
   model once on MLX with a 4-bit build, same questions and context size, to record the difference.
   Preferably through the Swift stack described above rather than Python's.
2. Model B on llama.cpp: is the flagship at about 3 bits better than the small model at 8 bits? Run it
   on MLX too only if step 1 showed a large gap.
3. Model C at 4 bits: is about 12 tok/s liveable, and what does the openness buy in practice?

## Sources

- Hugging Face API, 2026-11-26: `mistralai`, `swiss-ai`, `unsloth` and `mlx-community` model listings,
  model info and file trees.
- Model cards: `mistralai/Mistral-Small-4-119B-2603`, `swiss-ai/Apertus-70B-Instruct-2509`. The card
  for `swiss-ai/Apertus-v1.5-70B` cannot be read without logging in.
- Homebrew formula data for `llama.cpp`, `ollama`, `mlx-lm`; the llama.cpp v1.0.0 release (2026-11-13).
- `mlx_lm/server.py` on the `main` branch of `ml-explore/mlx-lm`, read 2026-11-26.
- Ollama: the NVD entry for CVE-2026-7482, and Ollama's own FAQ (`docs/faq.mdx` on its `main` branch),
  both read 2026-11-26. Press coverage: <https://thehackernews.com/2026/05/ollama-out-of-bounds-read-vulnerability.html>
- LM Studio: <https://lmstudio.ai/app-privacy>, <https://lmstudio.ai/app-terms>
- The Devstral trial: `runbooks/devstral.md` in the private `metal-working` repo.
- Osaurus: the README and `docs/IDENTITY.md` on the `main` branch of `osaurus-ai/osaurus`, the README and
  `Package.swift` of `osaurus-ai/vmlx-swift`, and GitHub's API and code search, read 2026-11-26;
  <https://techcrunch.com/2026/05/15/osaurus-brings-both-local-and-cloud-ai-models-to-your-mac/>
