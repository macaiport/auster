# Sourced by the jobs' tests (V6: T70 to T80, T97's and T103's engine halves, T104, T105, and T107's file for
# the server check's no-key rule) after lib.sh, helpers.sh and install-helpers.sh. One first install makes a
# real data root, and the engine job and the check job are then run directly, as launchd runs them, with the
# stubs first on PATH:
#   job_install [make_home option...]   install_env and a first install (T69's answers: no keep-awake,
#                       four people, a device named ipad); the engine job launchd_hook started is then booted
#                       out, and the data root copied to $W/pristine. ED is the engine's folder, ESHA its sha256
#   job_reset           the data root put back as job_install left it, and any engine job stopped
#   engine_job [VAR=VALUE...]   jobs/auster-engine in the background with those variables (the network
#                       stubs'), its output appended to $W/engine-job.out; builds/<recipe>/start removed first.
#                       EJ is its process, NSTARTS the stub engine's starts before it
#   engine_wait [TENTHS]  waits (10 s by default) for its outcome: EJ_CODE, the code it wrote into start (none
#                       if it wrote none), and for `starting`, EJ_START, the stub engine's start folder, once
#                       that engine (EJ itself, by exec) listens
#   engine_job_end      the job stopped, with what it started (its wait, caffeinate, the engine)
#   starts              how many times the stub engine has started
#   check_job [VAR=VALUE...]    jobs/auster-check, to its end, its output appended to $W/check.out
#   probe_field KEY [N] field N (default 1) of the line KEY in _update/engine
#   speed_set SPEED     serving's launch line with that speed
#   serving_put BUILD MODEL PEOPLE CONTEXT [SPEED]  builds/<recipe>/serving for that build, its lines from
#                       the fixture registry, the installed engine's list, and its template and model (a stand-in, A or B)
#                       put in store/ when it lacks them, so that the build in use is whole (an update checks every file of
#                       it, D3.6, U6's third part)
#   notes / last_note   how many notifications the stub notifier has had / the sentence of the last one
# and for the notification of an update waiting (U7: T5's, T19's and T35's notification clauses, T20, T37):
#   release_says VERSION   release's CHANGELOG.md names VERSION (of 2026-12-01) and its registry.tsv is install_registry's
#                       of VERSION, as the check job's update check fetches them
#   update_notes        how many notifications of an update waiting the stub notifier has had
#   last_update_note    the sentence of the last of them
UIDN=501

