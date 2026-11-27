# T76: a permanent fault (keys, engine-hash, not-home, B4 steps 3 to 5): the job writes its code into start,
# then waits 60 s before it exits, so that launchd, which keeps it alive, starts it at most once a minute. Each
# fault's job is still alive seconds after start is written, its wait is `sleep 60`, and it says so. Mutant:
# tests/mutants/T76a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install

fault_waits() { # CODE LABEL VAR=VALUE...
  local c=$1 l=$2 w
  shift 2
  : > "$W/engine-job.out"
  engine_job "$@"; engine_wait
  same "$EJ_CODE" "$c" "$l: start says $c"
  sleep 2
  if kill -0 "$EJ" 2>/dev/null; then ok "$l: the job is still alive 2 s after start was written"; else bad "$l: the job exited at once"; fi
  w=$(/bin/ps -o command= -p "$(pgrep -P "$EJ" | head -n 1)" 2>/dev/null)
  same "$w" "sleep 60" "$l: it waits with sleep 60"
  grep -q "^.* auster-engine: $c: .* It waits 60 s, then exits, and launchd starts it again\.$" "$W/engine-job.out" &&
    ok "$l: it says it waits 60 s" || bad "$l: it says: $(cat "$W/engine-job.out")"
  same "$(starts)" "$NSTARTS" "$l: no engine started"
  engine_job_end
  job_reset
}
: > "$DATA/keys/engine.keys"; fault_waits keys "an empty key file"
chmod 644 "$DATA/store/$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f5)"
printf 'x' >> "$DATA/store/$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f5)"; fault_waits engine-hash "a changed template"
fault_waits not-home "a default route through a VPN" STUB_NET_IF=utun0
done_
