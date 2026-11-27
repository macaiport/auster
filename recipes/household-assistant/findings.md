# household-assistant: findings

Measured on the development Mac (M5 Max, 64 GB, macOS 27.2.1) with llama.cpp `b12359`, on `127.0.0.1`
unless a log says otherwise. The logs are [`docs/phase-1.md`](../../docs/phase-1.md) and
[`docs/phase-2.md`](../../docs/phase-2.md); each line below points to its section.

## The chat templates: where they come from

Every build pins its template as a file in `assets/`, so that the Jinja the engine runs on every request
has been read (plan A4).

**Order 1, `assets/unsloth-Mistral-Small-4-119B-2603-dates-fixed.jinja`** (9,732 bytes, sha256
`f29aa0803a2d0346a20a384690cf1eb8eef71cdffd90b178751592bfa3e291f4`): the model file's own template with
its date block (lines 2 to 143) replaced by Auster's (lines 2 to 38), and every other byte as it was
(T56 checks this). The original is kept as `tests/fixtures/templates/unsloth-Mistral-Small-4-119B-2603.jinja`
(14,121 bytes, sha256 `d579fedfe0a78b11376089da957bbd4299ffb3f95cf827ab00c9cdc77298f954`): the `tokenizer.chat_template` that
`Mistral-Small-4-119B-2603-UD-IQ3_S.gguf` carries, from `unsloth/Mistral-Small-4-119B-2603-GGUF` at
commit `bd93c721735aa32c035c0f19e738cb3371fd56ff`, taken out byte for byte on 2026-11-26 by
`scripts/phase-2/gguf-template.py`, which reads only the file's metadata. Its own comments mark
Unsloth's changes ("Unsloth template fixes", "Edits made by Unsloth"), and it comes with the model
under Apache-2.0. Credit: Unsloth, and Mistral AI, whose model it is made for.

**Order 2, `assets/mistralai-Ministral-3-14B-Reasoning-2512.jinja`** (6,206 bytes, sha256
`39f03c383413f531fd302c06c7e982ad98c83f0657a8339ae25478ccb81fdcda`, git blob
`beb4d612c75af9d10bb0865b20422c8778fa7ea4`). Copied from the llama.cpp repository at tag `b12359`
(commit `b1b770d90`, as the engine reports itself), and checked against GitHub's hash. Magistral's model
file carries no template, and Mistral publishes none for it. Credit: the llama.cpp authors, MIT
licence. ([phase 1, step 3](../../docs/phase-1.md))

## What the templates do

- **Order 2's** renders the same text as llama.cpp's built-in `mistral-v7-tekken` when a system prompt is
  given; with none, it inserts Magistral's own reasoning prompt. The recipe always sends its own, and the
  chat page gets it from the server. ([phase 1, step 3](../../docs/phase-1.md))
- **Order 1's** inserts its own default system prompt when none is given, and asks for no reasoning
  (`reasoning_effort` "none") unless a request says "high".
- **The model file's own order-1 template fails on two days of some years, so Auster's replaces its date
  block** (plan BD20). The original reads the Mac's date to work out yesterday's for its default system
  prompt, and its arithmetic knows only some years: on **1 March of a year other than 2024, 2028 or
  2032**, and on **1 January of a year after 2032**, it raises an error. Through the engine (b12359) the
  engine then **does not start at all**: its start-up check of the template fails
  (`common_chat_verify_template: failed to apply template`). Measured at 2026-11-26 and 2028-03-01 (it
  starts) and 2027-03-01 and 2033-01-01 (it does not). Auster's block uses the leap-year rule and the year
  before, and raises nothing: through the engine it gave the right today and yesterday at 21 dates,
  including 2027-03-01, 2028-03-01, 2000-03-01, 2100-03-01, 2033-01-01 and the first of every month, and
  its rendering on 2026-11-26 was byte for byte the original's, with and without a system prompt
  ([phase 2, section 11](../../docs/phase-2.md)).

## Memory, at the recipe's largest setting (four people at 32,768 each)

From the engine's own report, `-lv 4` ([phase 1, steps 13 and 14](../../docs/phase-1.md)):

| | Order 1 | Order 2 |
|---|---|---|
| Weights on the GPU | 41,923 MiB | 13,302 MiB |
| Working buffers on the GPU | 333 MiB | 665 MiB |
| Cache per token | 23,040 bytes | 163,840 bytes |
| Outside the GPU | 420 + 64 = 484 MiB | 360 + 72 = 432 MiB |
| On the GPU in all | 45,136 MiB | 34,447 MiB |

- The working buffers grow with the total context, so these are the largest the recipe uses.
- The file's own context limit: 1,048,576 tokens for order 1, **40,960 for order 2** (Mistral's card says
  128K). ([phase 1, steps 2 and 4](../../docs/phase-1.md))
- **With the engine's fitting off, a setting that does not fit fails loudly**, HTTP 500 after a `/health`
  of 200, and so did one about 210 MiB inside the GPU limit: the 1,024 MiB margin is needed.
  ([phase 1, steps 11 and 14](../../docs/phase-1.md))
- **An engine cannot see another engine's memory.** Two side by side over the limit broke both, the one
  already serving until it was restarted. ([phase 2, section 6](../../docs/phase-2.md))

## Answers and speed

- **The recipe's test** (`assets/household-test.json`): both builds 12 of 12, twice, at temperature 0.
  With four slots, temperature 0 is not repeatable byte for byte, so the test grades answers.
  ([phase 2, section 1](../../docs/phase-2.md))
- **The speed question**, at four people × 32K: order 1 79.5 to 80.1 tok/s, order 2 35.1 to 36.8 tok/s,
  each within 5 % over three runs. ([phase 2, section 4](../../docs/phase-2.md))
- **Order 1's temperature is 0:** 53 of phase 1's 56 household questions, against 51 to 53 at 0.3 and 50
  to 51 at 0.7. Its effect on long conversations is not measured. Order 2 uses Mistral's advice, 0.7 and
  top-p 0.95. ([phase 2, section 3](../../docs/phase-2.md))
- **Tool calls:** both builds return a well-formed call through the engine with these templates; the
  test asks none in v0.1. ([phase 2, section 2](../../docs/phase-2.md))
- **The chat page sends no sampling values of its own,** so the engine's `--temp` and `--top-p` reach the
  household's chats. ([phase 2, section 5](../../docs/phase-2.md))
- Phase 1's quizzes, read by hand: order 1 made 2 mistakes in 56, order 2 made 4.
  ([phase 1, step 9](../../docs/phase-1.md))

## The engine

- `b12359`'s programs need macOS 13.3 or later. ([phase 1, step 13](../../docs/phase-1.md))
- **A key file with no key in it leaves the server open,** and `/health` says nothing; revoking a key
  needs a restart. ([phase 1, steps 3 and 12](../../docs/phase-1.md))
- The slot monitor tells one key holder when another is busy, so the recipe runs with `--no-slots`;
  cross-site requests are allowed from anywhere by default, so it sets `--cors-origins`.
  ([phase 1, step 3](../../docs/phase-1.md))
