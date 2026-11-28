# T112 (U5, U6; B6, C4, D3.6 "If only its setting changes"): `auster people 2` on a Mac serving four, with a newer release
# waiting (v0.2.0, whose own programs differ, while order 1 waits for this Mac): release's install.sh is fetched and run
# with `people 2`, the question names the change, and on a yes nothing is fetched but the installer, GitHub's API and the
# tree, no build is tested, the old descriptor is in kept/ byte for byte, serving is rewritten by rename with two people
# and a speed of 0 that the server check then replaces, the engine is restarted on it, and no build, no program, no stamp
# and no `mac` change. On a Mac whose figures allow 15,360 tokens each for four, two people are chosen again at 31,744
# (C4; T91's `auster people 2`). A stub engine failing at the new setting (three people): exit 4, naming `auster
# rollback`, serving at the new setting with a speed of 0, the earlier setting kept, nothing in failed/; `auster rollback`
# then goes back to two people with a speed of 0 until its check passes (watched while the check waits on an engine still
# loading), writes no `hold` and nothing in failed/, and lists the three-person entry as never checked. More people than
# the recipe's default, a no, a live lock and no installer from GitHub each change nothing. (Its refusal while a file the
# engine job checks has changed is T118 (xiv), tests/t118-repair-refusals.sh.)
# Mutants: tests/mutants/T112a (run the test), T112b (rewrite serving in place), T112c (skip the server check), T112d
# (hold the build itself on that rollback), T112e (change the build), T112f (write the stamp).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
waiting_b1   # serving order 2 for four at 32,768, order 1 waiting
release_at v0.2.0 "$COMMIT2"
printf '# a change in v0.2.0\n' >> "$FX/tree-src-$COMMIT2/common/auster"
tree_archive "$FX/tree-src-$COMMIT2" "auster-$COMMIT2" "$COMMIT2" "$FX/tree-$COMMIT2.tar.gz"
engine_up
S="$DATA/builds/$IR/serving"
progs() { snapshot "$DATA/bin"; snapshot "$DATA/jobs"; }
launch() { sed -n 5p "$S" | cut -f1-4,6; }
newest_start() { ls -d "$STUB_ENGINE_DIR"/starts/* | tail -n 1; }
arg_after() { sed -n "/^$2\$/{n;p;}" "$1/args"; }   # START OPTION -> the value the engine was given
p0=$(progs) stamp=$(cat "$DATA/_update/scripts") mac=$(cat "$DATA/builds/mac") s0=$(cat "$S") i0=$(stat -f %i "$S")
n=$(starts); rm -rf "$STUB_CURL_DIR/requests"

ANSWERS=$'yes\n' auster people 2
same "$RC" 0 "auster people 2 on a Mac serving four, a newer release waiting: exit 0"
outsays "The recipe household: its setting would change, on the build it serves." "the question: a change of setting"
outsays "  People      2 people at a time, as asked, in place of 4." "  ...from four people to two"
outsays "  Download    Nothing: it is the build this Mac serves" "  ...nothing to download"
outsays "Nothing is fetched or tested" "  ...nothing fetched or tested"
grep -q 'Programs' "$W/out" && bad "  ...it says Auster's programs change" || ok "  ...and no change of Auster's programs"
outsays "The server answered, at 36.9 tokens a second, and refused a request with no key." "the server check made, and passed"
same "$(requests | grep -cE 'huggingface|cdn\.example|github\.com/ggml')" 0 "nothing asked of Hugging Face, its CDN or the engine's host"
same "$(requests | cut -d' ' -f2 | grep '^https:' | sed -E 's|/[^/]*$||' | sort -u | tr '\n' ' ')" \
  "https://api.github.com/repos/macaiport/auster/commits/heads https://codeload.github.com/macaiport/auster/tar.gz https://raw.githubusercontent.com/macaiport/auster/refs/heads/release " \
  "  ...nothing fetched but release's install.sh, GitHub's API and the tree"
for st in $(ls -d "$STUB_ENGINE_DIR"/starts/* | tail -n +$((n + 1))); do
  grep -qx -- --list-devices "$st/args" || [ "$(arg_after "$st" --port)" = 8484 ] || bad "a candidate engine was started: $(tr '\n' ' ' < "$st/args")"
done
ok "no candidate engine started for a test"
same "$(ls "$DATA/builds/$IR/kept" | wc -l | tr -d ' ')" 1 "one entry in kept/"
k=$(ls -d "$DATA/builds/$IR"/kept/* | head -n 1)
same "$(cat "$k")" "$s0" "  ...the old descriptor, byte for byte"
[[ ${k##*/} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z-$IB2$ ]] && ok "  ...named by the time and its build" || bad "  ...named ${k##*/}"
same "$(sed -n 2p "$S" | cut -f2)" "$IB2" "serving names the build it served: no other build is chosen"
same "$(sed -n 1,4p "$S")" "$(printf '%s\n' "$s0" | sed -n 1,4p)" "  ...its format line and three registry lines as they were"
same "$(launch)" "launch	2	32768	8484	36.9" "  ...with two people at 32,768, and the speed the check measured"
[ "$(stat -f %i "$S")" != "$i0" ] && ok "  ...rewritten by rename, not in place" || bad "serving was rewritten in place"
same "$(ls -d "$STUB_ENGINE_DIR"/starts/* | tail -n +$((n + 1)) | while read -r st; do grep -qx -- --list-devices "$st/args" || echo "$st"; done | wc -l | tr -d ' ')" 1 "the engine restarted once"
same "$(arg_after "$(newest_start)" -c) $(arg_after "$(newest_start)" -np)" "65536 2" "  ...on the new setting"
same "$(progs)" "$p0" "no program changed, though v0.2.0's differ"
same "$(cat "$DATA/_update/scripts")" "$stamp" "no stamp written"
same "$(cat "$DATA/builds/mac")" "$mac" "builds/mac as it was"
[ -z "$(ls -A "$DATA/builds/$IR/failed" 2>/dev/null)" ] && ok "nothing in failed/" || bad "failed/: $(ls "$DATA/builds/$IR/failed")"

