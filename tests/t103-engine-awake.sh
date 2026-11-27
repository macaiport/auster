# T103, the engine job's half (V6; the download's half is t103-install-awake.sh): with the household's no in
# builds/mac the engine job runs no caffeinate; with yes it runs `caffeinate -i -w` naming its own process,
# which the engine then is (BD10, B4 step 7). Mutants: tests/mutants/T103c and T103d.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
same "$(sed -n 's/^keep-awake	//p' "$DATA/builds/mac")" no "builds/mac holds the household's no"
: > "$STUB_LOG"
engine_job; engine_wait
same "$EJ_CODE" starting "the no: the engine starts"
sleep 1
same "$(grep -c '^caffeinate' "$STUB_LOG")" 0 "the no: no caffeinate ran"
engine_job_end

sed 's/^keep-awake	no$/keep-awake	yes/' "$DATA/builds/mac" > "$W/mac" && cat "$W/mac" > "$DATA/builds/mac"
: > "$STUB_LOG"
engine_job; engine_wait
same "$EJ_CODE" starting "the yes: the engine starts"
for i in $(seq 50); do grep -q '^caffeinate' "$STUB_LOG" && break; sleep 0.1; done
same "$(grep '^caffeinate' "$STUB_LOG")" "caffeinate -i -w $EJ" "the yes: caffeinate -i -w names the job's process"
[ -n "$EJ_START" ] && same "$(cat "$EJ_START/pid")" "$EJ" "and that process is the engine" || bad "no engine started"
engine_job_end
done_
