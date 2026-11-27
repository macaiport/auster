# Sourced by the `auster` command's tests (V7: T72's revoke clause, T81 to T87, T106, T108, T113, T114) after
# lib.sh, helpers.sh, install-helpers.sh and job-helpers.sh. One first install (job_install) makes a real data
# root; bin/auster is then run as the household runs it, with the stubs first on PATH:
#   cmd_install [make_home option...]   job_install, then cmd_hook; the engine is left booted out
#   cmd_hook            the stub launchctl starts the real engine job's program, as launchd_hook does, but a
#                       kickstart -k or a bootout waits for the engine it stops to end, as launchd does
#   engine_up           the engine's job bootstrapped, as at a login, and the engine listening on 8484
#   auster ARG...       bin/auster ARG... with HOME=$H, the questions answered from ANSWERS (one a line), the
#                       QR code drawn on $W/screen; its output in $W/out and its exit code in RC
#   login               launchd at a login: each job file in ~/Library/LaunchAgents bootstrapped, unless its job
#                       is loaded; the stub refuses a label that is disabled, as launchd does
#   loaded LABEL        0 when the stub launchctl holds the job as loaded
#   override LABEL      enabled, disabled, or none: what launchd keeps for the label
#   key_of NAME / id_of NAME   the device NAME's key / id, from keys/
#   ask_engine KEY [HOST [PORT]]  the HTTP code the server gives the speed question asked with KEY (- for no key), at
#                       HOST (10.0.0.5) and PORT (8484)
#   qr_texts FILE       what each QR code drawn in FILE holds, one a line (tests/qr-read.js)
#   engine_alive        0 while an engine the engine job started is alive and listening on 8484
#   outsays TEXT LABEL  ok when the command's output holds TEXT
# AU_SERVER_CHECK_SECS (common/auster) is 15 here, so that a check that cannot pass ends in seconds; a test
# that expects one to fail sets it lower for that call.
export AU_SERVER_CHECK_SECS=15
EJOB=local.auster.engine CJOB=local.auster.check

cmd_install() {
  job_install "$@"
  cmd_hook
}

cmd_hook() {
  mkdir -p "$STUB_LAUNCHCTL_DIR/hooks" "$STUB_LAUNCHCTL_DIR/pids"
  cat > "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine" <<'EOF'
#!/bin/bash
S=$STUB_LAUNCHCTL_DIR L=local.auster.engine
stop() {
  local p i
  p=$(cat "$S/pids/$L" 2>/dev/null)
  if [ -n "$p" ]; then
    kill "$p" 2>/dev/null
    for i in $(seq 100); do kill -0 "$p" 2>/dev/null || break; /bin/sleep 0.05; done
  fi
  rm -f "$S/pids/$L"
}
start() {
  local plist prog log
  plist=$(cat "$S/loaded/$L")
  prog=$(/usr/bin/plutil -extract ProgramArguments.1 raw -o - "$plist")
  log=$(/usr/bin/plutil -extract StandardErrorPath raw -o - "$plist")
  /bin/bash "$prog" >> "$log" 2>&1 < /dev/null &
  echo $! > "$S/pids/$L"
}
case "$1" in bootstrap) start ;; kickstart) stop; start ;; bootout|disable) stop ;; esac
exit 0
EOF
  chmod 755 "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine"
}

engine_alive() {
  local p
  p=$(cat "$STUB_LAUNCHCTL_DIR/pids/$EJOB" 2>/dev/null)
  [ -n "$p" ] && kill -0 "$p" 2>/dev/null && grep -qx "pid=$p" "$STUB_ENGINE_DIR/ports/8484" 2>/dev/null
}

engine_up() {
  local i
  launchctl bootstrap "gui/$UIDN" "$H/Library/LaunchAgents/$EJOB.plist"
  for i in $(seq 150); do engine_alive && return 0; sleep 0.1; done
  bad "the engine did not start: $(tail -n 5 "$DATA/logs/engine.log")"
}

auster() {
  printf '%s' "${ANSWERS:-}" > "$W/answers"
  HOME="$H" AU_TTY="$W/answers" AU_SCREEN="$W/screen" /bin/bash "$DATA/bin/auster" "$@" > "$W/out" 2>&1
  RC=$?
}

login() {
  local f l
  for f in "$H"/Library/LaunchAgents/*.plist; do
    [ -f "$f" ] || continue
    l=$(plutil -extract Label raw -o - "$f")
    [ -f "$STUB_LAUNCHCTL_DIR/loaded/$l" ] && continue
    launchctl bootstrap "gui/$UIDN" "$f" > /dev/null 2>&1
  done
}

loaded() { [ -f "$STUB_LAUNCHCTL_DIR/loaded/$1" ]; }
override() { cat "$STUB_LAUNCHCTL_DIR/overrides/$1" 2>/dev/null || echo none; }

id_of() {
  local f
  for f in "$DATA"/keys/k*.name; do
    [ -f "$f" ] && [ "$(cat "$f")" = "$1" ] && { f=${f%.name}; printf '%s' "${f##*/}"; return 0; }
  done
  return 1
}
key_of() { local id; id=$(id_of "$1") && cat "$DATA/keys/$id"; }

ask_engine() {
  local h=()
  [ "$1" = - ] || { printf 'Authorization: Bearer %s\n' "$1" > "$W/ask-header"; h=(-H @"$W/ask-header"); }
  printf '{"messages":[{"role":"user","content":"Count from 1 to 3"}],"max_tokens":8,"temperature":0}' > "$W/ask-body"
  curl -q -s --max-time 10 -o /dev/null -w '%{http_code}' ${h[@]+"${h[@]}"} -H 'Content-Type: application/json' \
    --data-binary @"$W/ask-body" "http://${2:-10.0.0.5}:${3:-8484}/v1/chat/completions"
  rm -f "$W/ask-header"
}

qr_texts() { [ -s "$1" ] || return 0; osascript -l JavaScript "$TESTS/qr-read.js" "$1"; }

outsays() { if grep -qF -- "$1" "$W/out"; then ok "$2"; else bad "$2: [$1] not in: $(head -c 3000 "$W/out")"; fi; }
