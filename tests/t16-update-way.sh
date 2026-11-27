# T16 (U5; D3.6 step 4, C5, B4 step 1): the two ways of testing a new build. On a Mac serving order 2 for four at 32,768
# with order 1 waiting, the candidate slowed so that it is alive for two seconds before its test: told the Mac has room
# for both (a GPU limit of 100,000 MiB and 128 GB), the server answers a household key on order 2 while the candidate
# runs, and no builds/paused is written; told it has not (this 64 GB Mac), the engine is stopped before the candidate
# starts, nothing answers on the household's port while it runs, builds/paused names the update's own process, and the
# engine job, started again by launchd, waits on it (its log says so). Either way the update then switches to order 1.
# Mutants: tests/mutants/T16a (always in turn), T16b (always side by side).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
candidate_slow 2
look() { # -> while the candidate runs: the household's answer, whether paused exists and the process it names is alive,
  # and whether the engine job waits (given a second to say so, while the candidate is still loading)
  local p i
  printf 'answer %s\n' "$(ask_engine "$(key_of ipad)")"
  if [ -f "$DATA/builds/paused" ]; then
    p=$(cut -f2 "$DATA/builds/paused")
    if kill -0 "$p" 2>/dev/null && /bin/ps -p "$p" -o command= | grep -q 'driver\.sh update'; then echo "paused by the update"; else echo "paused by $p"; fi
  else
    echo "no paused"
  fi
  for i in $(seq 20); do
    grep -q 'waiting: builds/paused names a run of Auster that is still alive' "$DATA/logs/engine.log" && { echo "the engine job waits"; break; }
    sleep 0.05
  done
}

# --- room for both: side by side
big_mac
waiting_b1
during_test look
update_run $'yes\n'
wait "$DURING"
same "$RC" 0 "room for both: the update finishes, exit 0"
same "$(cat "$W/during")" "answer 200
no paused" "  ...while the candidate runs, the server answers a household key and nothing is paused"
same "$(arg_of "$(start_on 8484)" --alias)" "$IB1" "  ...then order 1 serves"

# --- no room for both: in turn
unset AU_GPU_MIB STUB_MEMSIZE
waiting_b1
: > "$DATA/logs/engine.log"
during_test look
update_run $'yes\n'
wait "$DURING"
same "$RC" 0 "no room for both: the update finishes, exit 0"
same "$(cat "$W/during")" "answer 000
paused by the update
the engine job waits" "  ...while the candidate runs, nothing answers, builds/paused names the update, and the engine job waits on it"
[ -e "$DATA/builds/paused" ] && bad "  ...builds/paused is left" || ok "  ...builds/paused gone afterwards"
same "$(arg_of "$(start_on 8484)" --alias)" "$IB1" "  ...then order 1 serves"
done_
