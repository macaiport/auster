# T108: install, `auster remove`, install again (B3 step 12, B8). An `auster stop` leaves the engine's label
# disabled and builds/stopped; `auster remove` then leaves neither label disabled in the stub launchctl's list
# (launchctl print-disabled) and builds/stopped gone. A label left disabled from before (an `auster stop` whose
# data root was then deleted by hand) does not stop the second install: it loads both jobs, and its server
# answers. Mutants: tests/mutants/T108a and T108b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up
auster stop
same "$RC" 0 "auster stop"
same "$(override "$EJOB")" disabled "the engine's label is disabled"
[ -e "$DATA/builds/stopped" ] && ok "builds/stopped is written" || bad "no builds/stopped"

ANSWERS=$'yes\nno\n' auster remove
same "$RC" 0 "remove, the files kept"
pd=$(launchctl print-disabled "gui/$UIDN")
printf '%s\n' "$pd" | grep -F -e "\"$EJOB\" => disabled" -e "\"$CJOB\" => disabled" && bad "a label is left disabled" || ok "after the remove, launchd's list holds neither label as disabled"
[ -e "$DATA/builds/stopped" ] && bad "builds/stopped is left" || ok "builds/stopped is gone"
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "remove, the files deleted"
[ -e "$DATA" ] && bad "the data root is left" || ok "the data root is gone"

launchctl disable "gui/$UIDN/$EJOB"   # left disabled from before
rm -rf "$STUB_CURL_DIR/requests"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the second install passes"
loaded "$EJOB" && loaded "$CJOB" && ok "it loads both jobs" || bad "loaded: $(ls "$STUB_LAUNCHCTL_DIR/loaded")"
same "$(override "$EJOB")" enabled "the engine's label is enabled again"
says "The server answered" "its server check passed"
same "$(ask_engine "$(key_of ipad)")" 200 "its server answers the new device key"
done_
