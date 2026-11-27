# T33, the installer's half (U2; B3 steps 10 to 15, D3.1): after an install that passed, the stamp names the line,
# the version and the commit, with the time; `serving` reads as a descriptor of the build chosen, with the speed the
# server check measured; kept/ is there and empty (nothing served before). After one whose build failed its test:
# no `serving` and no stamp, and the descriptor in failed/, named by the date and the build, with a speed of 0.
# After one whose server check failed: `serving` names the build with a speed of 0, kept/ is empty, and no stamp is
# written. Each record read back by common/auster's readers. The update's half, and a run killed between the two
# writes of a switch, are U5's. Mutant: tests/mutants/T33a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
reads() { # -> what common/auster's readers make of this data root: the stamp, serving, kept/ and failed/
  ( . "$ROOT/common/auster"; AU_DATA=$DATA
    if au_line_read "$DATA/_update/scripts" 4; then printf 'stamp %s %s %s %s\n' "${AU_LF[0]}" "${AU_LF[1]}" "${AU_LF[2]}" "$( [[ ${AU_LF[3]} =~ $AU_RE_UTC ]] && echo utc)"
    else echo "stamp none"; fi
    if au_serving_read "$IR"; then echo "serving $AU_SV_BUILD $AU_SV_PEOPLE $AU_SV_CONTEXT $AU_SV_SPEED"; else echo "serving none"; fi
    printf 'kept %s\n' "$( [ -d "$DATA/builds/$IR/kept" ] && ls -A "$DATA/builds/$IR/kept" | wc -l | tr -d ' ' || echo none)"
    for f in "$DATA/builds/$IR"/failed/*; do
      [ -e "$f" ] || continue
      if au_entry_read "$f"; then echo "failed $AU_SV_BUILD $AU_SV_SPEED"; else echo "failed unreadable ${f##*/}"; fi
    done )
}

# A build that fails its test (the candidate's port answers badly)
engine_set 'port=18484' answers "$FX/answers-bad"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "a failed test: exit 5"
same "$(reads)" "stamp none
serving none
kept none
failed $IB1 0" "a failed test: no stamp, no serving, and the build in failed/ with a speed of 0"

# The same Mac, its engine now passing: an install that passes, and the failed entry gone (B3, V5)
engine_set 'port=18484' answers "$FX/answers-good"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the install passes: exit 0"
same "$(reads)" "stamp release v0.1.0 $COMMIT utc
serving $IB1 4 32768 36.9
kept 0" "a passed install: the stamp, serving with the measured speed, kept/ empty, failed/ empty"
same "$(stat -f %Lp "$DATA/builds/$IR/serving")" 600 "serving has mode 0600"

# A first install whose server check is not answered (the engine job's engine never listens), on another home
launchctl bootout "gui/$(id -u)/local.auster.engine"
install_env
engine_set 'port=8484' behaviour nolisten
AU_SERVER_CHECK_SECS=4 run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 4 "a server check not answered: exit 4"
same "$(reads)" "stamp none
serving $IB1 4 32768 0
kept 0" "a failed server check: serving names the build with a speed of 0, kept/ empty, no stamp"
done_
