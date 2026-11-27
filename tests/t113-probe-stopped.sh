# T113: while builds/stopped exists (B5 step 2), for either reason, unreadable (a folder, a link, text that is not
# the record) or of a newer format, the check job's probe sends nothing, `_update/engine` records `stopped`, and
# nothing is notified, run after run, though the engine is down (`auster stop`). After an `auster start` whose
# keyed question is not answered, no builds/stopped is left, and the probe runs again.
# Mutants: tests/mutants/T113a (common/auster-check) and T113b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
export AU_CHECK_LIMIT=3
auster start
same "$RC" 0 "the engine started"
auster stop
same "$RC" 0 "auster stop: the engine is down"
probes() { requests 127.0.0.1:8484 | wc -l | tr -d ' '; }

stopped_runs() { # LABEL
  local p0
  p0=$(probes); : > "$STUB_NOTIFY_LOG"
  check_job; check_job
  same "$(probes)" "$p0" "$1: the probe sent nothing"
  same "$(probe_field probe)" stopped "$1: _update/engine records stopped"
  same "$(notes)" 0 "$1: nothing is notified, two runs in a row"
}
stopped_runs "stopped by the household"
printf 'auster-record 1\topen\t2026-11-26T08:00:00Z\n' > "$DATA/builds/stopped"; stopped_runs "stopped as open"
rm -f "$DATA/builds/stopped"; mkdir "$DATA/builds/stopped"; stopped_runs "stopped, a folder"
rmdir "$DATA/builds/stopped"; ln -s "$W/nowhere" "$DATA/builds/stopped"; stopped_runs "stopped, a link to nothing"
rm -f "$DATA/builds/stopped"; printf 'a[$(touch f)]\n' > "$DATA/builds/stopped"; stopped_runs "stopped, text that is not the record"
printf 'auster-record 2\tsomething\n' > "$DATA/builds/stopped"; stopped_runs "stopped, a newer format"
printf 'auster-record 1\thousehold\t2026-11-26T08:00:00Z\n' > "$DATA/builds/stopped"

engine_set '*' behaviour nolisten
AU_SERVER_CHECK_SECS=4 auster start
same "$RC" 4 "a start whose keyed question is not answered: exit 4"
[ -e "$DATA/builds/stopped" ] || [ -L "$DATA/builds/stopped" ] && bad "builds/stopped is left after it" || ok "no builds/stopped is left after it"
p0=$(probes)
check_job
[ "$(probes)" -gt "$p0" ] && ok "the probe runs again" || bad "the probe sent nothing"
case "$(probe_field probe)" in down|failed) ok "and records the engine as $(probe_field probe)" ;; *) bad "probe: $(probe_field probe)" ;; esac
engine_set '*' behaviour ok
done_