job_install() {
  install_env "$@" || return 1
  trap 'engine_job_end; install_cleanup' EXIT
  fixture_hook
  run_install $'no\nyes\nipad\n' "$IR"
  if [ "$RC" != 0 ]; then bad "the fixture's install: exit $RC: $(tail -n 20 "$W/out")"; done_; fi
  launchctl bootout "gui/$UIDN/local.auster.engine"
  local i
  for i in $(seq 100); do [ -f "$STUB_ENGINE_DIR/ports/8484" ] || break; sleep 0.1; done
  launchd_hook
  ED=$(cd "$DATA"/engines/[0-9a-f]* && pwd -P)
  ESHA=${ED##*/}
  cp -Rp "$DATA" "$W/pristine"
  : > "$STUB_NOTIFY_LOG"
}

fixture_hook() { # -> while the fixture installs, the stub launchctl runs a stand-in for the engine job, so that
  # a mutant of the program under test cannot fail the fixture: it writes `start` and starts the stub engine
  # on 127.0.0.1 and the home address with the install's key file, as B4 step 8 would. launchd_hook puts the
  # real program back afterwards.
  mkdir -p "$STUB_LAUNCHCTL_DIR/hooks" "$STUB_LAUNCHCTL_DIR/pids"
  cat > "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine" <<'EOF'
#!/bin/bash
S=$STUB_LAUNCHCTL_DIR L=local.auster.engine
stop() { local p; p=$(cat "$S/pids/$L" 2>/dev/null); [ -z "$p" ] || kill "$p" 2>/dev/null; rm -f "$S/pids/$L"; }
start() {
  local plist prog log data r
  plist=$(cat "$S/loaded/$L")
  prog=$(/usr/bin/plutil -extract ProgramArguments.1 raw -o - "$plist")
  log=$(/usr/bin/plutil -extract StandardErrorPath raw -o - "$plist")
  data=${prog%/jobs/auster-engine}
  for r in "$data"/builds/r*/serving; do r=${r%/serving}; break; done
  printf 'auster-record 1\ncode\tstarting\naddress\t10.0.0.5\nboot\t%s\ntime\t%s\n' "$(sysctl -n kern.bootsessionuuid)" "$(/bin/date +%s)" > "$r/start"
  ( cd "$data/store" && exec "$data"/engines/*/root/llama-stub/llama-server -m stand-in --alias stand-in \
      --host 127.0.0.1,10.0.0.5 --port 8484 --api-key-file ../keys/engine.keys ) >> "$log" 2>&1 < /dev/null &
  echo $! > "$S/pids/$L"
}
case "$1" in bootstrap) start ;; kickstart) stop; start ;; bootout|disable) stop ;; esac
exit 0
EOF
  chmod 755 "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine"
}

job_reset() {
  engine_job_end
  rm -rf "$DATA"
  cp -Rp "$W/pristine" "$DATA"
}

starts() { ls "$STUB_ENGINE_DIR/starts" 2>/dev/null | wc -l | tr -d ' '; }

engine_job() {
  rm -f "$DATA/builds/$IR/start"
  NSTARTS=$(starts)
  env "$@" /bin/bash "$DATA/jobs/auster-engine" >> "$W/engine-job.out" 2>&1 < /dev/null &
  EJ=$!
}

engine_wait() {
  local i n=${1:-100} f="$DATA/builds/$IR/start"
  EJ_CODE=none EJ_START=
  for ((i = 0; i < n; i++)); do
    if [ -f "$f" ]; then
      EJ_CODE=$(sed -n 's/^code	//p' "$f")
      [ "$EJ_CODE" = starting ] || return 0
      if grep -qx "pid=$EJ" "$STUB_ENGINE_DIR"/ports/* 2>/dev/null; then EJ_START=$(cat "$STUB_ENGINE_DIR/pids/$EJ"); return 0; fi
    fi
    kill -0 "$EJ" 2>/dev/null || return 0
    sleep 0.1
  done
}

engine_job_end() {
  [ -n "${EJ:-}" ] || return 0
  pkill -P "$EJ" 2>/dev/null
  kill "$EJ" 2>/dev/null
  wait "$EJ" 2>/dev/null
  EJ=
  return 0
}

check_job() {
  env "$@" /bin/bash "$DATA/jobs/auster-check" >> "$W/check.out" 2>&1 < /dev/null
}

probe_field() { awk -F'\t' -v k="$1" -v n="${2:-1}" '$1 == k { print $(n + 1); exit }' "$DATA/_update/engine"; }

speed_set() {
  local s="$DATA/builds/$IR/serving"
  awk -F'\t' -v OFS='\t' -v v="$1" 'NR == 5 { $6 = v } { print }' "$s" > "$s.new" && mv "$s.new" "$s"
}

serving_put() {
  local s="$DATA/builds/$IR/serving" bl el ml list tsha f msha
  bl=$(grep "^build	$1	" "$FX/registry.tsv"); el=$(grep "^engine	$IE	" "$FX/registry.tsv"); ml=$(grep "^model	$2	" "$FX/registry.tsv")
  list=$(sed -n 5p "$W/pristine/builds/$IR/serving" | cut -f5)
  tsha=$(printf '%s\n' "$bl" | cut -f5)
  if [ ! -f "$DATA/store/$tsha" ]; then
    for f in "$FX"/assets/*; do
      [ "$(shasum -a 256 < "$f" | cut -c1-64)" = "$tsha" ] && { cp "$f" "$DATA/store/$tsha"; chmod 444 "$DATA/store/$tsha"; }
    done
  fi
  msha=$(printf '%s\n' "$ml" | cut -f7)
  case "$2" in "$IMA") f=standin-a.gguf ;; "$IMB") f=standin-b.gguf ;; *) f= ;; esac
  if [ -n "$f" ] && [ ! -e "$DATA/store/$msha" ]; then cp "$FX/models/$f" "$DATA/store/$msha"; chmod 444 "$DATA/store/$msha"; fi
  printf 'auster-descriptor 1\n%s\n%s\n%s\nlaunch\t%s\t%s\t8484\t%s\t%s\n' "$bl" "$el" "$ml" "$3" "$4" "$list" "${5:-36.9}" > "$s"
}

notes() { wc -l < "$STUB_NOTIFY_LOG" | tr -d ' '; }
last_note() { tail -n 1 "$STUB_NOTIFY_LOG" | cut -f2; }

release_says() {
  install_registry "$FX/registry-$1.tsv" "$1"
  printf '# Changelog\n\n## %s (2026-12-01)\n\nNew.\n' "$1" > "$FX/changelog-$1.md"
  route_drop "$CHANGELOG"; route_drop "$REGISTRY"
  curl_route GET "$CHANGELOG" 200 "$FX/changelog-$1.md"; curl_route GET "$REGISTRY" 200 "$FX/registry-$1.tsv"
}

update_notes() { grep -c ' is out' "$STUB_NOTIFY_LOG"; }
last_update_note() { grep ' is out' "$STUB_NOTIFY_LOG" | tail -n 1 | cut -f2; }
