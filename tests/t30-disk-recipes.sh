# T30 (U6; C6, D3.1, D3.6 steps 3 and 6): recipe A's disk rule never removes a file that recipe B's descriptors name, and
# a file already in store/ is not fetched again. Four parts:
#   - the disk holdings, made by common/auster's au_holdings (the update's and `auster cleanup`'s) and by the rule file's own
#     copy, _auu_holdings, are one output on the records of two recipes (tests/fixtures/records/two) with a download cut
#     short, a file in store/ and a folder in engines/ that no descriptor names;
#   - on those records, `auster cleanup` with several recipes and none named exits 2 and removes nothing;
#   - `auster cleanup` for recipe A with no disk free: A's kept build (whose old model B's serving names) and A's failed
#     build (whose engine B's kept build names) free nothing and are not named; a failed build added to A, with an engine
#     archive of its own and B's template, is named, and removed on a yes with its own engine, while B's template and every
#     file B's descriptors name stay;
#   - an update of the household recipe beside a second recipe, Z, whose serving names model A and a template of its own:
#     order 1, waiting, needs model A, which Z's serving has put in store/, so the question says nothing is downloaded and
#     nothing is asked of Hugging Face; a kept build of the household recipe that names Z's template beside a model file of
#     its own is the one the disk rule names, a KiB short of the floor, and is removed on the yes while Z's template and
#     Z's serving stay (exit 3: Z, which the tree's registry does not know, is passed over).
# Mutants: tests/mutants/T30a (remove by recipe folder: a removed build's files kept only when its own recipe names them),
# T30b (the disk rule counts a file another recipe's descriptor names as free), T30c (fetch a file store/ already holds).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
RA=rapdsanqlj2eu RB=rkfbt7hbg4kzw                   # tests/fixtures/records: recipes A and B
FA=bvuefucqhcs35 KA=byvlad4zog2kq FA2=bsxouvqegcxbo  # A's failed and kept builds, and one more failed (minted for T30)
RZ=rzl423ljlgvwf BZ=bruwgstcula7d BKZ=brcwsje7x75pc  # recipe Z, its build, and a household build kept (minted for T30)
update_install

# --- the two copies of the disk holdings
root2() { # DIR -> a home in DIR whose data root holds the records of two recipes, with bin/auster and section C's programs
  local h="$1/home" d="$1/home/Library/Application Support/Auster" f
  mkdir -p "$h/Library/Application Support"
  records_fixture two "$d"
  mkdir -m 700 "$d/bin" "$d/jobs" "$d/keys" "$d/logs"
  cp "$ROOT/common/auster" "$d/bin/auster"; chmod 755 "$d/bin/auster"
  for f in capability.js capability-lib.js registry-lib.js; do cp "$ROOT/common/$f" "$d/jobs/$f"; chmod 644 "$d/jobs/$f"; done
}
root2 "$W/one"; D1="$W/one/home/Library/Application Support/Auster"
printf 'part of a model\n' > "$D1/store/$(printf '%064d' 7).part"
printf 'a file no descriptor names\n' > "$D1/store/$(printf '%064d' 8)"; chmod 444 "$D1/store/$(printf '%064d' 8)"
mkdir -p "$D1/engines/$(printf '%064d' 9)/root"; printf 'x\n' > "$D1/engines/$(printf '%064d' 9)/root/f"
h1=$( . "$ROOT/common/auster"; AU_DATA=$D1; au_holdings ); r1=$?
h2=$( AU_UPDATE_DIR="$D1/_update"; . "$ROOT/common/updates.sh"; _auu_holdings "$W/one/h2" && cat "$W/one/h2" ); r2=$?
same "$r1:$r2" "0:0" "the disk holdings of two recipes, made by both copies"
same "$h1" "$h2" "  ...au_holdings (the update's and cleanup's) and the rule file's _auu_holdings give one output"
same "$(printf '%s\n' "$h1" | cut -f1 | sort | uniq -c | awk '{ printf "%s %s ", $1, $2 }')" "1 auster-disk 5 desc 15 file 1 partial " \
  "  ...with every kind of line: 5 descriptors, 15 files and folders (a file and a folder that nothing names among them), a download cut short"

