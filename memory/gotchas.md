# macaiport — Gotchas

Patterns, not tasks. On every bug fix, add an entry under the matching heading:

```
### <short title> (YYYY-MM-DD)
- **Symptom:** what you saw
- **Root cause:** the assumption that was false
- **Prevention:** the check, test or rule that stops it recurring
```

## Build & tooling

### `--chat-template <name>` is taken as template text when Jinja is on (2026-11-26)
- **Symptom:** with `--chat-template mistral-v7-tekken`, the model wrote about "Mistral V7 Tekken":
  it had been given the name itself as its prompt.
- **Root cause:** llama-server's Jinja engine is on by default, and then `--chat-template` takes the
  text of a template, not the name of a built-in one. The help says so in passing.
- **Prevention:** use `--chat-template-file` with a pinned file, or `--no-jinja` before a built-in
  name. Then check what the model is given with `/apply-template`, not by reading answers.

## Environment & config

## Data

### A memory figure measured at one setting was used at a larger one (2026-11-26)
- **Symptom:** the v0.1 plan carried Magistral Small's GPU working buffer as 272 MiB; at the recipe's
  largest setting (four people at 32K) the engine reports 665 MiB. Order 1's CPU buffer was carried as
  160 MiB from a run at other settings; at the household's setting it is 64.
- **Root cause:** the engine's working buffers grow with the total context, and the figures were read
  from whatever run was at hand, at the engine's default log level, which hides its memory report.
- **Prevention:** take every memory figure from a `-lv 4` run at the largest setting the recipe allows,
  keep the log, and cite the run (`docs/phase-1.md`, steps 13 and 14).

## Testing

### A grader that checks only the start of an answer passes the wrong ones (2026-11-26)
- **Symptom:** carrying `quiz.py` over to JavaScript "exactly" carried over its `yesno` rule,
  `a.startswith(want)`: "Not sure" and "Nope" passed a mandatory safety question whose answer is "no".
- **Root cause:** a prefix check stands in for a word check. Phase 1's saved answers never exercised it,
  so a grader that agreed with `quiz.py` on all 112 of them still had it.
- **Prevention:** a grading rule gets constructed cases for its near misses, not only for its hits
  (`tests/fixtures/recipe-test/grader-cases.json`), and a mutant that restores the loose rule (T59c).

### A bare `wait` in a script that started a server waits for ever (2026-11-26)
- **Symptom:** `measure-server.sh` hung after two background requests had finished.
- **Root cause:** the script starts `llama-server` with `&`, so a bare `wait` also waits for the server,
  which never exits.
- **Prevention:** always `wait "$PID1" "$PID2"` with the exact process numbers. The script says so
  where it waits.

## Deployment
