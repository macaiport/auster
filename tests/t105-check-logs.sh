# T105: the check job truncates a log in logs/ above 50 MB (50,000,000 bytes) in place, and the engine's next
# line, written through the file launchd gave it open for appending, lands in it, at its start; a log of
# exactly 50,000,000 bytes is untouched, and so is a link in logs/ to a large file elsewhere (B5 step 5).
# Mutant: tests/mutants/T105a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
L="$DATA/logs"
rm -f "$L"/*
dd if=/dev/zero of="$L/engine.log" bs=1 count=0 seek=50000001 2> /dev/null
dd if=/dev/zero of="$L/check.log" bs=1 count=0 seek=50000000 2> /dev/null
dd if=/dev/zero of="$W/big" bs=1 count=0 seek=60000000 2> /dev/null
ln -s "$W/big" "$L/linked.log"
same "$(stat -f %z "$L/engine.log") $(stat -f %z "$L/check.log")" "50000001 50000000" "the logs: one byte over 50 MB, and 50 MB"
ino=$(stat -f %i "$L/engine.log")
# the engine, as launchd starts it: its output opened for appending, held open, written to after the check
( exec 5>> "$L/engine.log"; while [ ! -f "$W/go" ]; do sleep 0.1; done; printf 'the engine goes on\n' >&5; touch "$W/written" ) &
writer=$!
sleep 0.5
check_job
touch "$W/go"
for i in $(seq 50); do [ -f "$W/written" ] && break; sleep 0.1; done
wait "$writer"
same "$(stat -f %i "$L/engine.log")" "$ino" "engine.log is the same file"
same "$(cat "$L/engine.log")" "the engine goes on" "engine.log was truncated, and the engine's next line is in it, at its start"
same "$(stat -f %z "$L/check.log")" 50000000 "a log of 50,000,000 bytes is untouched"
[ -L "$L/linked.log" ] && same "$(stat -f %z "$W/big")" 60000000 "a link in logs/ is not followed" || bad "the link is gone"
grep -q 'truncated engine.log, which held 50000001 bytes' "$W/check.out" && ok "the check's log says so" || bad "check.out: $(tail -n 5 "$W/check.out")"
done_
