# T7 (U4; D3.6 step 2, C6): a no at the question leaves no new file on disk, no earlier build removed, the server
# untouched, and the build still waiting. On a Mac serving order 2 with order 1 waiting (3,400 bytes to fetch), with a
# build kept from before whose model file only it names, and with free disk one step short of Auster's floor, the
# question names the download and the kept build the disk rule would remove (the one before the build in use), the
# way the switch would go (in turn: both builds do not fit at once on this 64 GB Mac), and that nothing has been
# fetched. Answered no: exit 1; the data root as it was but logs/ (the kept entry and its file there); no request to
# Hugging Face or its CDN; no job loaded, booted out or kickstarted, the engine's process the same; and the rule file
# still says waiting. Answered yes: the run ends at U5's step with exit 3, having changed nothing.
# Mutants: tests/mutants/T7a (start the download before the question), T7b (remove earlier builds before it).
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

update_run $'no\n'
same "$RC" 1 "answered no: exit 1"
says "The recipe household: an update is waiting. Nothing has been fetched, and nothing changes without a yes." "the question says nothing is fetched yet"
says "Download    3,400 bytes: standin-a.gguf from Hugging Face ($REPO_A)." "  ...it names the download"
says "build $IB1, kept since 2026-11-20: the one before the build in use, so \`auster rollback\` could no longer go back to it" \
  "  ...the kept build the disk rule would remove, and that it is the one before the build in use"
says "This Mac cannot hold both builds at once: the server does not answer while the new build is tested" "  ...the way the switch would go"
says "Nothing was changed: build $IB1 stays waiting" "  ...after the no, it says the build stays waiting"
same "$(data_snap)" "$before" "the data root as it was but logs/: no new file, the kept build and its file still there"
same "$(requests | grep -cE 'huggingface|cdn\.example|github\.com/ggml')" 0 "nothing asked of Hugging Face, its CDN or the engine's host"
same "$(job_calls "$n")" "" "no job loaded, booted out or kickstarted"
same "$(engine_pid)" "$pid" "the engine's process the same"
same "$(AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" --recipes | awk -F'\t' '$1 == "recipe" { print $3, $7 }')" "waiting $IB1" \
  "the rule file still says order 1 is waiting"

update_run $'yes\n'
same "$RC" 3 "answered yes: exit 3, at U5's step"
says "Making this change comes with a later version of Auster (U5), so nothing was changed." "  ...it says nothing was changed"
same "$(data_snap)" "$before" "  ...and nothing was"
same "$(requests | grep -cE 'huggingface|cdn\.example|github\.com/ggml')" 0 "  ...nothing fetched"
same "$(engine_pid)" "$pid" "  ...the engine's process the same"
done_
