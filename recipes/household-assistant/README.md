# household-assistant

A chat assistant for a household. One Mac serves it on the home network with llama.cpp's
`llama-server`, and each device uses the engine's own chat page with a key of its own. The plan it is
built from is [`docs/plans/v0.1.md`](../../docs/plans/v0.1.md) (A6 and A7). It cannot be installed yet.

For Auster the recipe is the id `rmmsi4vdvxsr4` in [`registry.tsv`](../../registry.tsv). This folder is
for people; nothing on a Mac is found by its name.

## Builds, preferred first

| Order | Model | File | Engine |
|---|---|---|---|
| 1 | Mistral Small 4 119B (2603), Apache-2.0 | `Mistral-Small-4-119B-2603-UD-IQ3_S.gguf`, 44.4 GB, from `unsloth/Mistral-Small-4-119B-2603-GGUF` (the build Mistral's own card links to) | llama.cpp `b12359` |
| 2 | Magistral Small 2509, Apache-2.0 | `Magistral-Small-2509-Q4_K_M.gguf`, 14.3 GB, from `mistralai/Magistral-Small-2509-GGUF` (Mistral's own) | llama.cpp `b12359` |

Each file is fetched from its publisher and checked against the size and sha256 in `registry.tsv`.
Auster works out on each Mac which build fits and at what context (section C of the plan): on the
development Mac (M5 Max, 64 GB) that is order 1 for four people at 32,768 tokens each. A Mac with 36 GB
would get order 2 by the plan's arithmetic; that has not been measured.

## What the builds use from `assets/`

| File | What | Used by |
|---|---|---|
| `household-system.txt` | the system prompt, 73 bytes | both |
| `unsloth-Mistral-Small-4-119B-2603.jinja` | the chat template the model file carries, taken out | order 1 |
| `mistralai-Ministral-3-14B-Reasoning-2512.jinja` | a chat template from llama.cpp | order 2 |
| `household-test.json` | the recipe's test: twelve household questions and the speed question | both |

Where each template comes from, and what was measured, is in [findings.md](findings.md).
