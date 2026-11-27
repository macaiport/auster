#!/bin/bash
# template-dates.sh SERVER MODEL TEMPLATE DATE...
#
# Renders a chat template through llama-server's own Jinja, as the engine would on each of the given
# dates (YYYY-MM-DD), for plan BD20. The template's three calls strftime_now("%d"), ("%m") and ("%Y")
# are replaced by that date's day, month and year in a copy; the engine is started with the copy,
# asked for /apply-template on one user message and no system message, so that the template's default
# system message, which holds the dates, is rendered; then stopped. One line a date:
#   DATE ok TODAY YESTERDAY      the two dates the default message holds
#   DATE failed WHY              the engine did not start, or did not render
# SERVER is llama-server, MODEL any model file it can load (the model is not used to answer). The engine
# listens on 127.0.0.1 only, on the port in TEMPLATE_DATES_PORT (default 28484). Measured by hand on the
# development Mac; never part of tests/run.sh, which has no engine.
set -u
server=$1 model=$2 template=$3
shift 3
port=${TEMPLATE_DATES_PORT:-28484}
work=$(mktemp -d "${TMPDIR:-/tmp}/template-dates.XXXXXX")
trap 'kill "$pid" 2>/dev/null; rm -rf "$work"' EXIT
pid=

for date in "$@"; do
  y=${date%%-*} rest=${date#*-}; m=${rest%%-*} d=${rest#*-}
  sed -e "s/strftime_now(\"%d\")/'$d'/g" -e "s/strftime_now(\"%m\")/'$m'/g" -e "s/strftime_now(\"%Y\")/'$y'/g" \
    "$template" > "$work/t.jinja"
  "$server" -m "$model" --chat-template-file "$work/t.jinja" --host 127.0.0.1 --port "$port" \
    -c 2048 -ngl 0 --no-warmup > "$work/log" 2>&1 &
  pid=$!
  up=0
  for _ in $(seq 1 120); do
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    if [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/health")" = 200 ]; then up=1; break; fi
    sleep 0.5
  done
  if [ "$up" != 1 ]; then
    why=$(grep -m1 -iE 'error|exception|failed' "$work/log" | cut -c1-160)
    echo "$date failed the engine did not start: ${why:-no message}"
  else
    code=$(curl -s -o "$work/out" -w '%{http_code}' -H 'Content-Type: application/json' \
      -d '{"messages":[{"role":"user","content":"Hi"}]}' "http://127.0.0.1:$port/apply-template")
    today=$(grep -o 'The current date is [0-9-]*' "$work/out" | head -1 | sed 's/.* //')
    yday=$(grep -o 'yesterday\\" is [0-9-]*' "$work/out" | head -1 | sed 's/.* //')
    if [ "$code" = 200 ] && [ -n "$today" ] && [ -n "$yday" ]; then
      echo "$date ok $today $yday"
    else
      echo "$date failed HTTP $code: $(head -c 160 "$work/out")"
    fi
  fi
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; pid=
done
