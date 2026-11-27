# T80: the check job never stops, starts or restarts the engine (B5, D2.2). A gate on the source: its program
# and everything it loads (capability.js and the two files that file loads, and updates.sh once U1 adds it)
# hold no launchctl, kill or pkill; the copies in jobs/ are the tree's. And the engine, started by launchd
# (the stub launchctl and its hook), keeps its process after every probe: one that answers, one after the
# address changed, one while it answers HTTP 500, one while it is open; the stub launchctl logs no call from
# the check job. Mutant: tests/mutants/T80a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
for f in common/auster-check common/capability.js common/capability-lib.js common/registry-lib.js common/updates.sh; do
  [ -f "$ROOT/$f" ] || continue
  hits=$(grep -n -w -E 'launchctl|kill|pkill' "$ROOT/$f")
  same "$hits" "" "$f holds no launchctl, kill or pkill"
done
for f in auster-check capability.js capability-lib.js registry-lib.js; do
  case "$f" in auster-check) src=$ROOT/common/auster-check ;; *) src=$ROOT/common/$f ;; esac
  cmp -s "$src" "$DATA/jobs/$f" && ok "jobs/$f is the tree's" || bad "jobs/$f differs from the tree's"
done

launchctl bootstrap "gui/$UIDN" "$H/Library/LaunchAgents/local.auster.engine.plist"
for i in $(seq 100); do grep -q '^pid=' "$STUB_ENGINE_DIR/ports/8484" 2>/dev/null && break; sleep 0.1; done
pid=$(sed -n 's/^pid=//p' "$STUB_ENGINE_DIR/ports/8484")
[ -n "$pid" ] && ok "launchd started the engine (process $pid)" || bad "no engine: $(tail -n 5 "$DATA/logs/engine.log")"
n=$(starts) calls=$(grep -c '^launchctl' "$STUB_LOG")

unchanged() { # LABEL
  same "$(sed -n 's/^pid=//p' "$STUB_ENGINE_DIR/ports/8484")" "$pid" "$1: the engine's process is the same"
  kill -0 "$pid" 2>/dev/null && ok "$1: and alive" || bad "$1: the engine is gone"
  same "$(starts)" "$n" "$1: no engine started"
  same "$(grep -c '^launchctl' "$STUB_LOG")" "$calls" "$1: no launchctl call"
}
check_job; same "$(probe_field probe)" ok "a probe that answers: ok"; unchanged "a probe that answers"
check_job STUB_NET_ADDR=10.0.0.6; same "$(notes)" 1 "the address changed: notified"; unchanged "after the address changed"
engine_live 8484 behaviour http500
check_job; same "$(probe_field probe)" broken "HTTP 500: broken"; unchanged "while it answers HTTP 500"
engine_live 8484 behaviour ok; engine_live 8484 open 1
check_job; same "$(probe_field probe)" open "open: open"; unchanged "while it is open"
done_
