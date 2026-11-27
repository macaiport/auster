# T25 (U5; D3.6 steps 4 and 5, B4 step 1, D3.1): an update killed between stopping the engine and starting it. On this
# 64 GB Mac serving order 2 with order 1 waiting, the update tests in turn: once the engine is stopped and the candidate
# runs (slowed, so that it is alive for three seconds before its test), the update's own process, the one builds/paused
# names, is killed with SIGKILL, as a power cut or a closed window would leave it. Without a restart of the Mac the engine
# job, which waited on builds/paused, starts order 2 again, which answers a household key; serving is as it was and kept/
# empty, so the candidate is never served; the candidate itself is stopped by its watch within seconds; and `auster
# status` reports the update that ended before it finished. The next update takes the lock over and finishes.
# Mutants: tests/mutants/T25a (the engine job prefers the candidate while the lock exists: the update writes the candidate
# into serving before its test, where the engine job reads it), T25b (the engine job waits on paused whether or not its
# process is alive), T25c (`auster status` says nothing of a lock left by a run that died), T25d (no watch on the
# candidate: it outlives a killed update).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2 for four at 32,768, order 1 waiting
engine_up
candidate_slow 3
S="$DATA/builds/$IR/serving"
s0=$(cat "$S")

( update_run $'yes\n' ) &
up=$!
for i in $(seq 300); do [ -f "$STUB_ENGINE_DIR/ports/$CPORT" ] && [ -f "$DATA/builds/paused" ] && break; sleep 0.05; done
[ -f "$STUB_ENGINE_DIR/ports/$CPORT" ] && [ -f "$DATA/builds/paused" ] && ok "the candidate runs, builds/paused written" || bad "no candidate, or no builds/paused: $(tail -n 5 "$W/out")"
[ -f "$STUB_ENGINE_DIR/ports/8484" ] && bad "  ...the engine still listens" || ok "  ...and the engine stopped"
cand=$(sed -n 's/^pid=//p' "$STUB_ENGINE_DIR/ports/$CPORT")
p=$(cut -f2 "$DATA/builds/paused")
/bin/ps -p "$p" -o command= | grep -q 'driver\.sh update' && ok "  ...builds/paused names the update" || bad "  ...builds/paused names $p: $(/bin/ps -p "$p" -o command=)"
kill -9 "$p"
wait "$up"
for i in $(seq 150); do [ -f "$STUB_ENGINE_DIR/ports/8484" ] && break; sleep 0.1; done
same "$(arg_of "$(start_on 8484)" --alias) $(ask_engine "$(key_of ipad)")" "$IB2 200" "killed: the engine job starts order 2 again, which answers a household key"
same "$(cat "$S")" "$s0" "  ...serving as it was"
same "$(ls -A "$DATA/builds/$IR/kept")" "" "  ...kept/ empty: the candidate never served"
for i in $(seq 50); do kill -0 "$cand" 2>/dev/null || break; sleep 0.1; done
kill -0 "$cand" 2>/dev/null && { bad "  ...the candidate still runs"; kill "$cand"; } || ok "  ...and the candidate was stopped by its watch"
auster status
outsays "A run of Auster (process $p) that was installing, updating or changing the server ended before it finished." "auster status reports the update that ended before it finished"

engine_set "port=$CPORT" load 0
update_run $'yes\n'
same "$RC" 0 "the next update takes the lock over and finishes: exit 0"
same "$(sed -n 2p "$S" | cut -f2)" "$IB1" "  ...order 1 serves"
done_
