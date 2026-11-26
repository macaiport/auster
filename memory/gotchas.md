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

## Testing

### A bare `wait` in a script that started a server waits for ever (2026-11-26)
- **Symptom:** `measure-server.sh` hung after two background requests had finished.
- **Root cause:** the script starts `llama-server` with `&`, so a bare `wait` also waits for the server,
  which never exits.
- **Prevention:** always `wait "$PID1" "$PID2"` with the exact process numbers. The script says so
  where it waits.

## Deployment
