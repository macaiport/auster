# T17 (U6; D3.6 steps 3 and 6, C6, AD7), with T93's removal names used by the update and by `auster cleanup`. With disk
# to spare, earlier builds are kept: on a Mac serving order 2 with order 1 at two people in kept/, an update to order 1
# removes nothing and leaves two entries in kept/; `auster cleanup` then names nothing (every earlier build stays), and
# `auster rollback` goes back to the older entry and then to the other. With less disk, failed builds go first, then the
# oldest kept: with a failed build that names the model in use beside an engine archive of its own, and two kept builds
# each with a model file of its own, an update whose download is 2,500 bytes short of the floor names the failed build
# and the oldest kept one, not the newest; on a yes it removes exactly those two, with the files only they named, and
# every file the build in use names stays. The one before the build in use goes only on the person's yes: `auster
# cleanup`, a byte further short than the oldest kept build frees, names it as the one before the build in use, removes
# nothing on a no, and on a yes removes both, leaving every file of the build in use, which `auster verify` then passes.
# Mutants: tests/mutants/T17a (keep exactly one, whatever the disk), T17b (remove a file the build in use names when a
# removed build named it too), T17c (the one before the build in use not said to be so).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
BF1=bxwjrhxsa3cf3 BK1=bth7tigeg4dtc BK2=bhtuzk2cyzs2w   # a failed build and two kept ones (minted for this test)
FLOOR=50000000000                                     # 5% of install_env's 1 TB volume
update_install
waiting_b1   # serving order 2 for four at 32,768, model A not in store/
model_in "$IMB"
kept_put "$IB1" "$IMA" 2 32768 36.9 2026-11-19T10:00:00Z   # order 1 at two people, from before; its model in store/
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept" F="$DATA/builds/$IR/failed"
build() { sed -n 2p "$S" | cut -f2; }
setting() { sed -n 5p "$S" | cut -f2,3 | tr '\t' ' '; }
entries() { ls "$1" 2>/dev/null | sed -E 's/^[0-9T:-]{19}Z-//' | sort | tr '\n' ' '; }   # build ids, sorted
has() { [ -e "$DATA/$1" ]; }
pick() { # BUILD PEOPLE -> the number `auster rollback` lists that entry under (the list asked for and answered no)
  ANSWERS=$'no\n' auster rollback
  sed -n "s/^  \([0-9]*\)  build $1 ([^)]*), $2 people .*/\1/p" "$W/out"
}

# --- disk to spare (install_env: 500 GB free of 1 TB)
update_run $'yes\n'
same "$RC" 0 "disk to spare: the update to order 1, exit 0"
says_not "To make room" "  ...it names no earlier build to remove"
says_not "Removed build" "  ...and removes none"
same "$(build) $(setting)" "$IB1 4 32768" "  ...order 1 serves"
same "$(entries "$K")" "$IB2 $IB1 " "  ...both earlier entries are in kept/: order 1 at two people, and order 2"
ANSWERS= auster cleanup
same "$RC" 0 "auster cleanup with disk to spare: exit 0"
outsays "There is nothing to remove: this Mac has 500.0 GB free, above the 50.0 GB Auster keeps free, so every earlier build stays." \
  "  ...it says every earlier build stays"
same "$(entries "$K")" "$IB2 $IB1 " "  ...kept/ as it was"
n=$(pick "$IB1" 2)
ANSWERS="$n"$'\n' auster rollback
same "$RC:$(build) $(setting)" "0:$IB1 2 32768" "auster rollback picks the older entry, order 1 at two people (number $n)"
n=$(pick "$IB2" 4)
ANSWERS="$n"$'\n' auster rollback
same "$RC:$(build) $(setting)" "0:$IB2 4 32768" "auster rollback then picks the other, order 2 (number $n)"

