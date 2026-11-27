# T52, the update's half (U5; A3 "Correcting a build", D3.6 step 3, D3.7): a corrected build of the same files,
# ordered first, is chosen, and nothing is downloaded. On a 36 GB Mac (a 27 GiB GPU limit) serving order 2 for four people
# at 15,360 tokens, release v0.2.0 adds a build of order 2's model, engine, template, system prompt and test with a
# corrected figure, orders it after order 1 (which does not fit this Mac) and ahead of order 2, and withdraws order 2 with
# the reason `corrected`: the corrected build is waiting, its question says nothing is to be downloaded, and the yes
# asks nothing of Hugging Face, its CDN or the engine's host, neither a HEAD nor a download, tests the corrected build and
# switches to it (exit 0), order 2 in kept/. (The calm words of `corrected` are U8's.)
# Mutant: tests/mutants/T52b (download again for the same sha256), and T52a (the registry's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
IB6=bhydumlxpbj4c   # order 2 corrected: the same files, another working buffer (minted for this test)
update_install
export AU_GPU_MIB=27648 AU_RAM_BYTES=38654705664
serving_put "$IB2" "$IMB" 4 15360 36.9
cp "$FX/models/standin-b.gguf" "$DATA/store/$SB"; chmod 444 "$DATA/store/$SB"   # order 2 serves, so its model is here
R="$FX/registry-v0.2.0.tsv"
install_registry "$R" v0.2.0 "$IB1" "$IB6"
awk -F'\t' -v OFS='\t' -v ib2="$IB2" -v b="$IB6" '$1 == "build" && $2 == ib2 { $2 = b; $9 = 666; print }' "$R" > "$W/b6"; cat "$W/b6" >> "$R"
printf 'withdraw\t%s\tcorrected\n' "$IB2" >> "$R"
install_tree "$R" "$COMMIT2"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"
s0=$(cat "$DATA/builds/$IR/serving") st0=$(ls "$DATA/store" | sort)
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "a corrected build of the same files, answered yes: exit 0, tested and switched to"
says "  After       build $IB6 (standin-b.gguf)" "  ...the corrected build is offered"
says "  Download    Nothing: the files it needs are already on this Mac." "  ...its question: nothing to download"
same "$(requests | grep -E 'huggingface|cdn\.example|github\.com/ggml' | tr '\n' ' ')" "" "  ...nothing asked of Hugging Face, its CDN or the engine's host"
same "$(ls "$DATA/store" | sort)" "$st0" "  ...store/ as it was"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB6" "  ...the corrected build serves"
same "$(cat "$DATA/builds/$IR"/kept/*)" "$s0" "  ...and kept/ holds order 2's descriptor"
done_
