# T32 (U5; D3.6 step 5, B3 step 13): a fallback after which the server does not answer. On this 64 GB Mac serving order 2
# with order 1 waiting, tested in turn, the candidate fails its test, and the old build the engine job starts again once
# builds/paused is gone does not answer (the stub engine on the household's port never listens): the update makes the
# server check, says the server did not answer and why, names `auster restart`, and exits 4; serving is as it was, and no
# stamp is written (release is at v0.2.0).
# Mutant: tests/mutants/T32a (report the fallback without asking the server).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
engine_up
release_at v0.2.0 "$COMMIT2"
candidate_slow 1
engine_set "port=$CPORT" answers "$FX/answers-bad"
down() { engine_set 'port=8484' behaviour nolisten; echo down; }
s0=$(cat "$DATA/builds/$IR/serving") st0=$(cat "$DATA/_update/scripts")
during_test down
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
wait "$DURING"
same "$RC" 4 "a failed test, then an old build that does not answer: exit 4"
says "Build $IB1 did not pass the recipe's test on this Mac." "  ...it says the test failed"
says "The server did not answer its check within 4 s: the engine job started the engine, but the engine did not answer the recipe's question (starting)." "  ...it says the server did not answer, and why, the start code in parentheses"
says "\`auster restart\` starts it again and checks it." "  ...and names auster restart"
same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"
same "$(cat "$DATA/_update/scripts")" "$st0" "  ...no stamp written"
engine_set 'port=8484' behaviour ok
done_
