# T111 (U5; A5, B3 step 13, B5): serving's launch line holds 0 for the writing speed from a switch until a server check
# writes the rate the stub engine reports for the speed question (41.7 here, every other question 12.5), by rename. The
# engine job starts on a speed of 0. A switch whose check fails leaves 0, and while it is 0: `auster status` says the
# build has not passed a check, that `auster restart` checks it, and, with an entry in kept/, that `auster rollback` goes
# back; the probe reports no `slow` however low the rate; and it notifies at the first `failed`, in a sentence that names
# `auster rollback` with kept/ not empty and `auster status` with it empty, never `auster restart`. `auster restart`'s
# passed check then writes the speed. (The baseline it becomes is the check job's, T77; T60's side-by-side clause is U5's
# second half.) Mutants: tests/mutants/T111a (the engine job refuses a 0), T111b (the probe reports slow against 0), T111c
# (write the speed in place), T111d (take the speed from another question), T111e (wait for a second failure at 0).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
export AU_CHECK_LIMIT=3
engine_up
S="$DATA/builds/$IR/serving"
speed() { sed -n 5p "$S" | cut -f6; }
printf 'Count from 1 to\t1\\n2\\n3\t41.7\t0\n*\tok\t12.5\t0\n' > "$W/answers-rates"
engine_set '*' answers "$W/answers-rates"

i0=$(stat -f %i "$S")
ANSWERS=$'yes\n' auster people 2
same "$RC" 0 "a switch, the engine job starting on a speed of 0, and its check passed: exit 0"
same "$(speed)" 41.7 "the check wrote the rate of the speed question, not of another"
[ "$(stat -f %i "$S")" != "$i0" ] && ok "  ...by rename" || bad "  ...serving was written in place"

engine_set 'ctx=98304' behaviour http500
AU_SERVER_CHECK_SECS=4 ANSWERS=$'yes\n' auster people 3
same "$RC" 4 "a switch whose check is not answered: exit 4"
same "$(speed)" 0 "  ...serving holds 0 for the speed"
same "$(sed -n 's/^code	//p' "$DATA/builds/$IR/start")" starting "  ...and the engine job started on it"

auster status
outsays "It has not passed a server check since the switch: \`auster restart\` checks it." "status at 0: not yet checked, and auster restart checks it"
outsays "\`auster rollback\` goes back to what it served before, with no download." "  ...with an entry in kept/, auster rollback goes back"
mkdir "$W/kept-aside"; mv "$DATA/builds/$IR"/kept/* "$W/kept-aside/"
auster status
grep -q 'auster rollback' "$W/out" && bad "  ...with kept/ empty it names auster rollback" || ok "  ...with kept/ empty it does not name auster rollback"
mv "$W/kept-aside"/* "$DATA/builds/$IR/kept/"

told() { # LABEL SENTENCE-PART
  same "$(notes)" 1 "$1: one notification, at the first run"
  case "$(last_note)" in *"$2"*) ok "$1: it names $2" ;; *) bad "$1: the notification: $(last_note)" ;; esac
  case "$(last_note)" in *restart*) bad "$1: it names auster restart" ;; *) ok "$1: it does not name auster restart" ;; esac
}
rm -f "$DATA/_update/engine"; : > "$STUB_NOTIFY_LOG"
check_job
same "$(probe_field probe)" failed "the probe at 0, the engine answering HTTP 500: failed, not broken"
told "the probe at 0, an entry in kept/" "auster rollback"
mv "$DATA/builds/$IR"/kept/* "$W/kept-aside/"
rm -f "$DATA/_update/engine"; : > "$STUB_NOTIFY_LOG"
check_job
told "the probe at 0, kept/ empty" "auster status"
mv "$W/kept-aside"/* "$DATA/builds/$IR/kept/"
engine_live 8484 behaviour ok; engine_live 8484 answers ''; engine_live 8484 rate 1
check_job
same "$(probe_field probe 1) $(probe_field probe 2)" "ok 1" "the probe at 0, the engine writing 1 token a second: ok, never slow"

engine_set 'ctx=98304' behaviour ok
i1=$(stat -f %i "$S")
auster restart
same "$RC" 0 "auster restart, the engine answering: exit 0"
same "$(speed)" 41.7 "  ...its check wrote the speed of the speed question"
[ "$(stat -f %i "$S")" != "$i1" ] && ok "  ...by rename" || bad "  ...serving was written in place"
auster status
grep -q 'has not passed a server check' "$W/out" && bad "  ...status still says not checked" || ok "  ...and status no longer says it is not checked"
done_
