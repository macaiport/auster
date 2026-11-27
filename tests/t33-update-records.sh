# T33, the update's half (U5; D3.6 step 5, D3.1, A5): the records after an update to a new build, read back by common/
# auster's readers. On a Mac serving order 2 with order 1 waiting: after one whose candidate fails its test, serving and
# kept/ are as they were (the stamp follows U4's rule for a recipe not updated, and is not asserted here). After one whose
# server check fails (the new build answering HTTP 500 on the household's port; release at v0.3.0), serving names order 1
# with a speed of 0, kept/ holds order 2's descriptor byte for byte, and no stamp is written. After one that passes
# (release at v0.4.0), the stamp names v0.4.0 and its commit, serving names order 1 with the speed the server check
# measured, and kept/ holds order 2's descriptor byte for byte, named by the date and the build. Killed between the
# switch's two writes (a stand-in mv that kills the update at the second of them): the old build still has a descriptor,
# kept/'s copy of it, and serving is still order 2's.
# Mutants: tests/mutants/T33b (replace serving before copying the old descriptor to kept/), T33c (an update writes kept/
# and serving before the test; T33a is the install's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept"
reads() { # -> what common/auster's readers make of the stamp, serving and kept/
  ( . "$ROOT/common/auster"; AU_DATA=$DATA
    if au_line_read "$DATA/_update/scripts" 4; then echo "stamp ${AU_LF[1]} ${AU_LF[2]}"; else echo "stamp none"; fi
    if au_serving_read "$IR"; then echo "serving $AU_SV_BUILD $AU_SV_PEOPLE $AU_SV_CONTEXT $AU_SV_SPEED"; else echo "serving none"; fi
    for f in "$K"/*; do
      [ -e "$f" ] || continue
      if au_entry_read "$f"; then echo "kept $AU_SV_BUILD $AU_SV_SPEED"; else echo "kept unreadable ${f##*/}"; fi
    done )
}
fresh() { waiting_b1; rm -rf "$K"/* "$DATA/builds/$IR"/failed/*; s0=$(cat "$S"); }
kept_is_old() { # LABEL -> kept/ holds one entry, the old serving byte for byte, named by the date and its build
  local k
  k=$(ls "$K")
  [[ $k =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z-$IB2$ ]] && ok "$1: one entry in kept/, named by the date and order 2" || bad "$1: kept/ holds [$k]"
  same "$(cat "$K/$k" 2>/dev/null)" "$s0" "$1: ...order 2's descriptor, byte for byte"
}

# --- the candidate fails its test
fresh
engine_set "port=$CPORT" answers "$FX/answers-bad"
update_run $'yes\n'
same "$RC" 3 "a candidate that fails its test: exit 3"
same "$(cat "$S"):$(ls "$K")" "$s0:" "  ...serving and kept/ as they were"
engine_set "port=$CPORT" answers "$FX/answers-good"

# --- the server check fails after the switch
fresh
release_at v0.3.0 "$COMMIT2"
engine_set "alias=$IB1,port=8484" behaviour http500
st0=$(cat "$DATA/_update/scripts")
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "a switch whose server check fails: exit 4"
same "$(reads)" "stamp $(cut -f3,4 <<< "$st0" | tr '\t' ' ')
serving $IB1 4 32768 0
kept $IB2 36.9" "  ...serving names order 1 with a speed of 0, and kept/ order 2"
same "$(cat "$DATA/_update/scripts")" "$st0" "  ...no stamp written"
kept_is_old "  ...after the failed check"
engine_set "alias=$IB1,port=8484" behaviour ok

# --- an update that passes
fresh
release_at v0.4.0 1f2e3d4c5b6a79881726354a5b6c7d8e9f0a1b2c
update_run $'yes\n'
same "$RC" 0 "an update that passes: exit 0"
same "$(reads)" "stamp v0.4.0 1f2e3d4c5b6a79881726354a5b6c7d8e9f0a1b2c
serving $IB1 4 32768 36.9
kept $IB2 36.9" "  ...the stamp of v0.4.0, serving order 1 with the speed measured, kept/ order 2"
kept_is_old "  ...after the pass"

# --- killed between the two writes of the switch
fresh
mkdir -p "$W/fakebin"
cat > "$W/fakebin/mv" <<EOF
#!/bin/bash
case "\${!#}" in
  "$S"|"$K"/*)
    n=\$(cat "$W/mv-calls" 2>/dev/null || echo 0); n=\$((n + 1)); echo "\$n" > "$W/mv-calls"
    if [ "\$n" = 2 ]; then kill -9 "\$PPID"; exit 1; fi ;;
esac
exec /bin/mv "\$@"
EOF
chmod 755 "$W/fakebin/mv"
rm -f "$W/mv-calls"
PATH="$W/fakebin:$PATH" update_run $'yes\n'
same "$(cat "$W/mv-calls")" 2 "killed at the second of the switch's two writes"
[ "$RC" -ne 0 ] && [ "$RC" -ne 3 ] && [ "$RC" -ne 4 ] && ok "  ...the update did not finish (exit $RC)" || bad "  ...the update ended with exit $RC"
same "$(reads | tail -n +2)" "serving $IB2 4 32768 36.9
kept $IB2 36.9" "  ...the old build still has a descriptor: serving is still order 2's, and kept/ holds it"
kept_is_old "  ...killed between the two writes"
done_
