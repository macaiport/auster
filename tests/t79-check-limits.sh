# T79: the check job, with no `timeout` on the PATH (T98's bare tools), still ends every part within its limit
# (B5, D3.4): curl's --max-time for each request, and a watchdog of the job's own for each part. With
# AU_CHECK_LIMIT=3, a probe whose /health never answers (the stub curl's hang, which --max-time does not cut)
# is left behind after 3+3+3+3 s and recorded as failed, and an updates.sh that never ends after 3 s while the
# probe still runs; a run with nothing hanging gives ok. U7: the two asks of updates.sh for an update's notification
# (--noted, --recipes) each have the update check's limit. Mutants: tests/mutants/T79a, and T79b and T79c (ask --noted,
# or --recipes, with no time limit).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
command -v timeout > /dev/null 2>&1 && bad "timeout is on the PATH" || ok "timeout is not on the PATH"
leftovers() { # -> the processes a hang left behind, stopped (launchd would end them with the job)
  local d
  for d in "$STUB_CURL_DIR"/requests/*; do kill "$(cat "$d/pid")" 2>/dev/null; done
  pkill -f "${W##*/}/the home.s & more/Library/Application Support/Auster/_update/updates.sh" 2>/dev/null
  return 0
}
trap 'leftovers; engine_job_end; install_cleanup' EXIT

engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
rm -f "$DATA/_update/updates.sh"   # the install deploys it (U1); this run is the check job without one
check_job
same "$(probe_field probe)" ok "nothing hangs: the probe gives ok"
grep -q 'no _update/updates.sh yet, so no update check' "$W/check.out" && ok "with no updates.sh it says there is no update check" || bad "check.out: $(cat "$W/check.out")"

cat > "$DATA/_update/updates.sh" <<'UPD'
while :; do /bin/sleep 1; done
UPD
t=$(date +%s); check_job; t=$(( $(date +%s) - t ))
[ "$t" -le 12 ] && ok "updates.sh never ends: the run ends in $t s" || bad "updates.sh never ends: the run took $t s"
grep -q 'update: still running after 3 s, so it is left behind' "$W/check.out" && ok "the update check is left behind at its limit" || bad "check.out: $(tail -n 5 "$W/check.out")"
same "$(probe_field probe)" ok "and the probe still runs: ok"
rm "$DATA/_update/updates.sh"; leftovers

# U7: each ask for an update's notification has the update check's limit. A rule file whose check says it fetched and
# whose --noted never ends: left behind after 3 s, the run ends, nothing notified; one whose --noted names v0.2.0 and
# whose --recipes never ends: left behind too, and the update notified with no recipe named. Each run is watched from
# here, so that a part with no limit fails this test rather than hanging it.
ends() { # LABEL PART -> check_job, ended within 30 s, with PART left behind at its limit
  local i t=$(date +%s)
  : > "$STUB_NOTIFY_LOG"; : > "$W/check.out"
  check_job & CJ=$!
  for i in $(seq 300); do kill -0 "$CJ" 2>/dev/null || break; sleep 0.1; done
  if kill -0 "$CJ" 2>/dev/null; then bad "$1: the run still goes after 30 s"; pkill -P "$CJ"; kill "$CJ" 2>/dev/null
  else ok "$1: the run ends in $(( $(date +%s) - t )) s"; fi
  wait "$CJ" 2>/dev/null
  grep -q "$2: still running after 3 s, so it is left behind" "$W/check.out" && ok "  ...--$2 is left behind at its limit" ||
    bad "  ...check.out: $(tail -n 5 "$W/check.out")"
  leftovers
}
cat > "$DATA/_update/updates.sh" <<'UPD'
case "${1:-}" in
  --refresh) printf 'ready\tv0.1.0\tv0.2.0\t-\tfetched\n' ;;
  --noted) [ -f "${0%/*}/t79-noted" ] && { echo v0.2.0; exit 0; }; while :; do /bin/sleep 1; done ;;
  --recipes) while :; do /bin/sleep 1; done ;;
esac
UPD
ends "--noted never ends" noted
same "$(notes)" 0 "  ...and nothing is notified"
: > "$DATA/_update/t79-noted"
ends "--recipes never ends" recipes
same "$(last_note)" "Auster v0.2.0 is out. auster status says what would change, and auster update asks before changing anything." \
  "  ...and the update is notified, naming no recipe"
rm "$DATA/_update/updates.sh" "$DATA/_update/t79-noted"

engine_job_end
curl_route GET http://127.0.0.1:8484/health hang -
t=$(date +%s); check_job; t=$(( $(date +%s) - t ))
[ "$t" -ge 12 ] && [ "$t" -le 25 ] && ok "a probe that hangs: the run ends in $t s" || bad "a probe that hangs: the run took $t s"
grep -q 'probe: still running after 12 s, so it is left behind' "$W/check.out" && ok "the probe is left behind at its limit" || bad "check.out: $(tail -n 5 "$W/check.out")"
same "$(probe_field probe)" failed "a probe left behind is recorded as failed"
done_
