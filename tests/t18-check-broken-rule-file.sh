# T18 (U7; D2.2, D3.4, B4, B5): the engine never waits on the check. With _update/updates.sh replaced by a file with a
# syntax error, by one that sleeps for ever, and by one that exits 1, the engine job starts the engine in its usual time
# (listening within the 10 s engine_wait allows, and within 5 s of the first start, with the real rule file), and after
# the check job has fired (its update check left behind or failed, its probe, its notifications) the same engine is
# alive and answers a household device's question, and nothing is notified. Mutant: tests/mutants/T18a (run the check
# from the engine job).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
U="$DATA/_update"
leftovers() { pkill -f "${W##*/}/the home.s & more/Library/Application Support/Auster/_update/updates.sh" 2>/dev/null; return 0; }
trap 'leftovers; engine_job_end; install_cleanup' EXIT
KEY=$(key_of ipad)
[[ $KEY =~ ^[0-9a-f]{32}$ ]] && ok "the device ipad has a key" || bad "no key for ipad: [$KEY]"

started() { # LABEL -> the engine job run; ok when its engine listens. T, the seconds it took
  local t0
  : > "$W/engine-job.out"
  t0=$(date +%s); engine_job; engine_wait; T=$(( $(date +%s) - t0 ))
  same "$EJ_CODE" starting "$1: the engine job writes starting"
  [ -n "$EJ_START" ] && ok "  ...and its engine listens, after $T s" || bad "  ...no engine listening within 10 s: $(tail -n 3 "$W/engine-job.out")"
}
started "the real rule file"
BASE=$T
engine_job_end

broken() { # LABEL -> with updates.sh as the test made it
  started "$1"
  [ "$T" -le $((BASE + 5)) ] && ok "  ...in its usual time ($BASE s with the real rule file)" || bad "  ...$T s, against $BASE s with the real rule file"
  : > "$STUB_NOTIFY_LOG"; : > "$W/check.out"
  check_job
  grep -q 'probe: ok' "$W/check.out" && ok "  ...the check job fired, and its probe got an answer" || bad "  ...check.out: $(cat "$W/check.out")"
  kill -0 "$EJ" 2>/dev/null && grep -qx "pid=$EJ" "$STUB_ENGINE_DIR/ports/8484" && ok "  ...the same engine is alive and listening after it" ||
    bad "  ...the engine is gone"
  same "$(ask_engine "$KEY")" 200 "  ...and answers a household device's question"
  same "$(notes)" 0 "  ...nothing is notified"
  engine_job_end; leftovers
}
printf 'if then fi (\n' > "$U/updates.sh"; broken "updates.sh with a syntax error"
printf 'while :; do /bin/sleep 1; done\n' > "$U/updates.sh"; broken "updates.sh that sleeps for ever"
printf 'exit 1\n' > "$U/updates.sh"; broken "updates.sh that exits 1"
done_
