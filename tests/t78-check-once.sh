# T78: notifications once for each change of state (B5 step 6). The address changed: notified once, and not
# again at the next run (four hours later); back to the address the engine started on, nothing, and a new
# change notified again. down twice in a row: one notification, and none on the third; ok in between resets,
# so that down twice again notifies again. A build that no longer fits (B5 step 4, 32 GB here): notified once;
# fitting again clears it. A record of a newer format is left as it is and nothing is notified. Mutant:
# tests/mutants/T78a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs, started on 10.0.0.5"

check_job STUB_NET_ADDR=10.0.0.6
same "$(notes)" 1 "the address changed: one notification"
case "$(last_note)" in *"address on the home network has changed"*"auster restart"*) ok "it says so, and names auster restart" ;; *) bad "the notification: $(last_note)" ;; esac
same "$(probe_field address)" 10.0.0.6 "_update/engine records the address found"
same "$(probe_field probe)" ok "the probe on 127.0.0.1 still answers"
check_job STUB_NET_ADDR=10.0.0.6
same "$(notes)" 1 "the same change, four hours later: no notification"
check_job
same "$(notes)" 1 "back on the address the engine started on: no notification"
check_job STUB_NET_ADDR=10.0.0.7
same "$(notes)" 2 "a new change: notified again"

: > "$STUB_NOTIFY_LOG"
engine_job_end
check_job; same "$(notes)" 0 "down once: no notification"
check_job; same "$(notes)" 1 "down twice in a row: one notification"
check_job; same "$(notes)" 1 "down a third time: no more"
engine_job; engine_wait
check_job; same "$(probe_field probe)" ok "the engine back: ok"
same "$(probe_field failures)" 0 "ok resets the count"
engine_job_end
check_job; check_job
same "$(notes)" 2 "down twice again after an ok: notified again"

# The build no longer fits (B5 step 4): with 32 GB, order 1 at 4 x 32,768 leaves less than 12 GiB for the Mac
engine_job; engine_wait
: > "$STUB_NOTIFY_LOG"
check_job; same "$(probe_field told-fit)" no "64 GB: the build fits, nothing to tell"
check_job AU_RAM_BYTES=34359738368
same "$(notes)" 1 "32 GB: the build no longer fits, one notification"
case "$(last_note)" in *"no longer fits"*) ok "it says so" ;; *) bad "the notification: $(last_note)" ;; esac
check_job AU_RAM_BYTES=34359738368
same "$(notes)" 1 "32 GB four hours later: no more"
check_job; same "$(probe_field told-fit)" no "64 GB again: the state is cleared"
check_job AU_RAM_BYTES=34359738368
same "$(notes)" 2 "32 GB again: notified again"

# A record of a newer format is left as it is, and nothing is notified
printf 'auster-record 2\nsomething\tnew\n' > "$DATA/_update/engine"
check_job STUB_NET_ADDR=10.0.0.9
same "$(notes)" 2 "a newer _update/engine: no notification"
same "$(head -n 1 "$DATA/_update/engine")" "auster-record 2" "and the record is left as it is"
done_
