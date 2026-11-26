#!/bin/bash
# Phase 1 of Auster, by hand (docs/phase-1.md). Starts llama-server on one model at one context size,
# on the loopback address only, with a key file, and measures what the v0.1 plan needs: time to load,
# memory, time to a first answer, prompt and generation speed, two people at once. Then it tests the
# keys, the slot monitor and cross-site requests, and what it takes to revoke a key.
#
#   scripts/phase-1/measure-server.sh <model.gguf> <context> <slots> <label> [prompt sizes...]
#
# Extra server options go in SERVER_ARGS, such as a chat template. The server runs with --offline. Keys are made on first use in the workspace's keys/ folder, are
# passed to curl from files, and are never printed. A run folder keeps the server log and the answers.
set -u
W="${AUSTER_P1:-$HOME/Library/Developer/Auster/phase-1}"
BIN="$W/engine/llama-b12359"
[ $# -ge 4 ] || { echo "usage: $0 <model.gguf> <context> <slots> <label> [prompt sizes...]" >&2; exit 2; }
MODEL=$1; CTX=$2; NP=$3; LABEL=$4; shift 4
SIZES="${*:-1024 8192}"
PORT=18931
URL="http://127.0.0.1:$PORT"
RUN="$W/runs/$(date +%Y%m%d-%H%M%S)-$LABEL"
K="$W/keys"
PY=/usr/bin/python3
mkdir -p "$RUN"
[ -f "$MODEL" ] || { echo "no such model: $MODEL" >&2; exit 2; }
if lsof -tiTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; then echo "port $PORT is in use" >&2; exit 2; fi

umask 077
for n in a b; do
  [ -s "$K/$n" ] || openssl rand -hex 24 > "$K/$n"
  printf 'Authorization: Bearer %s\n' "$(cat "$K/$n")" > "$K/h$n"
done
printf 'Authorization: Bearer %s\n' "not-a-key-$(openssl rand -hex 8)" > "$K/hwrong"
cat "$K/a" "$K/b" > "$K/keys.txt"
umask 022

now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }
say() { echo "$*" | tee -a "$RUN/summary.txt"; }
json() { $PY -c "import json,sys; d=json.load(open(sys.argv[1])); print($2)" "$1" 2>/dev/null || echo "?"; }

PID=""
stop() { [ -n "$PID" ] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null; PID=""; }
trap stop EXIT

start() {  # $1: log name. Sets PID and LOAD (seconds from start to /health answering 200)
  local t0 t1 i=0 code
  t0=$(now)
  "$BIN/llama-server" -m "$MODEL" -c "$CTX" -np "$NP" --host 127.0.0.1 --port "$PORT" \
    --api-key-file "$K/keys.txt" --offline --cors-origins "$URL" ${SERVER_ARGS:-} > "$RUN/$1.log" 2>&1 &
  PID=$!
  while :; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$URL/health")
    [ "$code" = 200 ] && break
    kill -0 "$PID" 2>/dev/null || { say "server exited while loading; see $RUN/$1.log"; tail -15 "$RUN/$1.log"; exit 1; }
    i=$((i + 1)); [ $i -lt 3000 ] || { say "server not ready after 600 s"; exit 1; }
    sleep 0.2
  done
  t1=$(now)
  LOAD=$(echo "$t1 - $t0" | bc)
}

post() {  # $1 header file, $2 path, $3 body file, $4 output file; prints the HTTP code
  curl -s -o "$4" -w '%{http_code}' --max-time 900 -H @"$1" -H 'Content-Type: application/json' \
    -d @"$3" "$URL$2"
}

say "== $LABEL: $(basename "$MODEL"), context $CTX, slots $NP, options [${SERVER_ARGS:-none}], $(date '+%F %T')"
say "conditions: CPU idle $(top -l 2 -n 0 | grep 'CPU usage' | tail -1 | sed -E 's/.* ([0-9.]+)% idle.*/\1/')%, GPU $(ioreg -r -d 1 -w 0 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)% busy, game or model processes $(pgrep -f 'wineserver|wine64|steam_osx|llama-server' | wc -l | tr -d ' ')"

start server
say "load: ${LOAD} s to /health 200"
RSS=$(ps -o rss= -p "$PID" | tr -d ' ')
footprint -p "$PID" > "$RUN/footprint.txt" 2>&1
say "memory: resident $(echo "scale=1; $RSS / 1048576" | bc) GiB; footprint: $(grep -i -m1 -E 'phys_footprint|Footprint' "$RUN/footprint.txt" | sed -E 's/^ +//' | cut -c1-80)"
grep -E 'model buffer size|KV buffer size|compute buffer size|n_ctx_seq|n_ctx +=|n_slots' "$RUN/server.log" | sed -E 's/^.*(llama_|srv|load_tensors|init).{0,20}: +//' | sort -u | head -12 | sed 's/^/  /' | tee -a "$RUN/summary.txt"

