# T109, for a new build (U5; B3 step 13, D3.6 step 5): after an update's switch to a new build, a server that answers HTTP
# 500 (the stub engine failing for order 1 on the household's port, though its candidate passed its test): nothing
# switches back, serving names order 1 with a speed of 0, failed/ is unchanged, no stamp is written (release is at
# v0.2.0, so a stamp would move), the run says the server did not answer and names `auster rollback`, exit 4. A second
# update then prints OK for the recipe, makes the server check, and exits 4 again with no stamp. (`auster rollback`
# serving the old build with a speed of 0 until its check passes, and holding the new one, is U6's.)
# Mutants: those of tests/t109-check-fails.sh, which the switch to a new build shares: T109a (report success), T109b (put
# the build in failed/), T109e (switch back by itself), T109f (write the stamp on the second run).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, order 1 waiting
engine_up
release_at v0.2.0 "$COMMIT2"
engine_set "alias=$IB1,port=8484" behaviour http500
S="$DATA/builds/$IR/serving"
launch() { sed -n 5p "$S" | cut -f1-4,6; }
stamp() { cut -f3 "$DATA/_update/scripts"; }
failed() { ls -A "$DATA/builds/$IR/failed" 2>/dev/null | tr '\n' ' '; }
f0=$(failed) s0=$(cat "$S")

AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "a switch to order 1 whose server answers HTTP 500: exit 4"
says "Build $IB1 passed the recipe's test on this Mac" "  ...its candidate passed"
says "The server did not answer its check within 4 s" "  ...it says the server did not answer"
says "\`auster rollback\` goes back to what it served before, with no download." "  ...and names auster rollback"
same "$(sed -n 2p "$S" | cut -f2) $(launch)" "$IB1 launch	4	32768	8484	0" "  ...serving names order 1 with a speed of 0: nothing switches back"
same "$(cat "$DATA"/builds/$IR/kept/*)" "$s0" "  ...order 2 in kept/"
same "$(failed)" "$f0" "  ...failed/ unchanged"
same "$(stamp)" v0.1.0 "  ...no stamp"

AU_SERVER_CHECK_SECS=4 update_run ''
same "$RC" 4 "a second update: exit 4 again"
says "The recipe household: OK. Build $IB1 serves it, for 4 people at 32,768 tokens each." "  ...it prints OK for the recipe"
says "The server has not passed a check since its build was last switched" "  ...it makes the server check"
same "$(launch)" "launch	4	32768	8484	0" "  ...serving as it was"
same "$(stamp)" v0.1.0 "  ...no stamp"
engine_set "alias=$IB1,port=8484" behaviour ok
done_
