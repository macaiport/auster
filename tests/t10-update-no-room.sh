# T10 (U5; D3.6 steps 1 and 3, C6): too little disk even after removing the earlier builds the rule allows passes the
# recipe over before any fetch. On a Mac serving order 2 with order 1 waiting (3,400 bytes to fetch) and nothing kept,
# with free disk one byte short of Auster's floor less the download: the recipe is passed over before the question with
# the reason, exit 3, and nothing is asked of Hugging Face or its CDN, not even the HEAD. Room is worked out again before
# the download starts: with `df` saying there is room at the question and, measured again after the yes, that there is
# not (a stand-in df whose figures drop after its first call), the recipe stops before any fetch, with exit 3, the
# reason, and nothing fetched but the publisher's HEAD. With a build kept from before that only a removal after the yes
# would free (there being room without it at the question, which named no removal), the recipe stops before any fetch
# and the kept build stays: the one before the build in use goes only when the question named it (D3.6 step 3).
# Mutants: tests/mutants/T10a (check the disk after the download starts: no disk rule before the question), T10b (room
# worked out only at the question), T10c (remove earlier builds the question did not name).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/, nothing kept
s0=$(cat "$DATA/builds/$IR/serving")
host_asks() { requests | grep -E 'huggingface|cdn\.example|github\.com/ggml' | tr '\n' ' '; }

export AU_DISK_FREE_BYTES=50000003399   # floor 50,000,000,000 (5% of 1 TB); less the 3,400 to fetch, one byte short
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "too little disk, nothing the rule may remove: exit 3"
says "The recipe household: passed over (no room on disk), so it is not updated: it keeps serving build $IB2." "  ...passed over, with the reason"
says_not "an update is waiting" "  ...before the question"
same "$(host_asks)" "" "  ...nothing asked of Hugging Face or its CDN"
same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"

# a df of a 1 TB volume (976,562,500 KiB; the floor is 48,828,125 KiB) whose free space drops after its first call:
# 48,828,135 KiB at the question (10,240 bytes above the floor, room for 3,400), then 48,828,126 (1,024 above: none)
unset AU_DISK_FREE_BYTES AU_DISK_TOTAL_BYTES
mkdir -p "$W/fakebin"
cat > "$W/fakebin/df" <<EOF
#!/bin/bash
n=\$(cat "$W/df-calls" 2>/dev/null || echo 0); n=\$((n + 1)); echo "\$n" > "$W/df-calls"
if [ "\$n" = 1 ]; then a=48828135; else a=48828126; fi
printf 'Filesystem   1024-blocks       Used Available Capacity iused      ifree %%iused  Mounted on\n/dev/disk3s1   976562500  927734375 %9s    95%% 2560778 2893107240    0%%   /System/Volumes/Data\n' "\$a"
EOF
chmod 755 "$W/fakebin/df"
rm -rf "$STUB_CURL_DIR/requests" "$W/df-calls"
PATH="$W/fakebin:$PATH" update_run $'yes\n'
same "$RC" 3 "room at the question, none when the download would start: exit 3"
says "The recipe household: an update is waiting." "  ...the question was asked, with room"
says "The recipe household: passed over (no room on disk), so it is not updated: it keeps serving build $IB2." "  ...after the yes, the disk measured again: no room"
same "$(cat "$W/df-calls")" 2 "  ...df asked at the question and again before the download"
same "$(host_asks)" "HEAD $URL_A " "  ...nothing fetched: only the publisher's HEAD, before the question"
[ -e "$DATA/store/$SA" ] || [ -e "$DATA/store/$SA.part" ] && bad "  ...a file for model A in store/" || ok "  ...no file for model A in store/"
same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"

# the same df, with a build kept from before whose own model file (4,000 bytes) frees enough: at the question there is
# room without it, so the question names no removal; after the yes there is room only by removing it, the one before
# the build in use, which the question did not name: the recipe stops, the kept build stays, and nothing is fetched
X=$(printf 'an older model file\n' | shasum -a 256 | cut -c1-64)
head -c 4000 /dev/zero | tr '\0' 'm' > "$DATA/store/$X"; chmod 444 "$DATA/store/$X"
K="$DATA/builds/$IR/kept/2026-11-20T10:00:00Z-$IB1"
awk -F'\t' -v OFS='\t' -v x="$X" 'NR == 4 { $7 = x } { print }' "$W/pristine/builds/$IR/serving" > "$K"; chmod 600 "$K"
rm -rf "$STUB_CURL_DIR/requests" "$W/df-calls"
PATH="$W/fakebin:$PATH" update_run $'yes\n'
same "$RC" 3 "room at the question, and after the yes only by removing a build the question did not name: exit 3"
says_not "  Removed     To make room" "  ...the question named no removal"
says "To make room now, build $IB1 would have to be removed, which the question did not name. The recipe household is not updated: it keeps serving build $IB2." \
  "  ...after the yes: it says the removal was not named, and stops"
[ -f "$K" ] && [ -f "$DATA/store/$X" ] && ok "  ...the kept build and its model file are still there" || bad "  ...the kept build was removed"
same "$(host_asks)" "HEAD $URL_A " "  ...and nothing was fetched"
done_
