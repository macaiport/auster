# T74: the wait on builds/paused (B4 step 1, D3.1). paused naming a live process whose start time differs,
# one from an earlier boot, one that is gone, or a record older than 30 minutes: the engine starts. paused
# naming a live run (number, start time and boot session all matching): the job waits, and starts nothing.
# After an in-turn switch, it starts the build serving names once the run is gone, not the one it would have
# read before waiting. Mutants: tests/mutants/T74a and T74b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
BOOT=5E1A2B3C-0D4E-4F60-8A7B-9C0D1E2F3A4B          # the stub sysctl's boot session
LIVE='Thu Nov 26 09:00:00 2026'                     # what the stub ps gives a live process it has no line for
/bin/sleep 300 & P=$!
trap 'kill "$P" 2>/dev/null; engine_job_end; install_cleanup' EXIT
paused() { printf 'auster-record 1\t%s\t%s\t%s\n' "$1" "$2" "$3" > "$DATA/builds/paused"; }

starts_anyway() { # LABEL
  engine_job; engine_wait 150
  same "$EJ_CODE" starting "$1: the engine starts"
  [ -n "$EJ_START" ] && ok "$1: the engine listens" || bad "$1: no engine: $(tail -n 3 "$W/engine-job.out")"
  engine_job_end
}
paused "$P" "$BOOT" 'Wed Nov 25 08:00:00 2026'; starts_anyway "a live process whose start time differs"
paused "$P" 11111111-2222-3333-4444-555555555555 "$LIVE"; starts_anyway "a record from an earlier boot"
/usr/bin/true & G=$!; wait "$G"
paused "$G" "$BOOT" "$LIVE"; starts_anyway "a process that is gone"
paused "$P" "$BOOT" "$LIVE"; touch -t "$(/bin/date -v-31M +%Y%m%d%H%M)" "$DATA/builds/paused"
starts_anyway "a record older than 30 minutes"

# The live run: it waits. Then the run switches serving (order 2 at two people) and ends: the new build starts.
paused "$P" "$BOOT" "$LIVE"
engine_job; engine_wait 30
same "$EJ_CODE" none "a live run: no start record while it waits"
same "$(starts)" "$NSTARTS" "a live run: no engine started"
kill -0 "$EJ" 2>/dev/null && ok "a live run: the job is still waiting" || bad "a live run: the job ended: $(tail -n 3 "$W/engine-job.out")"
grep -q 'waiting: builds/paused names a run of Auster that is still alive' "$W/engine-job.out" && ok "it says why it waits" || bad "no word of the wait"
serving_put "$IB2" "$IMB" 2 32768
kill "$P"; wait "$P" 2>/dev/null
engine_wait 100
same "$EJ_CODE" starting "the run ended: the engine starts"
if [ -n "$EJ_START" ]; then
  same "$(sed -n '/^--alias$/{n;p;}' "$EJ_START/args")" "$IB2" "it starts the build the switch wrote, order 2"
  same "$(sed -n '/^-np$/{n;p;}' "$EJ_START/args")" 2 "at the setting the switch wrote"
else
  bad "no engine started after the run ended"
fi
done_