# --- less disk: on order 2, order 1 waiting with 3,400 bytes to fetch, and three earlier builds
ANSWERS= auster unhold
rm -f "$K"/* "$F"/*
chmod 644 "$DATA/store/$SA"; rm -f "$DATA/store/$SA"
blob() { # BYTES TAG -> a file of BYTES bytes in store/, named by its sha256, which is printed; read-only
  { printf '%s\n' "$2"; head -c "$1" /dev/zero | tr '\0' x; } | head -c "$1" > "$W/blob"
  local s; s=$(shasum -a 256 < "$W/blob" | cut -c1-64)
  mv "$W/blob" "$DATA/store/$s"; chmod 444 "$DATA/store/$s"; printf '%s' "$s"
}
desc_as() { # SOURCE DEST BUILD ENGINE-SHA MODEL-SHA -> SOURCE's descriptor as BUILD's, with that engine and model (- keeps one)
  awk -F'\t' -v OFS='\t' -v b="$3" -v e="$4" -v m="$5" 'NR == 2 { $2 = b } NR == 3 && e != "-" { $7 = e } NR == 4 && m != "-" { $7 = m } { print }' "$1" > "$2"
  chmod 600 "$2"
}
E2=$(blob 1000 'an older engine archive') X1=$(blob 2000 'an older model file') X2=$(blob 3000 'a newer model file')
mkdir -p -m 700 "$F"
desc_as "$S" "$F/2026-11-10T10:00:00Z-$BF1" "$BF1" "$E2" -                            # failed: model B, the one in use
desc_as "$W/pristine/builds/$IR/serving" "$K/2026-11-14T10:00:00Z-$BK1" "$BK1" - "$X1"   # kept, the oldest
desc_as "$W/pristine/builds/$IR/serving" "$K/2026-11-16T10:00:00Z-$BK2" "$BK2" - "$X2"   # kept, the newest
T2=$(sed -n 2p "$S" | cut -f5)   # order 2's template, which only the build in use and the failed build name
export AU_DISK_FREE_BYTES=$((FLOOR + 3400 - 2500))
update_run $'yes\n'
same "$RC" 0 "2,500 bytes short: the update to order 1, exit 0"
says "Removed     To make room, these earlier builds are removed" "  ...the question names builds to remove"
says "build $BF1, which failed its test here on 2026-11-10;" "  ...the failed build first"
says "build $BK1, kept since 2026-11-14;" "  ...then the oldest kept"
says_not "build $BK2" "  ...not the newest kept, which the room does not need"
says "Removed build $BF1, which failed its test here on 2026-11-10, to make room." "  ...on the yes, the failed build removed"
says "Removed build $BK1, kept since 2026-11-14, to make room." "  ...and the oldest kept"
same "$(entries "$F"):$(entries "$K")" ":$IB2 $BK2 " "  ...failed/ empty; kept/ the newest kept and order 2, just left"
has "store/$E2" || has "store/$X1" && bad "  ...a file only they named is still there" || ok "  ...the files only they named are gone"
has "store/$X2" && ok "  ...the newest kept build's model stays" || bad "  ...the newest kept build's model was removed"
has "store/$SB" && has "store/$T2" && ok "  ...the files of the build in use, which the failed build named too, stay" ||
  bad "  ...a file of the build in use was removed"
same "$(build)" "$IB1" "  ...order 1 serves"

# --- the one before the build in use, only on the person's yes (auster cleanup)
export AU_DISK_FREE_BYTES=$((FLOOR - 3000))
before=$(data_snap)
ANSWERS=$'no\n' auster cleanup
same "$RC" 1 "auster cleanup 3,000 bytes short, answered no: exit 1"
outsays "  build $BK2, kept since 2026-11-16;" "  ...it names the oldest kept, whose 3,000 bytes are enough"
grep -qF "build $IB2" "$W/out" && bad "  ...it named the one before the build in use: $(cat "$W/out")" || ok "  ...and not the one before the build in use"
same "$(data_snap)" "$before" "  ...nothing removed"
export AU_DISK_FREE_BYTES=$((FLOOR - 3001))
ANSWERS=$'no\n' auster cleanup
same "$RC" 1 "3,001 bytes short, answered no: exit 1"
outsays "  build $BK2, kept since 2026-11-16;" "  ...the oldest kept first"
outsays ": the one before the build in use, so \`auster rollback\` could no longer go back to it;" \
  "  ...then order 2, said to be the one before the build in use"
same "$(data_snap)" "$before" "  ...nothing removed on the no"
ANSWERS=$'yes\n' auster cleanup
same "$RC" 0 "answered yes: exit 0"
same "$(entries "$K")" "" "  ...kept/ empty"
has "store/$X2" || has "store/$SB" || has "store/$T2" && bad "  ...a file only they named is still there" || ok "  ...the files only they named are gone"
ANSWERS= auster verify
same "$RC" 0 "  ...every file of the build in use stays: auster verify passes"
done_