# A first answer, as a person would ask it, right after the load
say "first answer: $($PY "$(dirname "$0")/chat.py" "$URL/v1/chat/completions" "$K/a" - "Say hello in five words." | head -1)"

# Prompt and generation speed at each prompt size (no prompt cache, fixed length of answer)
for n in $SIZES; do
  $PY - "$n" > "$RUN/p$n.json" <<'EOF'
import json, sys
n = int(sys.argv[1])
words = ("The household keeps its notes in one place so that anyone can find the list for the week, "
         "the times of the school run, the numbers for the plumber and the plan for the garden. ").split()
text = " ".join(f"{words[i % len(words)]}{'' if i % 37 else ' (' + str(i) + ')'}" for i in range(int(n * 0.8)))
print(json.dumps({"prompt": text + "\n\nSummarise the notes above in one sentence.", "n_predict": 128,
                  "cache_prompt": False, "temperature": 0, "ignore_eos": True}))
EOF
  code=$(post "$K/ha" /completion "$RUN/p$n.json" "$RUN/p$n.out")
  say "prompt ~$n: code $code, $(json "$RUN/p$n.out" "'%d tokens read at %.0f tok/s; %d written at %.1f tok/s' % (d['timings']['prompt_n'], d['timings']['prompt_per_second'], d['timings']['predicted_n'], d['timings']['predicted_per_second'])")"
done

# Two people at once
if [ "$NP" -ge 2 ]; then
  M="marker-$(openssl rand -hex 6)"
  for n in a b; do
    printf '{"prompt":"Write a short story about a lighthouse keeper (%s %s).","n_predict":256,"cache_prompt":false,"ignore_eos":true}' "$n" "$M" > "$RUN/two-$n.json"
  done
  t0=$(now)
  post "$K/ha" /completion "$RUN/two-a.json" "$RUN/two-a.out" > "$RUN/two-a.code" & PA=$!
  post "$K/hb" /completion "$RUN/two-b.json" "$RUN/two-b.out" > "$RUN/two-b.code" & PB=$!
  wait "$PA" "$PB"   # never a bare wait: the server is a background job of this script too
  t1=$(now)
  say "two at once: a $(json "$RUN/two-a.out" "'%.1f tok/s' % d['timings']['predicted_per_second']"), b $(json "$RUN/two-b.out" "'%.1f tok/s' % d['timings']['predicted_per_second']"), both done in $(echo "$t1 - $t0" | bc) s"
  # Can one person's key read the other's conversation through the slot monitor?
  code=$(curl -s -o "$RUN/slots.out" -w '%{http_code}' -H @"$K/ha" "$URL/slots")
  say "slot monitor with key a: code $code; key b's words visible: $(grep -c "$M" "$RUN/slots.out" 2>/dev/null)"
  code=$(curl -s -o /dev/null -w '%{http_code}' "$URL/slots")
  say "slot monitor with no key: code $code"
fi

# The keys
printf '{"prompt":"Hi","n_predict":1}' > "$RUN/tiny.json"
say "keys: none $(curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -d @"$RUN/tiny.json" "$URL/completion"), wrong $(post "$K/hwrong" /completion "$RUN/tiny.json" /dev/null), a $(post "$K/ha" /completion "$RUN/tiny.json" /dev/null), b $(post "$K/hb" /completion "$RUN/tiny.json" /dev/null)"
say "no key: /health $(curl -s -o /dev/null -w '%{http_code}' "$URL/health"), chat page / $(curl -s -o /dev/null -w '%{http_code}' "$URL/"), /props $(curl -s -o /dev/null -w '%{http_code}' "$URL/props"), /v1/models $(curl -s -o /dev/null -w '%{http_code}' "$URL/v1/models")"
say "cross-site: a page at another origin is allowed: $(curl -s -D - -o /dev/null -X OPTIONS -H 'Origin: http://elsewhere.example' -H 'Access-Control-Request-Method: POST' "$URL/completion" | grep -i -c 'access-control-allow-origin: http://elsewhere.example')"

# Revoking a key: does the running server notice, and what does a restart cost?
cat "$K/a" > "$K/keys.txt"
say "revoke b in the file: b while running $(post "$K/hb" /completion "$RUN/tiny.json" /dev/null)"
stop
start restart
say "restart: ${LOAD} s to /health 200; then b $(post "$K/hb" /completion "$RUN/tiny.json" /dev/null), a $(post "$K/ha" /completion "$RUN/tiny.json" /dev/null)"
cat "$K/a" "$K/b" > "$K/keys.txt"
stop
say "run folder: $RUN"
