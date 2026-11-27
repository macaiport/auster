# T115 (U5; D3.6 step 5, C5, BD19): side by side, a test that overflowed breaks the serving engine too. On a Mac that holds
# both builds (a GPU limit of 100,000 MiB and 128 GB), serving order 2 with order 1 waiting, the candidate answering every
# question badly, and the serving stub engine answering HTTP 500 from the moment the candidate starts until it is
# restarted, as an engine does when another overflowed the GPU (docs/phase-2.md, section 6): the update restarts the
# serving engine (kickstart -k), makes the server check, which passes, says the test failed, and exits 3. With the
# restarted engine still failing: exit 4, naming `auster restart` and not `auster rollback`. Serving unchanged throughout.
# Mutants: tests/mutants/T115a (check only that the serving process is alive), T115b (skip the restart after a fail),
# T115c (name `auster rollback`).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
big_mac
waiting_b1
engine_up
candidate_slow 2
engine_set "port=$CPORT" answers "$FX/answers-bad"
S="$DATA/builds/$IR/serving"
s0=$(cat "$S")
break_it() { engine_live 8484 behaviour http500; echo "broken: $(ask_engine "$(key_of ipad)")"; }
break_for_good() { engine_set 'port=8484' behaviour http500; break_it; }

during_test break_it
n=$(wc -l < "$STUB_LOG")
update_run $'yes\n'
wait "$DURING"
same "$RC" 3 "side by side, the test fails and breaks the serving engine: exit 3"
same "$(cat "$W/during")" "broken: 500" "  ...the serving engine answered HTTP 500 while the candidate ran"
case "$(job_calls "$n")" in *'launchctl kickstart'*) ok "  ...the update restarted it (kickstart -k)" ;; *) bad "  ...no restart: $(job_calls "$n")" ;; esac
says "Build $IB1 did not pass the recipe's test on this Mac." "  ...it says the test failed"
says "The server answered on build $IB2" "  ...and the server check passed after the restart"
same "$(cat "$S")" "$s0" "  ...serving unchanged"
same "$(ask_engine "$(key_of ipad)")" 200 "  ...and the server answers a household key"

rm -f "$DATA/builds/$IR"/failed/*
during_test break_for_good
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
wait "$DURING"
same "$RC" 4 "the restarted engine still failing: exit 4"
says "Serving is still build $IB2, which it was before the test: \`auster restart\` starts it again and checks it." "  ...it names auster restart"
says_not "auster rollback" "  ...and not auster rollback"
same "$(cat "$S")" "$s0" "  ...serving unchanged"
engine_set 'port=8484' behaviour ok
done_
