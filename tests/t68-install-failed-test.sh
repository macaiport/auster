# T68: a build that fails the recipe's test at a first install (B3 step 10): no job file in
# ~/Library/LaunchAgents, no engine process, no serving, no key shown, the descriptor in failed/, and exit 5
# with the list of what is left and how to remove it; a simulated login starts nothing. A second run, its
# engine now passing, tests again without downloading again, and the build leaves failed/. On the way,
# the two ways to remove that B3 step 3 promises from then on are run once each (their own tests, T85,
# T86 and T108, are V7's): `install.sh remove` answered no at its second question keeps the files, and
# `auster remove` answered yes twice leaves the home folder as it was before the install.
# Mutants: tests/mutants/T68a and T68b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
home0=$(snapshot "$H")
engine_set 'port=18484' answers "$FX/answers-bad"   # the candidate's port (B3 step 10): every question answered badly

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "a failed test: exit 5"
says "The build did not pass the recipe's test on this Mac, so nothing is serving and nothing is loaded." "it says the test failed and nothing serves"
says "What is left, in $DATA:" "it lists what is left"
says "remove all of it with: \"$DATA/bin/auster\" remove" "and how to remove it"
same "$(grep -c '^  Q[0-9][0-9] FAIL' "$W/out")" 12 "the recipe's test ran, and each question failed"
same "$(ls -A "$H/Library/LaunchAgents")" "" "no job file in ~/Library/LaunchAgents"
same "$(ls "$STUB_ENGINE_DIR/pids" 2>/dev/null; ls "$STUB_ENGINE_DIR/ports" 2>/dev/null)" "" "no engine process, and nothing listening"
[ -e "$DATA/builds/$IR/serving" ] && bad "serving was written" || ok "no serving"
f=$(ls "$DATA/builds/$IR/failed/" 2>/dev/null)
case "$f" in 20[0-9][0-9]-*Z-"$IB1") ok "the descriptor is in failed/, named by the date and the build" ;; *) bad "failed/: [$f]" ;; esac
same "$(head -n 1 "$DATA/builds/$IR/failed/$f") $(tail -n 1 "$DATA/builds/$IR/failed/$f" | cut -f1,6)" "auster-descriptor 1 launch	0" "a descriptor, with a speed of 0"
grep -q 'A key is made' "$W/out" && bad "a key was shown" || ok "no key shown"
same "$(ls -A "$DATA/keys")" "" "no key made"
same "$(grep -c '^launchctl' "$STUB_LOG")" 0 "launchctl was never called"
same "$(ls -A "$STUB_LAUNCHCTL_DIR/loaded" 2>/dev/null)" "" "a simulated login starts nothing: no job is loaded, and none is there to load"
[ -f "$DATA/store/$SA" ] && ok "the model it fetched is kept for the next run" || bad "the model is not kept"

# install.sh remove, as the bootstrap runs it: yes to stop and unload, no to deleting the files
files=$(snapshot "$DATA")
run_install $'yes\nno\n' remove
same "$RC" 0 "install.sh remove, no at the second question: exit 0"
says "The files are kept." "install.sh remove: it says the files are kept"
same "$(snapshot "$DATA")" "$files" "install.sh remove: the files are as they were"
same "$(cat "$STUB_LAUNCHCTL_DIR/overrides/local.auster.engine" "$STUB_LAUNCHCTL_DIR/overrides/local.auster.check")" "enabled
enabled" "install.sh remove: both labels left enabled, so that a later install can load them"

# A second run: the candidate now passes. It rests on the state the first left, so it is not run when a
# check above failed.
[ "$FAILS" -eq 0 ] || done_
engine_set 'port=18484' answers "$FX/answers-good"
rm -rf "$STUB_CURL_DIR/requests"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "a second run: installed"
same "$(grep -c '^  Q[0-9][0-9] PASS' "$W/out")" 12 "it tested again"
same "$(requests | grep ' https://' | cut -d' ' -f2 | tr '\n' ' ')" "$API/heads/release $CODELOAD/$COMMIT " "it downloaded nothing again: not the model, not the engine"
same "$(ls -A "$DATA/builds/$IR/failed")" "" "the build that passed left failed/"
[ -f "$DATA/builds/$IR/serving" ] && ok "serving is written" || bad "no serving"

printf 'yes\nyes\n' > "$W/answers"
HOME="$H" AU_TTY="$W/answers" /bin/bash "$DATA/bin/auster" remove > "$W/out" 2>&1; RC=$?
same "$RC" 0 "auster remove, yes twice: exit 0"
same "$(ls "$STUB_LAUNCHCTL_DIR/loaded")" "" "auster remove: neither job is loaded"
same "$(snapshot "$H")" "$home0" "auster remove: the home folder as it was before the install"
done_
