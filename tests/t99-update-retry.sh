# T99 (U5; D3.7, BD12): a build in failed/ is not offered by `auster update`; `auster update --retry` offers
# it. On a Mac serving order 2 whose order 1 failed its test here (failed/ holds its descriptor, its files in store/):
# the rule file's word is current, `auster update` says nothing is waiting, and the update itself prints OK for the
# recipe, exit 0. `auster update --retry` over SSH runs the update with `update --retry`: its question offers order 1 and
# says it failed its test here on that date and is tested again; answered no, exit 1. At the Mac's screen it opens a
# .command file that runs `update --retry`, whose yes tests order 1 again (U5's last part): the candidate failing again,
# exit 3, a second entry for order 1 in failed/ and order 2 still serving; tried again with the candidate passing, exit 0,
# order 1 out of failed/ and serving. With nothing in failed/, `auster update --retry` refuses (exit 1) and opens nothing.
# Mutants: tests/mutants/T99a (offer failed builds), T99b (`--retry` that skips the test), T99c (the update ignores
# --retry).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, _update's registry and offer of v0.1.0
cp "$W/pristine/store/$SA" "$DATA/store/$SA"
F="$DATA/builds/$IR/failed/2026-11-25T10:00:00Z-$IB1"
mkdir -m 700 "$DATA/builds/$IR/failed"; cp "$W/pristine/builds/$IR/serving" "$F"; chmod 600 "$F"
U="$DATA/_update"

same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" | cut -f1)" current "order 1 failed here: the rule file's word is current"
auster update
same "$RC" 1 "auster update: exit 1"
outsays "Nothing is waiting" "  ...nothing is waiting"
update_run ''
same "$RC" 0 "the update itself: exit 0"
says "The recipe household: OK. Build $IB2 serves it" "  ...it prints OK: order 1 is not offered"

ANSWERS=$'no\n' SSH_CONNECTION='10.0.0.9 50111 10.0.0.5 22' auster update --retry
same "$RC" 1 "auster update --retry over SSH, answered no: exit 1"
outsays "  After       build $IB1 (standin-a.gguf)" "  ...the question offers order 1 again"
outsays "  Tried again Build $IB1 failed its test on this Mac on 2026-11-25; it is tested again before it serves." "  ...and says it failed here, and is tested again"

engine_set "port=$CPORT" answers "$FX/answers-bad"; c0=$(start_on $CPORT)
auster update --retry
same "$RC:$(opened | grep -c .)" "0:1" "auster update --retry at the screen: exit 0, one file opened"
grep -qx "RETRY='--retry'" "$(opened | tail -n 1)" && ok "  ...a file that runs update --retry" || bad "  ...the file does not retry: $(head -n 4 "$(opened | tail -n 1)")"
run_command "$(opened | tail -n 1)" $'yes\n'
same "$RC" 3 "  ...run and answered yes, the candidate failing again: exit 3"
c=$(start_on $CPORT)
[ "$c" != "$c0" ] && [ "$(arg_of "$c" --alias)" = "$IB1" ] && ok "  ...order 1 was tested again" || bad "  ...no new test of order 1"
same "$(ls "$DATA/builds/$IR/failed" | grep -c -- "-$IB1\$") $(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "2 $IB2" \
  "  ...a second entry for it in failed/, and order 2 still serves"

engine_set "port=$CPORT" answers "$FX/answers-good"
auster update --retry
run_command "$(opened | tail -n 1)" $'yes\n'
same "$RC" 0 "tried again, the candidate passing: exit 0"
[ "$(start_on $CPORT)" != "$c" ] && ok "  ...order 1 was tested again" || bad "  ...no new test of order 1"
same "$(ls -A "$DATA/builds/$IR/failed" | wc -l | tr -d ' ') $(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "0 $IB1" \
  "  ...it left failed/, and order 1 serves"

o=$(opened | grep -c .)
auster update --retry
same "$RC:$(opened | grep -c .)" "1:$o" "nothing in failed/ now: auster update --retry refuses, and opens nothing"
outsays "No build has failed its test on this Mac, so there is nothing to try again" "  ...it says so"
done_
