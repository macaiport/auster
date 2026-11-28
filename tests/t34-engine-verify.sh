# T34 (U6; AD13, B4 step 4, B6): at every start the engine and the template are hashed, and a changed one stops the start
# with a sentence in `auster status`; the model is not hashed at start; `auster verify` catches a changed model. On an
# untouched install `auster verify` finds each of the six things serving names the same and exits 0. A first start says
# starting; with the template then changed in store/, the next start says engine-hash and starts nothing, `auster status`
# says in a sentence that the engine was not started because a file it checks has changed, and names `auster verify`,
# which names the template and exits 1. An engine file changed at the same size stops the next start the same way, and
# `auster verify` names the engine's unpacked files (T97 holds every other kind of change to them). The model changed at
# the same size: the engine still starts, and `auster verify` names the model, and nothing else, and exits 1.
# Mutants: tests/mutants/T34a (skip the engine's hash), T34b (hash the model at start), T34c (skip the template's hash),
# T34d (`auster verify` by size alone), T34e (`auster status` says only the code).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
job_install
T=$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f5)   # the template
R="$ED/root/llama-stub"
STATUS_SAYS="So it did not start the engine: a file it checks at every start (the engine's files, the template or the system prompt) has changed, or the record of what serves cannot be read. \`auster verify\` says which file."
same_lines() { grep -c '^  same ' "$W/out"; }
start_says() { # CODE LABEL -> the engine job, started now, wrote CODE into start; with engine-hash, it started no engine
  engine_job; engine_wait
  same "$EJ_CODE" "$1" "$2: the start says $1"
  [ "$1" = starting ] || same "$(starts)" "$NSTARTS" "$2: no engine started"
  engine_job_end
}
same_size_change() { # FILE WHAT -> its byte at the middle changed, at the same size
  local f=$1 n
  n=$(stat -f %z "$f")
  { head -c $((n / 2)) "$f"; printf 'X'; tail -c +$((n / 2 + 2)) "$f"; } > "$W/changed"
  same "$(stat -f %z "$W/changed")" "$n" "$2, changed at the same size"
  chmod 644 "$f"; cat "$W/changed" > "$f"
}

auster verify
same "$RC:$(same_lines)" "0:6" "auster verify on an untouched install: exit 0, all six the same"
outsays "Every file is the one the registry names." "  ...it says so"

# --- the template, at every start
start_says starting "a first start"
chmod 644 "$DATA/store/$T"; printf '{# one more line #}\n' >> "$DATA/store/$T"
start_says engine-hash "the template changed, the next start"
auster status
outsays "The engine job's last start: engine-hash." "  ...auster status gives the code"
outsays "$STATUS_SAYS" "  ...and says in a sentence that the engine was not started, naming auster verify"
auster verify
same "$RC" 1 "  ...auster verify: exit 1"
outsays "  CHANGED   the template (store/$T)" "  ...it names the template"
job_reset
start_says starting "the template put back, a start"

# --- an engine file
same_size_change "$R/libstub.0.dylib" "a library of the engine"
start_says engine-hash "a file of the engine changed at the same size"
auster verify
same "$RC" 1 "  ...auster verify: exit 1"
outsays "  CHANGED   the engine's unpacked files (engines/$ESHA)" "  ...it names the engine's unpacked files"
job_reset

# --- the model
same_size_change "$DATA/store/$SA" "the model"
start_says starting "the model changed at the same size (the model is not hashed at start)"
auster verify
same "$RC:$(same_lines)" "1:5" "  ...auster verify: exit 1, five the same"
outsays "  CHANGED   the model (store/$SA)" "  ...it names the model"
done_
