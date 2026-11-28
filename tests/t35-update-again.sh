# T35, `auster update`'s half (U4; D3.3, D3.6 step 2): a person's no leaves the build waiting. On a Mac serving order 2
# with order 1 waiting, `auster update` opens the update, whose question, answered no, exits 1; `auster status` then
# still shows order 1 waiting, the rule file still says ready and --noted names nothing (no notification for a build
# waiting for a reason on the Mac), and `auster update` offers it again: it opens the update once more, whose question
# names the same build. U7: between the two, the check job checks release, which names the same version, and sends no
# notification. Mutants: tests/mutants/T35b (a no holds the build), T35c (tell of a build waiting as of a new version),
# and T35a (status's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
U="$DATA/_update"
auster update
same "$RC" 0 "auster update: exit 0, the update opened"
run_command "$(opened | tail -n 1)" $'no\n'
same "$RC" 1 "  ...its question answered no: exit 1"
says "The recipe household: an update is waiting." "  ...the question named the recipe"
says "After       build $IB1 (standin-a.gguf)" "  ...and order 1"
auster status
outsays "The recipe household: waiting. An update would move it from build $IB2 to build $IB1 (standin-a.gguf)" "status after the no: still waiting"
outsays "an update is waiting for this Mac (below)." "  ...and an update waiting for this Mac"
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" | cut -f1)" ready "the rule file: still ready"
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" --noted)" "" "  ...and --noted names nothing"
[ -e "$DATA/builds/$IR/hold" ] && bad "a hold was written: $(cat "$DATA/builds/$IR/hold")" || ok "no hold written"
release_says v0.1.0; rm -f "$U/tried"; rm -rf "$STUB_CURL_DIR/requests"; : > "$STUB_NOTIFY_LOG"
AU_CHECK_LIMIT=3 check_job
same "$(requests raw.githubusercontent.com | wc -l | tr -d ' ')" 2 "the check job checks release, which names v0.1.0 too"
same "$(update_notes)" 0 "  ...and sends no notification of the build still waiting"
auster update
same "$RC:$(opened | grep -c .)" "0:2" "auster update again: the update opened again"
run_command "$(opened | tail -n 1)" $'no\n'
same "$RC" 1 "  ...answered no again: exit 1"
says "After       build $IB1 (standin-a.gguf)" "  ...its question offers order 1 again"
done_
