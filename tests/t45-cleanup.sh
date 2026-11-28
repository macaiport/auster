# T45 (U6; D3.6 step 6, C6, B6): `auster cleanup` lists what it would remove and removes nothing on a no. On a Mac serving
# order 2, with a download of model A cut short (store/<sha256>.part), order 1's template left in store/ by a build no longer
# kept (no descriptor names it), a failed build and a kept one, each with a model file of its own: with disk to spare it
# lists the download and the file no build names, and no earlier build, which all stay (AD7); with no disk free it lists
# the failed build, then the kept one, said to be the one before the build in use, and says the Mac stays short. Answered
# no, each time: exit 1, and the data root as it was. While builds/stopped exists it works, as `unhold` does, since it
# starts and stops nothing: answered yes with disk to spare, it removes the download and the file no build names, and every
# earlier build stays; run again, there is nothing to remove (exit 0). A kept entry that cannot be read makes it refuse and
# remove nothing, since the files no descriptor names can no longer be told (D3.3).
# Mutants: tests/mutants/T45a (remove before asking), T45b (refuse while builds/stopped exists), T45c (go on when a
# descriptor cannot be read).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
BF=byo3qohhfuqvi BK=bth7tigeg4dtc   # a failed build and a kept one (minted for T45 and T17)
update_install
waiting_b1   # serving order 2; model A out of store/; nothing kept, so order 1's template is named by nothing
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept" F="$DATA/builds/$IR/failed"
T1=$(sed -n 2p "$W/pristine/builds/$IR/serving" | cut -f5) T1Z=$(stat -f %z "$DATA/store/$(sed -n 2p "$W/pristine/builds/$IR/serving" | cut -f5)")
head -c 1000 "$FX/models/standin-a.gguf" > "$DATA/store/$SA.part"; chmod 600 "$DATA/store/$SA.part"
blob() { # BYTES TAG -> a file of BYTES bytes in store/, named by its sha256, which is printed; read-only
  { printf '%s\n' "$2"; head -c "$1" /dev/zero | tr '\0' x; } | head -c "$1" > "$W/blob"
  local s; s=$(shasum -a 256 < "$W/blob" | cut -c1-64)
  mv "$W/blob" "$DATA/store/$s"; chmod 444 "$DATA/store/$s"; printf '%s' "$s"
}
commas() { printf '%s\n' "$1" | sed -E -e :a -e 's/^([0-9]+)([0-9]{3})/\1,\2/' -e ta; }
Y=$(blob 500 'a failed model file') X=$(blob 700 'a kept model file')
mkdir -p -m 700 "$F"
awk -F'\t' -v OFS='\t' -v b="$BF" -v m="$Y" 'NR == 2 { $2 = b } NR == 4 { $7 = m } { print }' "$S" > "$F/2026-11-21T10:00:00Z-$BF"
awk -F'\t' -v OFS='\t' -v b="$BK" -v m="$X" 'NR == 2 { $2 = b } NR == 4 { $7 = m } { print }' "$S" > "$K/2026-11-20T10:00:00Z-$BK"
chmod 600 "$F"/* "$K"/*
PART="  store/$SA.part, a download cut short (1,000 bytes);"
SPARE="  store/$T1 ($T1Z bytes), which no build names;"
before=$(data_snap)

# --- disk to spare (install_env: 500 GB free of 1 TB)
ANSWERS=$'no\n' auster cleanup
same "$RC" 1 "disk to spare, answered no: exit 1"
outsays "This Mac has 500.0 GB free, and Auster keeps at least 50.0 GB free. This removes:" "  ...it says what is free and what Auster keeps"
outsays "$PART" "  ...it lists the download cut short"
outsays "$SPARE" "  ...and the file no build names"
outsays "Every earlier build stays: with these gone, this Mac has room for them." "  ...and that every earlier build stays"
grep -qF -e "build $BF" -e "build $BK" "$W/out" && bad "  ...it named an earlier build: $(cat "$W/out")" || ok "  ...it names no earlier build"
outsays "Remove them? [yes/no]" "  ...it asks"
outsays "Nothing was removed." "  ...and on the no says nothing was removed"
same "$(data_snap)" "$before" "  ...the data root as it was"

# --- no disk free
AU_DISK_FREE_BYTES=0 ANSWERS=$'no\n' auster cleanup
same "$RC" 1 "no disk free, answered no: exit 1"
outsays "$PART" "  ...the download cut short"
outsays "  build $BF, which failed its test here on 2026-11-21;" "  ...the failed build"
outsays "  build $BK, kept since 2026-11-20: the one before the build in use, so \`auster rollback\` could no longer go back to it;" \
  "  ...then the kept one, said to be the one before the build in use"
[ "$(grep -n "build $BF" "$W/out" | cut -d: -f1)" -lt "$(grep -n "build $BK" "$W/out" | cut -d: -f1)" ] && ok "  ...the failed build first" || bad "  ...the kept build listed first"
outsays "That frees $(commas $((1000 + T1Z + 500 + 700))) bytes." "  ...what it frees"
outsays "Even with all of it gone, this Mac has less free than Auster keeps free." "  ...and that the Mac stays short"
same "$(data_snap)" "$before" "  ...the data root as it was"

# --- while builds/stopped exists, answered yes with disk to spare
printf 'auster-record 1\thousehold\t2026-11-27T08:00:00Z\n' > "$DATA/builds/stopped"; chmod 600 "$DATA/builds/stopped"
ANSWERS=$'yes\n' auster cleanup
same "$RC" 0 "builds/stopped exists, answered yes: exit 0"
outsays "Removed store/$SA.part, a download cut short." "  ...it removes the download cut short"
outsays "Removed store/$T1, which no build names." "  ...and the file no build names"
[ -e "$DATA/store/$SA.part" ] || [ -e "$DATA/store/$T1" ] && bad "  ...one is still there" || ok "  ...both are gone"
[ -f "$F/2026-11-21T10:00:00Z-$BF" ] && [ -f "$K/2026-11-20T10:00:00Z-$BK" ] && [ -f "$DATA/store/$X" ] && [ -f "$DATA/store/$Y" ] &&
  ok "  ...every earlier build stays, with its files" || bad "  ...an earlier build was removed"
[ -f "$DATA/builds/stopped" ] && ok "  ...and builds/stopped is left as it was" || bad "  ...builds/stopped was removed"
rm -f "$DATA/builds/stopped"
ANSWERS= auster cleanup
same "$RC" 0 "run again with disk to spare: exit 0"
outsays "There is nothing to remove: this Mac has 500.0 GB free, above the 50.0 GB Auster keeps free, so every earlier build stays." \
  "  ...nothing to remove"

# --- a kept entry that cannot be read
cp -p "$K/2026-11-20T10:00:00Z-$BK" "$W/kept-good"
printf 'launch\tnot a launch line\n' >> "$K/2026-11-20T10:00:00Z-$BK"
head -c 1000 "$FX/models/standin-a.gguf" > "$DATA/store/$SA.part"; chmod 600 "$DATA/store/$SA.part"
before=$(data_snap)
AU_DISK_FREE_BYTES=0 ANSWERS=$'yes\n' auster cleanup
same "$RC" 1 "a kept entry that cannot be read: exit 1"
outsays "A record of a build in builds/ cannot be read, so Auster cannot tell which files are still in use. Nothing was removed." "  ...it says why"
grep -qF "Remove them?" "$W/out" && bad "  ...it asked: $(cat "$W/out")" || ok "  ...it lists nothing and asks nothing"
same "$(data_snap)" "$before" "  ...nothing removed, not even the download cut short"
done_