# --- C4: the context chosen again for the number of people (the 36 GB Mac of T88: 15,360 each for four, 31,744 for two)
serving_put "$IB2" "$IMB" 4 15360 36.9
AU_GPU_MIB=27648 AU_RAM_BYTES=38654705664 ANSWERS=$'yes\n' auster people 2
same "$RC" 0 "a Mac whose figures give four people 15,360 each: auster people 2, exit 0"
outsays "  After       the same build, 2 people at a time, each with a context of 31,744 tokens," "  ...the question names 31,744 for two"
same "$(launch)" "launch	2	31744	8484	36.9" "  ...and serving holds two people at 31,744"
serving_put "$IB2" "$IMB" 2 32768 36.9

# --- the new setting fails its server check
i1=$(stat -f %i "$S")
engine_set 'ctx=98304' behaviour http500   # three people at 32,768
AU_SERVER_CHECK_SECS=4 ANSWERS=$'yes\n' auster people 3
same "$RC" 4 "a stub engine failing at three people: exit 4"
outsays "\`auster rollback\` goes back to what it served before" "  ...it names auster rollback"
same "$(launch)" "launch	3	32768	8484	0" "  ...serving holds the new setting with a speed of 0: nothing switches back"
[ "$(stat -f %i "$S")" != "$i1" ] && ok "  ...written by rename, not in place" || bad "  ...serving was written in place"
k=$(ls -d "$DATA/builds/$IR"/kept/* | tail -n 1)
same "$(sed -n 5p "$k" | cut -f1-4,6)" "launch	2	32768	8484	36.9" "  ...the setting before kept, as it was checked"
[ -z "$(ls -A "$DATA/builds/$IR/failed" 2>/dev/null)" ] && ok "  ...nothing in failed/" || bad "  ...failed/: $(ls "$DATA/builds/$IR/failed")"
same "$(cat "$DATA/_update/scripts")" "$stamp" "  ...no stamp written"

# --- auster rollback: back to two people, with a speed of 0 until its check passes; nothing held, nothing in failed/
model_in "$IMB"                                   # store/ holds the model it serves
engine_set 'ctx=65536' load 3                     # two people at 32,768: its server check waits a while
watch_serving "$IB2" 2 32768
ANSWERS=$'1\n' auster rollback
wait "$WATCH"
same "$RC" 0 "auster rollback: exit 0"
same "$(cat "$W/watched")" 0 "  ...serving at two people with a speed of 0 until its check passed"
same "$(launch)" "launch	2	32768	8484	36.9" "  ...then the speed the check measured"
[ -e "$DATA/builds/$IR/hold" ] && bad "  ...a hold written for the build itself: $(cat "$DATA/builds/$IR/hold")" || ok "  ...nothing held: the same build at another setting"
[ -z "$(ls -A "$DATA/builds/$IR/failed" 2>/dev/null)" ] && ok "  ...nothing in failed/" || bad "  ...failed/: $(ls "$DATA/builds/$IR/failed")"
engine_set 'ctx=65536' load 0
ANSWERS=$'no\n' auster rollback
same "$RC" 1 "auster rollback again, answered no: exit 1"
outsays "build $IB2 (standin-b.gguf), 3 people at 32,768 tokens each, served until " "  ...the three-person entry listed"
grep -F "3 people at 32,768 tokens each" "$W/out" | grep -qF ", the build it serves now, never checked" &&
  ok "  ...marked never checked" || bad "  ...not marked never checked: $(grep -F '3 people' "$W/out")"
engine_set 'ctx=98304' behaviour ok

# --- what changes nothing
s1=$(cat "$S"); k1=$(ls "$DATA/builds/$IR/kept")
ANSWERS=$'yes\n' auster people 5
same "$RC" 1 "auster people 5, above the recipe's four: exit 1"
outsays "The recipe household serves from 1 to 4 people at a time, so nothing was changed." "  ...it says the recipe's limit"
ANSWERS=$'no\n' auster people 1
same "$RC" 1 "auster people 1, answered no: exit 1"
outsays "Nothing was changed." "  ...it says so"
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
stale_lock "$DATA/builds/updating" "$live" "$(sysctl -n kern.bootsessionuuid)" "Thu Nov 20 10:00:00 2026"
rm -rf "$STUB_CURL_DIR/requests"
ANSWERS=$'yes\n' auster people 1
same "$RC" 1 "auster people 1 while a run holds the lock: exit 1"
outsays "Another run of Auster (process $live)" "  ...it names the run"
same "$(requests | wc -l | tr -d ' ')" 0 "  ...and fetches nothing"
{ kill "$live"; wait "$live"; } 2>/dev/null; rm -f "$DATA/builds/updating"
route_drop "$INSTALL_SH"; curl_route GET "$INSTALL_SH" 404 -
ANSWERS=$'yes\n' auster people 1
same "$RC" 1 "auster people 1, GitHub giving no installer: exit 1"
outsays "GitHub did not give Auster's installer (curl exit 0, answer 404), so nothing was changed." "  ...it says so"
same "$(cat "$S"):$(ls "$DATA/builds/$IR/kept")" "$s1:$k1" "serving and kept/ as they were after all four"
done_
