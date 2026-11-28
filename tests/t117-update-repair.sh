# T117 (U6, its third part; D3.6 "A changed file of the build in use is fetched again", AD13, BD18): a changed or
# missing file of the build in use is fetched again by an update, and only it, with serving at a speed other than 0. On
# a Mac that installed order 1 and serves it: (i) model A changed at the same size: the question names it with its size,
# and a yes deletes it, asks the stub publisher (HEAD), fetches it, checks its sha256, restarts the engine once (one
# kickstart) and makes the server check, with serving byte for byte as it was (and not renamed), no candidate started
# and nothing in kept/; (ii) the template changed: copied again from the tree, with no request but GitHub's API and the
# tree; (iii) a file of the engine changed with its archive intact: unpacked again, with no request to GitHub's
# releases; the archive changed: fetched again from them; (iv) llama-server lost its execute bit: unpacked again,
# executable; (v) a no fetches nothing and changes nothing but logs/ (exit 1); (vi) every file matching: nothing but
# logs/ changes, as in T65; (vii) a repair with a change of setting (serving order 1 at 16,384, which 32,768 now
# replaces): one restart, the old setting in kept/. (viii) Serving order 2 with order 1 waiting, Auster's programs
# unchanged and no jobs/previous/: model B, which order 1 does not share, has changed, and so has the engine's archive,
# which it does: model B is on a line of its own in the question, fetched again first from the stub publisher at
# serving's model line, the archive fetched once, and the move completes (exit 0). (ix) Side by side, order 2's template
# changed and the candidate failing its test, the engine job answering only while the template is serving's (it hashes
# it at every start, engine-hash otherwise): the repair comes first, so the restart after the failed test passes its
# check: "did not pass", exit 3, not 4.
# Mutants: tests/mutants/T117a (judge the build in use OK without checking its files), T117b (check the model by its
# size alone), T117c (run the isolated test on a repair), T117d (rewrite serving on a repair), T117e (no server check
# after a repair), T117f (fetch the archive again when only its unpacked files changed), T117g (check the engine against
# engines/<sha256>/files alone), T117h (restart twice), T117i (a move that leaves the build in use as it is).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept"
T1=$(sed -n 2p "$S" | cut -f5)                     # order 1's template
ESTORE="$DATA/store/$ESHA"                         # the engine's archive
sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
same_size() { # FILE -> its middle byte changed, at the same size, read-only as store/ keeps it
  local f=$1 n
  n=$(stat -f %z "$f")
  { head -c $((n / 2)) "$f"; printf 'X'; tail -c +$((n / 2 + 2)) "$f"; } > "$W/changed"
  chmod 644 "$f"; cat "$W/changed" > "$f"; chmod 444 "$f"
}
kicks() { job_calls "$1" | grep -o 'launchctl kickstart' | wc -l | tr -d ' '; }
mark() { N=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; S0=$(cat "$S"); I0=$(stat -f %i "$S"); C0=$(ls -d "$STUB_ENGINE_DIR"/starts/* 2>/dev/null | wc -l); }
candidates() { ls -d "$STUB_ENGINE_DIR"/starts/* 2>/dev/null | tail -n +$((C0 + 1)) | while read -r st; do [ "$(arg_of "$st" --port)" = "$CPORT" ] && echo "$st"; done | wc -l | tr -d ' '; }
hosts() { requests | grep -E 'huggingface|cdn\.example|github\.com/ggml|objects\.example' | tr '\n' ' '; }
serving_kept() { # LABEL -> serving byte for byte as it was, not renamed, and nothing in kept/
  same "$(cat "$S")" "$S0" "$1: serving byte for byte as it was"
  same "$(stat -f %i "$S")" "$I0" "$1: serving not rewritten (the same file)"
  same "$(ls -A "$K" 2>/dev/null | wc -l | tr -d ' ')" 0 "$1: nothing in kept/"
}

# --- (i) the model changed at the same size
same_size "$DATA/store/$SA"
mark
repaste $'yes\n'
same "$RC" 0 "(i) model A changed at the same size: exit 0"
says "the model standin-a.gguf, which has changed: 3,400 bytes from Hugging Face ($REPO_A)" "  ...the question names it with its size"
same "$(hosts)" "HEAD $URL_A HEAD $URL_A GET $URL_A GET https://cdn.example.test/a " "  ...asked of the publisher (before the question and before the fetch), then fetched"
same "$(sha_of "$DATA/store/$SA")" "$SA" "  ...model A whole again in store/"
same "$(stat -f %Lp "$DATA/store/$SA")" 444 "  ...read-only"
same "$(kicks "$N")" 1 "  ...the engine restarted once"
says "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...and the server check made"
same "$(candidates)" 0 "  ...no candidate started: no test"
serving_kept "  ..."

# --- (ii) the template changed: copied again from the tree, nothing asked of a host
chmod 644 "$DATA/store/$T1"; printf '{# one more line #}\n' >> "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"
mark
repaste $'yes\n'
same "$RC" 0 "(ii) the template changed: exit 0"
says "the template, which has changed: from this version of Auster" "  ...the question names it"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template whole again in store/"
same "$(requests | cut -d' ' -f2 | grep '^https:' | sed -E 's|/[^/]*$||' | sort -u | tr '\n' ' ')" \
  "https://api.github.com/repos/macaiport/auster/commits/heads https://codeload.github.com/macaiport/auster/tar.gz " \
  "  ...no request but GitHub's API and the tree"
same "$(kicks "$N")" 1 "  ...the engine restarted once, and checked"
serving_kept "  ..."

# --- (iii) the engine's unpacked files changed with the archive intact, then the archive changed
same_size "$ED/root/llama-stub/libstub.0.dylib"
mark
repaste $'yes\n'
same "$RC" 0 "(iii) a file of the engine changed, its archive intact: exit 0"
says "the engine's unpacked files, which have changed: unpacked again from its archive, with nothing fetched for them" "  ...the question says it is unpacked again"
same "$(hosts)" "" "  ...nothing asked of GitHub's releases"
(cd "$ED/root" && find . \( -type f -o -type l \) -print | sed 's|^\./||' | LC_ALL=C sort | while IFS= read -r p; do
  if [ -L "$p" ]; then printf '%s\tlink\t%s\n' "$p" "$(readlink "$p")"; else printf '%s\t%s\t%s\n' "$p" "$(stat -f %z "$p")" "$(shasum -a 256 < "$p" | cut -c1-64)"; fi
done) | cmp -s - "$ED/files" && ok "  ...unpacked again: its files those its list names" || bad "  ...the engine's files are not those its list names"
same "$(kicks "$N")" 1 "  ...the engine restarted once"
serving_kept "  ..."
same_size "$ESTORE"
mark
repaste $'yes\n'
same "$RC" 0 "  the archive changed at the same size: exit 0"
says "the engine's archive, which has changed:" "  ...the question names it"
same "$(hosts)" "HEAD $ENGINE_URL GET $ENGINE_URL GET $ENGINE_CDN " "  ...asked of GitHub's releases, then fetched from them"
same "$(sha_of "$ESTORE")" "$ESHA" "  ...the archive whole again in store/"
serving_kept "  ..."

# --- (iv) llama-server lost its execute bit (its list says nothing of modes)
chmod 644 "$ED/root/llama-stub/llama-server"
mark
repaste $'yes\n'
same "$RC" 0 "(iv) llama-server not executable: exit 0"
says "the engine's unpacked files, which have changed" "  ...the question names the engine's files"
[ -x "$ED/root/llama-stub/llama-server" ] && ok "  ...unpacked again: llama-server executable" || bad "  ...llama-server still not executable"
same "$(hosts)" "" "  ...nothing fetched"
same "$(kicks "$N")" 1 "  ...the engine restarted once"

# --- (v) a no
chmod 644 "$DATA/store/$T1"; printf '{# one more line #}\n' >> "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"
before=$(data_snap); mark
repaste $'no\n'
same "$RC" 1 "(v) the template changed, answered no: exit 1"
says "Nothing was changed: pasting the installer line again offers this again." "  ...it says so"
same "$(data_snap)" "$before" "  ...nothing in the data root changed but logs/"
same "$(hosts)" "" "  ...nothing fetched"
same "$(job_calls "$N")" "" "  ...and no job restarted"
chmod 644 "$DATA/store/$T1"; cp "$FX/assets/order-1.jinja" "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"

# --- (vi) every file matches
before=$(data_snap); mark
repaste ''
same "$RC" 0 "(vi) every file matching: exit 0"
says "The recipe household: OK. Build $IB1 serves it" "  ...it prints OK"
says_not "Repair" "  ...and asks nothing"
same "$(data_snap)" "$before" "  ...nothing in the data root changed but logs/"
same "$(job_calls "$N")" "" "  ...no job restarted"

# --- (vii) a repair with a change of setting: one restart, the old setting kept
serving_put "$IB1" "$IMA" 4 16384 36.9
chmod 644 "$DATA/store/$T1"; printf '{# one more line #}\n' >> "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"
mark
repaste $'yes\n'
same "$RC" 0 "(vii) a changed template and a change of setting: exit 0"
says "its setting would change, on the build it serves" "  ...the question: a change of setting"
says "fetched again first, so that the build this Mac" "  ...with the repair on a line of its own"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template whole again"
same "$(kicks "$N")" 1 "  ...one restart"
same "$(sed -n 5p "$S" | cut -f2,3,6)" "4	32768	36.9" "  ...serving at the new setting, checked"
same "$(ls "$K" | wc -l | tr -d ' '):$(sed -n 5p "$K"/* 2>/dev/null | cut -f2,3)" "1:4	16384" "  ...the old setting in kept/"
rm -f "$K"/*

# --- (viii) a move to order 2's successor, order 1: the build in use's changed model fetched first, a shared archive once
waiting_b1   # serving order 2 for four at 32,768; order 1 waiting
same_size "$DATA/store/$SB"; same_size "$ESTORE"
mark
AU_SERVER_CHECK_SECS=8 repaste $'yes\n'
same "$RC" 0 "(viii) a move, the build in use's model and the shared archive changed: exit 0"
says "These files of build $IB2, which it serves now, are fetched again first, so that the build this Mac" "  ...the build in use's files on a line of their own"
says "the model standin-b.gguf, which has changed: 2,040 bytes from Hugging Face ($REPO_B)" "  ...its model, with its size"
gets() { requests | grep '^GET ' | grep -nF "$1" | head -n 1 | cut -d: -f1; }
[ -n "$(gets "$URL_B")" ] && [ -n "$(gets "$URL_A")" ] && [ "$(gets "$URL_B")" -lt "$(gets "$URL_A")" ] &&
  ok "  ...model B fetched again from serving's model line, before the new build's model" || bad "  ...the order of the fetches: $(hosts)"
same "$(requests | grep -c "^GET $ENGINE_URL\$")" 1 "  ...the shared archive fetched once"
same "$(sha_of "$DATA/store/$SB"):$(sha_of "$ESTORE")" "$SB:$ESHA" "  ...both whole again"
same "$(sed -n 2p "$S" | cut -f2)" "$IB1" "  ...and the move completed: order 1 serves"

# --- (ix) side by side, the template changed and the candidate failing: the repair first, so the restart passes its check
big_mac
waiting_b1
T2=$(sed -n 2p "$S" | cut -f5)
chmod 644 "$DATA/store/$T2"; printf '{# one more line #}\n' >> "$DATA/store/$T2"; chmod 444 "$DATA/store/$T2"
engine_set "port=$CPORT" answers "$FX/answers-bad"
rm -f "$DATA/builds/$IR"/failed/*
mark
AU_SERVER_CHECK_SECS=8 repaste $'yes\n'
same "$RC" 3 "(ix) side by side, order 2's template changed, the candidate failing: exit 3, not 4"
says "Build $IB1 did not pass the recipe's test on this Mac." "  ...the test failed"
says "The server answered on build $IB2" "  ...and the restart after it passed its check: the repair came first"
same "$(sha_of "$DATA/store/$T2")" "$T2" "  ...order 2's template whole"
same "$(sed -n 2p "$S" | cut -f2)" "$IB2" "  ...order 2 still serves"
done_
