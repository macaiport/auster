# T135 (docs/plans/backup.md, sections 1 to 5 and 7; BK1, BK2): the model and the engine are kept out of Time Machine.
# The stub tmutil first (tests/stubs/tmutil): an existing folder is left out silently, exit 0; any other path gets the
# real error on standard error and `Command exited with status 100002.` on standard output, exit 162; STUB_TMUTIL_FAIL=1
# fails every path that way; another verb or an option is not answered. Then: a first install asks `tmutil
# addexclusion` once, for exactly the data root's store/ and engines/ (not the data root, not keys/, not builds/), and
# its question shows section 5's Backups line with the model's and the archive's size; a second paste, `install.sh
# update` and `auster people` each ask again, once; `install.sh --check` asks nothing and its question still shows
# section 5's line; a run refused for a held lock, and one refused for a record of a newer format, ask nothing. With
# STUB_TMUTIL_FAIL=1, an update, a second paste and `auster people` each say section 4's sentence once, straight after
# step 3, and go on to exit 0, with no path and none of tmutil's output on screen. A restored Mac: store/ and engines/
# deleted whole after the install; an update makes both again and asks for them, names the model, the engine's archive,
# its unpacked files, the template, the system prompt and the test in its question, and on a yes fetches the model and
# the archive, unpacks the engine, passes its server check, exit 0. Last, after `auster remove`, a first install with
# STUB_TMUTIL_FAIL=1: its question shows section 4's line with "about" and the size, never section 5's, and it goes on
# to its end, exit 0, with no path and none of tmutil's output on screen.
# Mutants: tests/mutants/T135a (leave out the whole data root), T135b (stop the run when tmutil fails), T135c (ask only
# when this run made a folder), T135d (ask before the folders exist), T135e (print tmutil's own output), T135f (ask in
# --check too), T135g (section 5's line when the call failed).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install   # the first install, with the stub tmutil leaving out what it is asked to; its output in $W/out
same "$(command -v tmutil)" "$TESTS/stubs/tmutil" "tmutil on PATH is the stub, never the real one"
E=$(stat -f %z "$FX/engine.tar.gz")
commas() { local n=$1 o=; while [ ${#n} -gt 3 ]; do o=",${n: -3}$o"; n=${n:0:${#n}-3}; done; printf '%s' "$n$o"; }
SIZE="$(commas $((3400 + E))) bytes"   # order 1: model A and the engine's archive, as au_bytes gives them
ASK="tmutil addexclusion $DATA/store $DATA/engines"
SAID="Time Machine could not be told to leave out the model and the engine, so it may back them up."
mark() { N=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; }
asked() { tail -n +$((N + 1)) "$STUB_LOG" | grep '^tmutil'; }   # the tmutil calls since the mark
quiet() { # LABEL -> no path tmutil names, and none of its output, on screen
  says_not "Error (100002)" "$1: none of tmutil's errors on screen"
  says_not "Command exited with status" "$1: nor its line on standard output"
  says_not "$DATA/store" "$1: no path of store/ on screen"
  says_not "$DATA/engines" "$1: nor of engines/"
}
section5() { # LABEL -> the question's Backups line says Time Machine leaves them out, and never that it could not
  says "  Backups     Time Machine leaves out the model and the engine ($SIZE): a Mac restored from a backup" "$1: the question's Backups line, with the model's and the archive's size"
  says "              fetches them again when the installer line is pasted." "$1: ...and what a restored Mac does"
  says_not "could not be told" "$1: ...and never that it could not be told"
}

# --- the first install, already made by update_install
same "$(grep '^tmutil' "$STUB_LOG")" "$ASK" "a first install asks once, for exactly store/ and engines/"
section5 "a first install"
q=$(grep -n 'Backups     ' "$W/out" | head -n 1 | cut -d: -f1); y=$(grep -n 'Install for 4 people' "$W/out" | head -n 1 | cut -d: -f1)
[ -n "$q" ] && [ -n "$y" ] && [ "$q" -lt "$y" ] && ok "  ...said in the question, before the yes" || bad "  ...the Backups line at line $q, the question's yes at $y"
quiet "a first install"

# --- the stub, by its own path
T="$TESTS/stubs/tmutil"; mkdir -p "$W/tm/dir"; mark
o=$("$T" addexclusion "$W/tm/dir" 2>&1); same "$?:$o" "0:" "stub tmutil: an existing folder, exit 0, nothing said"
"$T" addexclusion "$W/tm/dir" "$W/tm/none" > "$W/tm/o" 2> "$W/tm/e"; same "$?" 162 "stub tmutil: a path that does not exist, exit 162"
same "$(cat "$W/tm/e")" "$W/tm/none: Error (100002) while attempting to change exclusion setting." "  ...the real error on standard error, for that path alone"
same "$(cat "$W/tm/o")" "Command exited with status 100002." "  ...and tmutil's line on standard output"
STUB_TMUTIL_FAIL=1 "$T" addexclusion "$W/tm/dir" > "$W/tm/o" 2> "$W/tm/e"
same "$?:$(cat "$W/tm/o"):$(cat "$W/tm/e")" "162:Command exited with status 100002.:$W/tm/dir: Error (100002) while attempting to change exclusion setting." \
  "stub tmutil: STUB_TMUTIL_FAIL=1 fails an existing folder too"
"$T" isexcluded "$W/tm/dir" > /dev/null 2>&1; same "$?" 99 "stub tmutil: another verb is not answered"
"$T" addexclusion -p "$W/tm/dir" > /dev/null 2>&1; same "$?" 99 "stub tmutil: an option is not answered"
same "$(asked | wc -l | tr -d ' ')" 5 "stub tmutil: each call logged"

# --- a second paste, an update and `auster people` ask again
engine_up
mark; repaste ''
same "$RC" 0 "a second paste: exit 0"
same "$(asked)" "$ASK" "  ...asks again, once, for store/ and engines/"
says_not "$SAID" "  ...and says nothing of it"
mark; update_run ''
same "$RC" 0 "install.sh update: exit 0"
same "$(asked)" "$ASK" "  ...asks again, once"
mark; ANSWERS= auster people 4
same "$RC" 0 "auster people 4: exit 0"
same "$(asked)" "$ASK" "  ...asks again, once"

# --- --check asks nothing, and its question still says what an install would
mark; run_install '' --check "$IR"
same "$RC" 0 "install.sh --check: exit 0"
same "$(asked)" "" "  ...asks tmutil nothing"
section5 "  --check"

# --- refused at the lock, or for a newer record: nothing asked
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
stale_lock "$DATA/builds/updating" "$live" "$(sysctl -n kern.bootsessionuuid)" "Thu Nov 20 10:00:00 2026"
mark; repaste ''
same "$RC" 1 "a second paste while another run holds the lock: exit 1"
says "Another run of Auster (process $live) is installing, updating or changing the server." "  ...refused at the lock"
same "$(asked)" "" "  ...asks tmutil nothing"
kill "$live" 2>/dev/null; wait "$live" 2>/dev/null; rm -f "$DATA/builds/updating"; : > "$STUB_PS_TABLE"
cp -p "$DATA/builds/mac" "$W/mac"
printf 'auster-record 2\ngpu-mib\t53084\n' > "$DATA/builds/mac"
mark; repaste ''
same "$RC" 1 "a second paste meeting a record of a newer format: exit 1"
says "$DATA/builds/mac was written by a newer version of Auster" "  ...refused for it"
same "$(asked)" "" "  ...asks tmutil nothing"
cp -p "$W/mac" "$DATA/builds/mac"

# --- tmutil failing: said once after step 3, and the run goes on
failed() { # LABEL -> exit 0, asked once, section 4's sentence once and before step 4's measuring, nothing of tmutil's
  same "$RC" 0 "$1: exit 0"
  same "$(asked)" "$ASK" "  ...tmutil was asked, once"
  same "$(grep -cF "$SAID" "$W/out")" 1 "  ...section 4's sentence, once"
  s=$(grep -nF "$SAID" "$W/out" | head -n 1 | cut -d: -f1); m=$(grep -n 'Measuring this Mac' "$W/out" | head -n 1 | cut -d: -f1)
  [ -n "$s" ] && [ -n "$m" ] && [ "$s" -lt "$m" ] && ok "  ...straight after step 3, before step 4 measures" || bad "  ...the sentence at line $s, the measuring at $m"
  quiet "  ..."
}
mark; STUB_TMUTIL_FAIL=1 update_run ''
failed "install.sh update, tmutil failing"
says "Auster v0.1.0 is on this Mac, and nothing else needed changing." "  ...to its end"
mark; STUB_TMUTIL_FAIL=1 repaste ''
failed "a second paste, tmutil failing"
mark; ANSWERS= STUB_TMUTIL_FAIL=1 auster people 4
failed "auster people 4, tmutil failing"

# --- a restored Mac: store/ and engines/ are not in the backup
rm -rf "$DATA/store" "$DATA/engines"
mark; update_run $'yes\n'
same "$RC" 0 "a restored Mac, store/ and engines/ deleted whole, an update answered yes: exit 0"
[ -d "$DATA/store" ] && [ -d "$DATA/engines" ] && same "$(stat -f %Lp "$DATA/store"):$(stat -f %Lp "$DATA/engines")" 700:700 "  ...both made again, mode 0700" ||
  bad "  ...store/ or engines/ not made again"
same "$(asked)" "$ASK" "  ...and asked for, once"
says "the model standin-a.gguf, which is missing: 3,400 bytes from Hugging Face ($REPO_A)" "  ...the question names the model"
says "the engine's archive, which is missing: $(commas "$E") bytes from GitHub" "  ...the engine's archive"
says "the engine's unpacked files, which are missing: unpacked again from its archive" "  ...its unpacked files"
says "the template, which is missing: from this version of Auster" "  ...the template"
says "the system prompt, which is missing: from this version of Auster" "  ...the system prompt"
says "the recipe's test, which is missing: from this version of Auster" "  ...and the test"
says_not "Backups" "  ...an update's question does not repeat the Backups line"
same "$(requests | grep -cxF "GET $URL_A")" 1 "  ...the model fetched"
same "$(requests | grep -cxF "GET $ENGINE_URL")" 1 "  ...the archive fetched"
same "$(shasum -a 256 < "$DATA/store/$SA" | cut -c1-64)" "$SA" "  ...model A whole in store/"
same "$(shasum -a 256 < "$DATA/store/$ESHA" | cut -c1-64)" "$ESHA" "  ...the archive whole in store/"
(cd "$ED/root" 2>/dev/null && find . \( -type f -o -type l \) -print | sed 's|^\./||' | LC_ALL=C sort | while IFS= read -r p; do
  if [ -L "$p" ]; then printf '%s\tlink\t%s\n' "$p" "$(readlink "$p")"; else printf '%s\t%s\t%s\n' "$p" "$(stat -f %z "$p")" "$(shasum -a 256 < "$p" | cut -c1-64)"; fi
done) | cmp -s - "$ED/files" && [ -x "$ED/root/llama-stub/llama-server" ] && ok "  ...the engine unpacked again, its files those its list names" ||
  bad "  ...engines/$ESHA is not whole: $(ls -R "$DATA/engines" 2>&1 | head -n 5)"
says "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...and its server check passed"
says "Auster v0.1.0 is on this Mac, and the update is finished." "  ...to its end"

# --- after `auster remove`, a first install with tmutil failing
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "auster remove, the files deleted"
[ -e "$DATA" ] && bad "  ...the data root is left" || ok "  ...the data root is gone"
mark; STUB_TMUTIL_FAIL=1 run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "a first install, tmutil failing: exit 0"
same "$(asked)" "$ASK" "  ...tmutil was asked, once"
says "  Backups     Time Machine could not be told to leave out the model and the engine, so it may back them up" "  ...the question's Backups line says it could not"
says "              (about $SIZE)." "  ...with about the model's and the archive's size"
says_not "Time Machine leaves out" "  ...and never that Time Machine leaves them out"
same "$(grep -c 'Time Machine' "$W/out")" 1 "  ...said once, in the question alone"
says "Auster is installed. On a device on the home network, open http://test-mac.local:8484/" "  ...and it goes on to its end"
quiet "  ..."
done_
