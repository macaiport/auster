# T110 (U5; D3.6 steps 1 to 3, B3 step 4): an update to a build with a new engine fetches no engine archive or model file
# before the yes. On a Mac serving order 2 (engine b12359), release v0.2.0 puts first a build of model A on a new engine,
# b12360, whose registry line says it runs on macOS 28 or later. On macOS 27.2 the recipe is passed over before the
# question, in one sentence that names the floor, with exit 3, and nothing is asked of the engine's host, Hugging Face
# or its CDN (the candidate engine's macOS floor, judged as a first install judges it). On macOS 28.1, `auster update`
# over SSH answered no: until the question is answered, the stub curl's log shows only release's install.sh, GitHub's API,
# the tree and the publisher's HEAD for each file store/ lacks (the model at Hugging Face, the engine archive at GitHub),
# and step 4's --list-devices ran from the engine already in engines/. Answered yes: the model and the new engine are
# fetched after the yes from their own addresses, checked, the engine unpacked into engines/ with its list, the candidate
# run from it, and the recipe switched to the new build (exit 0), serving naming its engine and that engine's list.
# Mutants: tests/mutants/T110a (run step 4 as at a first install), T110b (judge no macOS floor for the candidate engine).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
IE2=ejy63moqy3zwf   # a second engine, b12360 (minted for this test)
IB5=bobshbb3xnrvs   # model A on it, A6's order-1 figures (minted for this test)
ENGINE2_URL=https://github.com/ggml-org/llama.cpp/releases/download/b12360/llama-b12360-bin-macos-arm64.tar.gz
ENGINE2_CDN=https://objects.example.test/llama-engine-2
update_install
waiting_b1   # serving order 2, model A not in store/
mkdir -p "$FX/engine-src2"; cp -R "$FX/engine-src/llama-stub" "$FX/engine-src2/"
printf 'the library of b12360\n' > "$FX/engine-src2/llama-stub/libstub.0.dylib"
(cd "$FX/engine-src2" && tar -czf "$FX/engine2.tar.gz" llama-stub)
E2=$(shasum -a 256 < "$FX/engine2.tar.gz" | cut -c1-64)
curl_route GET "$ENGINE2_URL" 302 - "Location: $ENGINE2_CDN"
curl_route GET "$ENGINE2_CDN" 200 "$FX/engine2.tar.gz"
R="$FX/registry-v0.2.0.tsv"
install_registry "$R" v0.2.0 "$IB5" "$IB1" "$IB2"
printf 'engine\t%s\tmacos-arm64\tb12360\tllama-b12360-bin-macos-arm64.tar.gz\t%s\t%s\t28\n' "$IE2" "$(stat -f %z "$FX/engine2.tar.gz")" "$E2" >> "$R"
awk -F'\t' -v OFS='\t' -v ib1="$IB1" -v b="$IB5" -v e="$IE2" '$1 == "build" && $2 == ib1 { $2 = b; $3 = e; print }' "$R" > "$W/b5"
cat "$W/b5" >> "$R"
install_tree "$R" "$COMMIT2"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"
s0=$(cat "$DATA/builds/$IR/serving")
host_asks() { requests | grep -E 'huggingface|cdn\.example|objects\.example|github\.com/ggml' | tr '\n' ' '; }

# --- macOS 27.2, below the new engine's floor
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "macOS 27.2, the new engine needs 28: exit 3"
says "Build $IB5 needs an engine that runs on macOS 28 or later, and this Mac has macOS 27.2. The recipe household is not updated: it keeps serving build $IB2." \
  "  ...passed over in one sentence that names the floor"
says_not "an update is waiting" "  ...before the question"
same "$(host_asks)" "" "  ...nothing asked of the engine's host, Hugging Face or its CDN"

# --- macOS 28.1: `auster update` over SSH, answered no
export STUB_MACOS=28.1
cp "$R" "$DATA/_update/registry"; printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$DATA/_update/offer"
rm -rf "$STUB_CURL_DIR/requests"; ls "$STUB_ENGINE_DIR/starts" > "$W/starts-before"
ANSWERS=$'no\n' SSH_CONNECTION='10.0.0.9 50111 10.0.0.5 22' auster update
same "$RC" 1 "macOS 28.1, auster update over SSH answered no: exit 1"
outsays "The recipe household: an update is waiting." "  ...the question was asked"
outsays "the engine b12360 from GitHub" "  ...and names the new engine among the downloads"
same "$(requests)" "GET $INSTALL_SH
GET $API/heads/release
GET $CODELOAD/$COMMIT2
HEAD $URL_A
HEAD $ENGINE2_URL" "  ...until it was answered: release's install.sh, GitHub's API, the tree, and the publisher's HEAD for the model and the engine"
ld=
for s in $(ls "$STUB_ENGINE_DIR/starts" | grep -vxF -f "$W/starts-before"); do
  grep -qx -- --list-devices "$STUB_ENGINE_DIR/starts/$s/args" && ld="$ld$(cat "$STUB_ENGINE_DIR/starts/$s/program") "
done
same "$ld" "$DATA/engines/$ESHA/root/llama-stub/llama-server " "  ...and step 4 ran --list-devices once, from the engine already in engines/"
[ -e "$DATA/engines/$E2" ] || [ -e "$DATA/store/$E2" ] || [ -e "$DATA/store/$SA" ] && bad "  ...a file was fetched" || ok "  ...nothing in store/ or engines/ for the new build"

# --- answered yes
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "answered yes: exit 0, the new build tested and switched to"
same "$(host_asks)" "HEAD $URL_A HEAD $ENGINE2_URL HEAD $URL_A GET $URL_A GET https://cdn.example.test/a GET $ENGINE2_URL GET $ENGINE2_CDN " \
  "  ...asked again before the download, then fetched from the addresses that name them"
same "$(shasum -a 256 < "$DATA/store/$E2" 2>/dev/null | cut -c1-64):$(shasum -a 256 < "$DATA/store/$SA" 2>/dev/null | cut -c1-64)" "$E2:$SA" \
  "  ...the new engine's archive and model A in store/"
[ -x "$DATA/engines/$E2/root/llama-stub/llama-server" ] && grep -q '^llama-stub/libstub.0.dylib	' "$DATA/engines/$E2/files" &&
  ok "  ...the new engine unpacked into engines/ with its file list" || bad "  ...engines/$E2 is not the unpacked engine: $(ls -R "$DATA/engines/$E2" 2>&1 | head -5)"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2) $(sed -n 3p "$DATA/builds/$IR/serving" | cut -f7) $(sed -n 5p "$DATA/builds/$IR/serving" | cut -f5)" \
  "$IB5 $E2 $(shasum -a 256 < "$DATA/engines/$E2/files" | cut -c1-64)" "  ...serving names the new build, its engine and that engine's list"
same "$(arg_of "$(start_on $CPORT)" --alias) $(cat "$(start_on $CPORT)/program")" "$IB5 $DATA/engines/$E2/root/llama-stub/llama-server" \
  "  ...the candidate ran from the new engine"
done_
