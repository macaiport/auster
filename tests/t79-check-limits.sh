# T79: the check job, with no `timeout` on the PATH (T98's bare tools), still ends every part within its limit
# (B5, D3.4): curl's --max-time for each request, and a watchdog of the job's own for each part. With
# AU_CHECK_LIMIT=3, a probe whose /health never answers (the stub curl's hang, which --max-time does not cut)
# is left behind after 3+3+3+3 s and recorded as failed, and an updates.sh that never ends after 3 s while the
# probe still runs; a run with nothing hanging gives ok. Mutant: tests/mutants/T79a.
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

engine_job_end
curl_route GET http://127.0.0.1:8484/health hang -
t=$(date +%s); check_job; t=$(( $(date +%s) - t ))
[ "$t" -ge 12 ] && [ "$t" -le 25 ] && ok "a probe that hangs: the run ends in $t s" || bad "a probe that hangs: the run took $t s"
grep -q 'probe: still running after 12 s, so it is left behind' "$W/check.out" && ok "the probe is left behind at its limit" || bad "check.out: $(tail -n 5 "$W/check.out")"
same "$(probe_field probe)" failed "a probe left behind is recorded as failed"
done_
