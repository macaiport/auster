# T7 (U4, and U5 for its yes; D3.6 steps 2 and 3, C6): a no at the question leaves no new file on disk, no earlier
# build removed, the server untouched, and the build still waiting. On a Mac serving order 2 with order 1 waiting
# (3,400 bytes to fetch), with a build kept from before whose model file only it names, and with free disk one step
# short of Auster's floor, the question names the download and the kept build the disk rule would remove (the one
# before the build in use), the way the switch would go (in turn: both builds do not fit at once on this 64 GB Mac),
# and that nothing has been fetched (the publisher was asked about the file with a HEAD, D3.6 step 1). Answered no:
# exit 1; the data root as it was but logs/ (the kept entry and its file there); nothing asked of Hugging Face, its CDN
# or the engine's host but that HEAD; no job loaded, booted out or kickstarted, the engine's process the same; and the
# rule file still says waiting. Answered yes (U5's middle part): the kept build the question named is removed only now,
# with the model file only it named, then order 1's model is fetched into store/, and the run ends where U5's last part
# will test it, with exit 3, serving and the engine's process as they were, and the files serving names kept (nothing
# asked of the engine's host). Mutants: tests/mutants/T7a (start the download before the question), T7b (remove
# earlier builds before it), T7c (remove every file a removed build named, those serving names among them).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
# a build kept from before: order 1's lines, with a model file of its own (1,000 bytes) that nothing else names
X=$(printf 'an older model file\n' | shasum -a 256 | cut -c1-64)
head -c 1000 /dev/zero | tr '\0' 'm' > "$DATA/store/$X"; chmod 444 "$DATA/store/$X"
K="$DATA/builds/$IR/kept/2026-11-20T10:00:00Z-$IB1"
awk -F'\t' -v OFS='\t' -v x="$X" 'NR == 4 { $7 = x } { print }' "$W/pristine/builds/$IR/serving" > "$K"; chmod 600 "$K"
export AU_DISK_FREE_BYTES=50000003399   # floor 50,000,000,000; less the 3,400 to fetch, one byte short
engine_up
before=$(data_snap); pid=$(engine_pid); n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
cp "$DATA/builds/$IR/serving" "$W/serving-before"

update_run $'no\n'
same "$RC" 1 "answered no: exit 1"
says "The recipe household: an update is waiting. Nothing has been fetched, and nothing changes without a yes." "the question says nothing is fetched yet"
says "Download    3,400 bytes: standin-a.gguf from Hugging Face ($REPO_A)." "  ...it names the download"
says "build $IB1, kept since 2026-11-20: the one before the build in use, so \`auster rollback\` could no longer go back to it" \
  "  ...the kept build the disk rule would remove, and that it is the one before the build in use"
says "This Mac cannot hold both builds at once: the server does not answer while the new build is tested" "  ...the way the switch would go"
says "Nothing was changed: build $IB1 stays waiting" "  ...after the no, it says the build stays waiting"
same "$(data_snap)" "$before" "the data root as it was but logs/: no new file, the kept build and its file still there"
same "$(requests | grep -E 'huggingface|cdn\.example|github\.com/ggml')" "HEAD $URL_A" "nothing asked of Hugging Face, its CDN or the engine's host but the publisher's HEAD"
same "$(job_calls "$n")" "" "no job loaded, booted out or kickstarted"
same "$(engine_pid)" "$pid" "the engine's process the same"
same "$(AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" --recipes | awk -F'\t' '$1 == "recipe" { print $3, $7 }')" "waiting $IB1" \
  "the rule file still says order 1 is waiting"

rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "answered yes: exit 3, where U5's last part will test the build"
says "Removed build $IB1, kept since 2026-11-20, to make room." "  ...it removes the kept build the question named"
[ -e "$K" ] || [ -e "$DATA/store/$X" ] && bad "  ...the kept entry or its model file is still there" || ok "  ...the kept entry and the model file only it named are gone"
same "$(shasum -a 256 < "$DATA/store/$SA" 2>/dev/null | cut -c1-64) $(stat -f %Lp "$DATA/store/$SA" 2>/dev/null)" "$SA 444" "  ...order 1's model is in store/, read-only"
same "$(requests | grep -E 'huggingface|cdn\.example' | tr '\n' ' ')" "HEAD $URL_A HEAD $URL_A GET $URL_A GET https://cdn.example.test/a " \
  "  ...asked of the publisher before the question and again before the download, from the address that names its commit"
same "$(requests | grep -c 'github\.com/ggml')" 0 "  ...nothing asked of the engine's host: the engine, which serving names too, was kept"
says "Build $IB1's files are on this Mac. The recipe household keeps serving build $IB2: testing build $IB1 here and switching to it come with a later version of Auster." "  ...it says the switch comes later"
same "$(cat "$DATA/builds/$IR/serving")" "$(cat "$W/serving-before")" "  ...serving as it was"
same "$(engine_pid)" "$pid" "  ...the engine's process the same"
done_
