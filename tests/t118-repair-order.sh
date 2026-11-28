# T118 (U6, its third part; D3.6 "A changed file of the build in use is fetched again", "Order against B3 step 6",
# BD18), the repair's order against Auster's programs and a move; tests/t118-repair-refusals.sh holds the rest of T118.
# Each run is `install.sh update` (as the update's .command file runs it) with a release newer than the stamp, so that a
# step 15 would move the stamp. (vii) Auster's programs change in the run that repairs the template, the engine job (the
# real one, run by the stub launchctl's hook) answering only while the template's sha256 is serving's (engine-hash
# otherwise): one kickstart and one check, which passes and deletes jobs/previous/; the new programs in place, exit 0.
# (viii) The same with the model changed and its download cut short after the yes: every program in the data root byte
# for byte, no jobs/previous/, no kickstart, the stamp and _update/updates.sh byte for byte, the closing line "is not in
# place on this Mac yet", exit 3. (ix) A changed template with jobs/previous/ there from an earlier change never
# checked: repaired, then one kickstart and check, which deletes jobs/previous/, exit 0; with the template missing from
# the tree's assets/ instead, jobs/previous/ left, no kickstart, the stamp as it was, and with kept/ holding an earlier
# build `auster rollback` named with "run it twice", exit 3. (x) Side by side, a move to order 1 while the programs
# change, model B (order 2's, not shared) changed: the question's line "so that the build this Mac serves is whole
# before anything restarts it" with its size; a yes fetches it (its curl in the stub log before the first kickstart),
# then one kickstart for step 6 and one for the switch; the move completes, exit 0. (xi) The template changed and
# missing from the tree's assets/ while the programs change: passed over before the question, no programs-only question
# (its sentence instead), no program changed, no kickstart, the stamp as it was, exit 3. (xiii) The new bin/auster
# failing its trial run after a repair of the template: exit 3, the template whole in store/, no kickstart, "The files
# put back above stay whole". (xvi) A move carrying a repair of the model (model B missing) where the disk, after the
# repair's download, no longer holds the move's (a stand-in df whose free space is what store/ does not take): the
# repair completes and is checked, "The build this Mac serves is whole again, but what this Mac can hold changed since
# the question", exit 3. (xviii) A no to a move that carries a repair: the move's own words, exit 1, nothing changed.
# Mutants: tests/mutants/T118f (step 6 before the repair), T118g (change the programs after a repair that failed), T118h
# (au_update_check checks the server after a repair passed over or failed when jobs/previous/ is there), T118i (a move
# while the programs change that leaves the build in use as it is), T118j (change the programs in a run whose build in
# use was passed over with a changed file), T118p (judge the move's room once, before the repair, and move whatever the
# disk then holds); the others are tests/t118-repair-refusals.sh's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept" ST="$DATA/_update/scripts" P="$DATA/jobs/previous"
T1=$(sed -n 2p "$S" | cut -f5)   # order 1's template
REL=0
fresh() { # [ORDER...] -> release names a new commit, of version v0.2.<n>, whose tree is $ROOT's; TC its commit, T its source
  REL=$((REL + 1)) TC=$(printf '%040x' $((12288 + REL)))
  release_at "v0.2.$REL" "$TC" "$@"
  T="$FX/tree-src-$TC"
}
pack() { tree_archive "$T" "auster-$TC" "$TC" "$FX/tree-$TC.tar.gz"; }
new_programs() { printf '# a change in v0.2.%s\n' "$REL" >> "$T/common/auster"; pack; }   # Auster's programs differ
progs() { snapshot "$DATA/bin"; snapshot "$DATA/jobs"; }
progs_reset() { # -> $ROOT's programs put back in the data root, as an install leaves them, and no jobs/previous/
  cp "$ROOT/common/auster" "$DATA/bin/auster"; chmod 755 "$DATA/bin/auster"
  for p in auster-engine auster-check registry-lib.js capability-lib.js capability.js registry.js; do cp "$ROOT/common/$p" "$DATA/jobs/$p"; chmod 644 "$DATA/jobs/$p"; done
  cp "$ROOT/tools/mint-id" "$DATA/jobs/mint-id"; chmod 644 "$DATA/jobs/mint-id"
  rm -rf "$P"
}
previous_put() { mkdir -m 700 "$P"; cp -p "$DATA/bin/auster" "$DATA"/jobs/auster-* "$DATA"/jobs/*.js "$DATA/jobs/mint-id" "$P/"; }
sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
same_size() { # FILE -> its middle byte changed, at the same size, read-only as store/ keeps it
  local f=$1 n
  n=$(stat -f %z "$f")
  { head -c $((n / 2)) "$f"; printf 'X'; tail -c +$((n / 2 + 2)) "$f"; } > "$W/changed"
  chmod 644 "$f"; cat "$W/changed" > "$f"; chmod 444 "$f"
}
template_off() { chmod 644 "$DATA/store/$1"; printf '{# one more line #}\n' >> "$DATA/store/$1"; chmod 444 "$DATA/store/$1"; }
kicks() { job_calls "$1" | grep -o 'launchctl kickstart' | wc -l | tr -d ' '; }
mark() { N=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; ST0=$(cat "$ST" 2>/dev/null); U0=$(cat "$DATA/_update/updates.sh"); P0=$(progs); }
stamp_kept() { same "$(cat "$ST" 2>/dev/null)" "$ST0" "$1: the stamp as it was: no step 15"; }

# --- (vii) the programs change in the run that repairs the template: one kickstart, after the repair
fresh; new_programs
template_off "$T1"
mark
AU_SERVER_CHECK_SECS=6 update_run $'yes\n'
same "$RC" 0 "(vii) the programs change and the template is repaired: exit 0"
says "they are put in place once the files" "  ...the question: the programs once the files are whole"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template whole again"
same "$(kicks "$N")" 1 "  ...one kickstart"
says "Auster's programs pass." "  ...and one check, which passed"
[ -e "$P" ] && bad "  ...jobs/previous left" || ok "  ...jobs/previous deleted"
cmp -s "$DATA/bin/auster" "$T/common/auster" && ok "  ...the new programs in place" || bad "  ...bin/auster is not the release's"
progs_reset

# --- (viii) the same with the model changed and its download cut short after the yes
fresh; new_programs
same_size "$DATA/store/$SA"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a exit:18:1000 "$FX/models/standin-a.gguf"
mark
update_run $'yes\n'
same "$RC" 3 "(viii) the programs change, the model's download cut short after the yes: exit 3"
same "$(progs)" "$P0" "  ...every program in the data root byte for byte as it was, and no jobs/previous"
same "$(kicks "$N")" 0 "  ...no kickstart"
stamp_kept "  ..."
same "$(cat "$DATA/_update/updates.sh")" "$U0" "  ..._update/updates.sh as it was"
says "Auster v0.2.$REL is not in place on this Mac yet: the lines above say why." "  ...the closing line: not in place yet"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a.gguf"
model_in "$IMA"; rm -f "$DATA/store/$SA.part"

# --- (ix) jobs/previous from an earlier change never checked: repaired, then checked once
fresh
previous_put
template_off "$T1"
mark
AU_SERVER_CHECK_SECS=6 update_run $'yes\n'
same "$RC" 0 "(ix) a changed template with jobs/previous there: exit 0"
says "once to check them, once the files above are whole." "  ...the question: checked once the files are whole"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template whole again"
same "$(kicks "$N")" 1 "  ...one kickstart"
[ -e "$P" ] && bad "  ...jobs/previous left" || ok "  ...its check passed and deleted jobs/previous"
fresh; rm -f "$T/assets/order-1.jinja"; pack
previous_put
kept_put "$IB2" "$IMB" 4 32768 36.9
template_off "$T1"
mark
update_run $'yes\n'
same "$RC" 3 "  the template missing from the tree's assets/ instead: exit 3"
[ -e "$P" ] && ok "  ...jobs/previous left" || bad "  ...jobs/previous deleted"
same "$(kicks "$N")" 0 "  ...no kickstart"
stamp_kept "  ..."
says "\`auster rollback\` goes back to what it served before, with no download (run it twice: the first time puts Auster's previous programs back)." \
  "  ...auster rollback named, with run it twice"
rm -rf "$P"; rm -f "$K"/*
chmod 644 "$DATA/store/$T1"; cp "$FX/assets/order-1.jinja" "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"

# --- (xi) the template changed and missing from the tree while the programs change
fresh; rm -f "$T/assets/order-1.jinja"; new_programs
template_off "$T1"
mark
update_run $'yes\n'
same "$RC" 3 "(xi) the template missing from the tree while the programs change: exit 3"
says "Auster's own programs of v0.2.$REL are not put in place while a file of the build this Mac serves cannot be fetched again." \
  "  ...the sentence for the programs"
says_not "Update Auster's programs now?" "  ...and no programs-only question"
same "$(progs)" "$P0" "  ...no program changed"
same "$(kicks "$N")" 0 "  ...no kickstart"
stamp_kept "  ..."

# --- (xiii) the new bin/auster failing its trial run after a repair of the template
fresh
{ sed '$d' "$ROOT/common/auster"; printf 'au_status() { return 1; }\n'; tail -n 1 "$ROOT/common/auster"; } > "$T/common/auster"; pack
template_off "$T1"
mark
update_run $'yes\n'
same "$RC" 3 "(xiii) the new bin/auster failing its trial run after a repair: exit 3"
says "The files put back above stay whole; the server takes them up at its next start." "  ...it says the files stay whole"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template whole in store/"
same "$(kicks "$N")" 0 "  ...no kickstart"
same "$(progs)" "$P0" "  ...no program changed"

# --- (x) side by side, a move while the programs change, the build in use's model changed and not shared
big_mac
waiting_b1   # serving order 2 for four at 32,768, order 1 waiting
fresh; new_programs
same_size "$DATA/store/$SB"
mark
AU_SERVER_CHECK_SECS=8 update_run $'yes\n'
same "$RC" 0 "(x) a move while the programs change, model B changed: exit 0"
says "fetched again first, so that the build this Mac" "  ...the question's line of its own"
says "the model standin-b.gguf, which has changed: 2,040 bytes from Hugging Face ($REPO_B)" "  ...with the model's size"
first_kick=$(tail -n +$((N + 1)) "$STUB_LOG" | grep -n '^launchctl kickstart' | head -n 1 | cut -d: -f1)
model_get=$(tail -n +$((N + 1)) "$STUB_LOG" | grep -nF "$URL_B" | grep -v -- ' -I ' | head -n 1 | cut -d: -f1)
[ -n "$model_get" ] && [ -n "$first_kick" ] && [ "$model_get" -lt "$first_kick" ] &&
  ok "  ...model B fetched before the first kickstart" || bad "  ...model B's curl (line ${model_get:-none}) not before the first kickstart (${first_kick:-none})"
same "$(sha_of "$DATA/store/$SB")" "$SB" "  ...model B whole again"
same "$(kicks "$N")" 2 "  ...one kickstart for the programs and one for the switch"
same "$(sed -n 2p "$S" | cut -f2)" "$IB1" "  ...the move completed: order 1 serves"
progs_reset
unset AU_GPU_MIB STUB_MEMSIZE

# --- (xviii) a no to a move that carries a repair: the move's own words
waiting_b1
fresh
same_size "$DATA/store/$SB"
before=$(data_snap); mark
update_run $'no\n'
same "$RC" 1 "(xviii) a no to a move that carries a repair: exit 1"
says "Nothing was changed: build $IB1 stays waiting, and \`auster update\` offers it again." "  ...the move's own words"
same "$(data_snap)" "$before" "  ...nothing changed but logs/"

# --- (xvi) a move carrying a repair of the model, the disk after the repair no longer holding the move's download
model_in "$IMB"; chmod 644 "$DATA/store/$SB"; rm -f "$DATA/store/$SB"   # model B missing: 2,040 bytes to fetch again
rm -f "$K"/*
fresh
# a df of a 1 TB volume (976,562,500 KiB; the floor is 48,828,125 KiB) whose free space is 4,096 bytes above the floor less
# what store/ has gained since now: room for model B's 2,040 bytes and for model A's 3,400, not for both
mkdir -p "$W/fakebin"
base=$(( 50000000000 + 4096 + $(cat "$DATA"/store/* | wc -c) ))
cat > "$W/fakebin/df" <<EOF
#!/bin/bash
used=\$(cat "$DATA"/store/* 2>/dev/null | wc -c)
printf 'Filesystem   1024-blocks       Used Available Capacity iused      ifree %%iused  Mounted on\n/dev/disk3s1   976562500  927734375 %9s    95%% 2560778 2893107240    0%%   /System/Volumes/Data\n' \$(( ($base - used) / 1024 ))
EOF
chmod 755 "$W/fakebin/df"
mark
( unset AU_DISK_FREE_BYTES AU_DISK_TOTAL_BYTES; PATH="$W/fakebin:$PATH" AU_SERVER_CHECK_SECS=8 update_run $'yes\n'; echo "$RC" > "$W/rc" )
RC=$(cat "$W/rc")
same "$RC" 3 "(xvi) a move whose room the repair's download took: exit 3"
says "The build this Mac serves is whole again, but what this Mac can hold changed since the question" "  ...it says so"
same "$(sha_of "$DATA/store/$SB")" "$SB" "  ...the repair completed: model B whole again"
same "$(kicks "$N")" 1 "  ...and was checked, with one restart"
says "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...which passed"
same "$(sed -n 2p "$S" | cut -f2)" "$IB2" "  ...order 2 still serves"
same "$(requests | grep -c "^GET $URL_A\$")" 0 "  ...and model A was not fetched"
done_
