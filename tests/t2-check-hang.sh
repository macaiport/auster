# T2 (U7; B5 step 1, D3.4): with release's CHANGELOG.md hanging (the stub curl's hang, which --max-time does not cut), the
# check job ends within its time limit (AU_CHECK_LIMIT=3: the update check left behind after 3 s), the day's try is used
# up (`tried` written before the fetch, so that a firing an hour later sends no request), `offer` is unchanged and
# nothing is said (no notification, though release's registry names v0.2.0). The run is watched from here, so that an
# update check with no limit fails this test rather than hanging it. Mutant: tests/mutants/T2a (call the check with no
# time limit).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
U="$DATA/_update"
leftovers() { # -> the processes a hang left behind, stopped (launchd would end them with the job)
  local d   # the rule file first, so that it cannot go on to its second request once its curl is gone
  pkill -f "${W##*/}/the home.s & more/Library/Application Support/Auster/_update/updates.sh" 2>/dev/null
  for d in "$STUB_CURL_DIR"/requests/*; do kill "$(cat "$d/pid" 2>/dev/null)" 2>/dev/null; done
  return 0
}
trap 'leftovers; engine_job_end; install_cleanup' EXIT
engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
release_says v0.2.0; route_drop "$CHANGELOG"; curl_route GET "$CHANGELOG" hang -
rm -f "$U/tried"; offer=$(cat "$U/offer" 2>/dev/null || echo none)
rm -rf "$STUB_CURL_DIR/requests"; : > "$STUB_NOTIFY_LOG"
t0=$(date +%s)
check_job & CJ=$!
for i in $(seq 300); do kill -0 "$CJ" 2>/dev/null || break; sleep 0.1; done
t=$(( $(date +%s) - t0 ))
if kill -0 "$CJ" 2>/dev/null; then bad "the run still goes after 30 s"; pkill -P "$CJ"; kill "$CJ" 2>/dev/null
else [ "$t" -le 15 ] && ok "release's changelog hangs: the run ends in $t s" || bad "the run took $t s"; fi
wait "$CJ" 2>/dev/null
grep -q 'update: still running after 3 s, so it is left behind' "$W/check.out" && ok "  ...the update check left behind at its limit" ||
  bad "  ...check.out: $(tail -n 5 "$W/check.out")"
same "$(requests raw.githubusercontent.com)" "GET $CHANGELOG" "  ...after the one request, which hangs"
tried=$(cut -f2 "$U/tried" 2>/dev/null)
[[ $tried =~ ^[0-9]+$ ]] && [ "$tried" -ge "$t0" ] && ok "  ...the day's try is used up: tried says $tried" || bad "  ...tried: $(cat "$U/tried" 2>&1)"
same "$(cat "$U/offer" 2>/dev/null || echo none)" "$offer" "  ...offer unchanged"
same "$(notes)" 0 "  ...and nothing is said"
same "$(probe_field probe)" ok "  ...while the probe still ran"
leftovers; rm -rf "$STUB_CURL_DIR/requests"
check_job AU_UPDATE_NOW=$((tried + 3600))
same "$(requests raw.githubusercontent.com | wc -l | tr -d ' '):$(notes)" 0:0 "an hour later: no request, nothing said"
done_