# --- auster cleanup on the records of two recipes
root2 "$W/two"; H2="$W/two/home" D2="$W/two/home/Library/Application Support/Auster"
auster2() { # ARG... -> bin/auster in the two recipes' data root, answered from ANSWERS; output in $W/out, exit code in RC
  printf '%s' "${ANSWERS:-}" > "$W/answers"
  HOME="$H2" AU_TTY="$W/answers" /bin/bash "$D2/bin/auster" "$@" > "$W/out" 2>&1
  RC=$?
}
snap2() { snapshot "$D2" | grep -v -E $'\tlogs(/|$)'; }
before=$(snap2)
AU_DISK_FREE_BYTES=0 ANSWERS=$'yes\n' auster2 cleanup
same "$RC" 2 "auster cleanup, two recipes and none named: exit 2"
outsays "This Mac serves more than one recipe ($RA, $RB): name one, as in \`auster cleanup $RA\`." "  ...it says to name one"
same "$(snap2)" "$before" "  ...and removes nothing"
AU_DISK_FREE_BYTES=0 ANSWERS=$'no\n' auster2 cleanup "$RA"
same "$RC" 0 "recipe A with no disk free: exit 0"
outsays "nothing Auster may remove would free any of it" "  ...its kept and failed builds free nothing (their files B's descriptors name), so none is named"
same "$(snap2)" "$before" "  ...nothing removed"

E3=$(printf 'an engine archive only A names\n' | shasum -a 256 | cut -c1-64)
printf 'an engine archive only A names\n' > "$D2/store/$E3"; chmod 444 "$D2/store/$E3"
mkdir -p "$D2/engines/$E3/root"; printf 'x\n' > "$D2/engines/$E3/root/f"
TB=$(sed -n 2p "$D2/builds/$RB/serving" | cut -f5)   # B's template, which B's serving and B's kept build name
awk -F'\t' -v OFS='\t' -v b="$FA2" -v t="$TB" -v e="$E3" 'NR == 2 { $2 = b; $5 = t } NR == 3 { $7 = e } { print }' \
  "$D2/builds/$RA/failed/2026-11-22T10:00:00Z-$FA" > "$D2/builds/$RA/failed/2026-11-23T10:00:00Z-$FA2"
