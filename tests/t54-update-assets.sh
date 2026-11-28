# T54, the update's half (U4; A4, B3 step 8, D3.6): the template, system prompt and test a build names are looked for by
# sha256, in store/ and then in the tree's assets/, before the question. On a Mac serving order 2 with order 1 waiting,
# and none of the three in store/ (order 1 has a system prompt and a test of its own here, so that the build in use
# keeps its own whole, which the update checks since U6's third part), a release whose asset differs from the one the
# build names by one byte (its length the same): the update stops before its question, says which file it lacks, passes
# the recipe over (exit 3), and changes nothing the server runs from: no question, no request to Hugging Face, builds/,
# store/, engines/, keys/ and Auster's programs as they were. (The run still ends with step 15, since its programs are
# this tree's byte for byte: the stamp says v0.2.0, as U1 placed it; a run that stops before its end writes none.) Every
# file in assets/ renamed changes nothing: the update reaches its question. Mutants: tests/mutants/T54c (find the asset
# by name) and T54d (skip the hash), which change the update's lookup as they change step 8's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
cp -R "$FX/assets" "$W/assets-good"
# order 1 is given a system prompt and a test of its own, so that none of its three is in store/ while the build in use
# keeps its own there, whole, as the update now checks (D3.6, U6's third part)
printf 'You are the household assistant for a family. Answer briefly, plainly and kindly.\n' > "$W/assets-good/order-1-system.txt"
{ cat "$FX/assets/household-test.json"; printf ' \n'; } > "$W/assets-good/order-1-test.json"
sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
one_byte() { # FILE -> its last byte made another, so that it differs by one byte and keeps its length
  local n c
  n=$(stat -f %z "$1"); c=$(tail -c 1 "$1")
  { head -c $((n - 1)) "$1"; if [ "$c" = X ]; then printf Y; else printf X; fi; } > "$1.new" && mv "$1.new" "$1"
}
install_registry "$FX/registry-v0.2.0.tsv" v0.2.0   # the shas of the assets as they are, and order 1's own two
awk -F'\t' -v OFS='\t' -v b="$IB1" -v s="$(sha_of "$W/assets-good/order-1-system.txt")" -v t="$(sha_of "$W/assets-good/order-1-test.json")" \
  '$1 == "build" && $2 == b { $6 = s; $7 = t } { print }' "$FX/registry-v0.2.0.tsv" > "$W/reg" && mv "$W/reg" "$FX/registry-v0.2.0.tsv"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"
for a in order-1.jinja:template order-1-system.txt:system-prompt order-1-test.json:test; do
  chmod 644 "$DATA/store/$(sha_of "$W/assets-good/${a%%:*}")" 2>/dev/null; rm -f "$DATA/store/$(sha_of "$W/assets-good/${a%%:*}")"
done
served() { snapshot "$DATA" | grep -v -E $'\t(logs|_update)(/|$)'; }   # all but logs/ and _update/
before=$(served)
for a in order-1.jinja:template order-1-system.txt:system-prompt order-1-test.json:test; do
  rm -rf "$FX/assets"; cp -R "$W/assets-good" "$FX/assets"
  one_byte "$FX/assets/${a%%:*}"
  install_tree "$FX/registry-v0.2.0.tsv" "$COMMIT2"
  rm -rf "$STUB_CURL_DIR/requests"
  update_run $'yes\n'
  same "$RC" 3 "the ${a#*:} differing by one byte: exit 3"
  says "This version of Auster holds no ${a#*:} with the sha256 build $IB1 names. The recipe household is not updated: it keeps serving build $IB2." \
    "  ...it says which file it lacks, and that the recipe keeps its build"
  says_not "an update is waiting" "  ...no question asked"
  same "$(requests | grep -c huggingface)" 0 "  ...nothing asked of Hugging Face"
  same "$(served)" "$before" "  ...builds/, store/, engines/, keys/ and the programs as they were"
  same "$(cut -f2,3,4 "$DATA/_update/scripts")" "release	v0.2.0	$COMMIT2" "  ...and the stamp moved to v0.2.0, the programs being this tree's"
done
rm -rf "$FX/assets"; mkdir "$FX/assets"; i=0
for f in "$W"/assets-good/*; do i=$((i + 1)); cp "$f" "$FX/assets/renamed-$i"; done
install_tree "$FX/registry-v0.2.0.tsv" "$COMMIT2"
update_run $'no\n'
same "$RC" 1 "every file in assets/ renamed: the update reaches its question, answered no: exit 1"
says "The recipe household: an update is waiting." "  ...the question is asked"
done_