chmod 600 "$D2/builds/$RA/failed/2026-11-23T10:00:00Z-$FA2"
named_by_b() { for f in "$D2/builds/$RB/serving" "$D2/builds/$RB"/kept/*; do sed -n 2p "$f" | cut -f5-7; sed -n 3,4p "$f" | cut -f7; done | tr '\t' '\n' | sort -u; }
b_files() { local s; for s in $(named_by_b); do [ -f "$D2/store/$s" ] && [ "$(shasum -a 256 < "$D2/store/$s" | cut -c1-64)" = "$s" ] || echo "missing $s"; done; }
AU_DISK_FREE_BYTES=0 ANSWERS=$'yes\n' auster2 cleanup "$RA"
same "$RC" 0 "A with a failed build that names B's template beside an engine of its own, answered yes: exit 0"
outsays "  build $FA2, which failed its test here on 2026-11-23;" "  ...that build is named"
grep -qF -e "build $FA," -e "build $KA," "$W/out" && bad "  ...a build that frees nothing was named: $(cat "$W/out")" || ok "  ...A's other builds, freeing nothing, are not"
outsays "Removed build $FA2, which failed its test here on 2026-11-23, to make room." "  ...and it is removed"
[ -e "$D2/store/$E3" ] || [ -e "$D2/engines/$E3" ] && bad "  ...its own engine is still there" || ok "  ...with its own engine, archive and folder"
[ -f "$D2/store/$TB" ] && ok "  ...B's template stays" || bad "  ...B's template was removed"
same "$(b_files)" "" "  ...every file B's descriptors name stays, whole"
[ -f "$D2/builds/$RA/kept/2026-11-20T10:00:00Z-$KA" ] && [ -f "$D2/builds/$RA/failed/2026-11-22T10:00:00Z-$FA" ] &&
  ok "  ...A's kept and failed builds stay" || bad "  ...one of A's other builds was removed"

# --- an update beside a second recipe
waiting_b1   # the household recipe serves order 2; order 1 waiting; model A out of store/
cp "$FX/models/standin-a.gguf" "$DATA/store/$SA"; chmod 444 "$DATA/store/$SA"   # put there by Z's serving, which names it
TZ=$(printf 'recipe Z template\n' | shasum -a 256 | cut -c1-64)
printf 'recipe Z template\n' > "$DATA/store/$TZ"; chmod 444 "$DATA/store/$TZ"
{ printf 'a model file only a kept build names\n'; head -c 4000 /dev/zero | tr '\0' m; } | head -c 4000 > "$W/x"
X=$(shasum -a 256 < "$W/x" | cut -c1-64); mv "$W/x" "$DATA/store/$X"; chmod 444 "$DATA/store/$X"
mkdir -m 700 "$DATA/builds/$RZ" "$DATA/builds/$RZ/kept"
list=$(sed -n 5p "$W/pristine/builds/$IR/serving" | cut -f5)
awk -F'\t' -v OFS='\t' -v b="$BZ" -v t="$TZ" -v l="$list" 'NR == 2 { $2 = b; $5 = t } NR == 5 { $2 = 1; $3 = 8192; $4 = 8485; $5 = l; $6 = "40.1" } { print }' \
  "$W/pristine/builds/$IR/serving" > "$DATA/builds/$RZ/serving"
chmod 600 "$DATA/builds/$RZ/serving"
KZ="$DATA/builds/$IR/kept/2026-11-20T10:00:00Z-$BKZ"
awk -F'\t' -v OFS='\t' -v b="$BKZ" -v t="$TZ" -v m="$X" 'NR == 2 { $2 = b; $5 = t } NR == 4 { $7 = m } { print }' "$DATA/builds/$IR/serving" > "$KZ"
chmod 600 "$KZ"
z0=$(cat "$DATA/builds/$RZ/serving")
engine_up
rm -rf "$STUB_CURL_DIR/requests"
# df -k of a 1 TB volume (976,562,500 KiB; the floor is 48,828,125 KiB): a KiB short of the floor while the kept build's own
# model file is there, and three KiB above it once it is gone, as a real df would say after the removal
mkdir -p "$W/fakebin"
{ printf '#!/bin/bash\nif [ -e %q ]; then a=48828124; else a=48828128; fi\n' "$DATA/store/$X"
  printf '%s\n' "printf 'Filesystem   1024-blocks       Used Available Capacity iused      ifree %%iused  Mounted on\\n/dev/disk3s1   976562500  927734375 %9s    95%% 2560778 2893107240    0%%   /System/Volumes/Data\\n' \"\$a\""; } > "$W/fakebin/df"
chmod 755 "$W/fakebin/df"
unset AU_DISK_FREE_BYTES AU_DISK_TOTAL_BYTES
PATH="$W/fakebin:$PATH" update_run $'yes\n'
same "$RC" 3 "an update of the household recipe beside recipe Z, a KiB short of the floor: exit 3 (Z passed over)"
says "Download    Nothing: the files it needs are already on this Mac." "  ...the question: model A, which Z's serving put in store/, is not downloaded"
same "$(requests | grep -cE 'huggingface|cdn\.example')" 0 "  ...nothing asked of Hugging Face or its CDN"
says "build $BKZ, kept since 2026-11-20: the one before the build in use" "  ...the kept build that names Z's template is named"
says "Removed build $BKZ, kept since 2026-11-20, to make room." "  ...and removed on the yes"
[ -e "$KZ" ] || [ -e "$DATA/store/$X" ] && bad "  ...the kept entry or its own model is still there" || ok "  ...with its own model file"
[ -f "$DATA/store/$TZ" ] && ok "  ...Z's template stays" || bad "  ...Z's template was removed"
same "$(cat "$DATA/builds/$RZ/serving")" "$z0" "  ...Z's serving as it was"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB1" "  ...order 1 serves the household recipe"
done_
