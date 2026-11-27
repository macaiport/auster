# T65 (U4; B3, D3.6): a second paste is an update. After a full install, with the engine serving on 8484, pasting the
# line again prints OK for the recipe and changes nothing but logs/: no job loaded, booted out, kickstarted, enabled or
# disabled, the engine's process and start the same, every key file byte for byte as it was, no QR code shown, and the
# port kept though the stub says something answers there (our own engine); nothing is fetched but GitHub's API and the
# tree. While the engine is stopped (`auster stop`), a paste refuses and names `auster start` (B6). Then, after
# `auster remove`, an install whose server check is not answered (exit 4: the keys made but not shown, no stamp), and
# the line pasted again with the engine answering: the run checks the server (its serving has a speed of 0), shows the
# key the first run made and never showed, and writes the stamp.
# Mutants: tests/mutants/T65a (rewrite and reload the jobs), T65b (regenerate keys), T65c (choose the port again),
# T65d (show only the keys minted in this run, as step 14 does: none), T65e (update while stopped).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
before=$(data_snap); agents=$(snapshot "$H/Library/LaunchAgents"); zp=$(cat "$H/.zprofile")
pid=$(engine_pid); port=$(cat "$STUB_ENGINE_DIR/ports/8484")
n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; : > "$W/screen"
nc -z 127.0.0.1 8484 && ok "the stub says something answers on 8484" || bad "nothing answers on 8484"
repaste ''
same "$RC" 0 "a second paste after a full install: exit 0"
says "The recipe household: OK. Build $IB1 serves it, for 4 people at 32,768 tokens each." "it prints OK for the recipe"
same "$(data_snap)" "$before" "nothing in the data root changed but logs/ (serving's port 8484 among it)"
same "$(snapshot "$H/Library/LaunchAgents"):$(cat "$H/.zprofile")" "$agents:$zp" "the job files and ~/.zprofile as they were"
same "$(job_calls "$n")" "" "no job loaded, booted out, kickstarted, enabled or disabled"
same "$(engine_pid)" "$pid" "the engine's process is the same"
same "$(cat "$STUB_ENGINE_DIR/ports/8484" 2>/dev/null)" "$port" "  ...with the same start"
same "$(wc -c < "$W/screen" | tr -d ' ')" 0 "no QR code shown"
says_not "Testing the build" "no test run"
same "$(requests | cut -d' ' -f2 | sed -E 's|/[^/]*$||' | sort -u)" "https://api.github.com/repos/macaiport/auster/commits/heads
https://codeload.github.com/macaiport/auster/tar.gz" "nothing fetched but GitHub's API and the tree"
auster stop
before=$(data_snap)
repaste ''
same "$RC" 1 "a second paste while the engine is stopped: exit 1"
says '`auster start` starts it' "  ...it names auster start"
says_not "OK." "  ...and judges no recipe"
same "$(data_snap)" "$before" "  ...the data root as it was but logs/"
auster start
same "$RC" 0 "auster start"

# --- a re-paste after a first install's exit 4
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "auster remove, everything deleted"
engine_set 'port=8484' behaviour nolisten
rm -rf "$STUB_ENGINE_DIR/ports/8484"; : > "$W/screen"
printf '%s' $'no\nyes\nipad\n' > "$W/answers"
HOME="$H" AU_TTY="$W/answers" AU_SERVER_CHECK_SECS=4 /bin/bash -c "$(cat "$ROOT/install.sh")" auster-install "$IR" > "$W/out" 2>&1; RC=$?
same "$RC" 4 "an install whose server check is not answered: exit 4"
says "The device keys are made but not shown" "  ...the keys are made but not shown"
same "$(wc -c < "$W/screen" | tr -d ' ')" 0 "  ...and no QR code is drawn"
[ -e "$DATA/_update/scripts" ] && bad "  ...a stamp was written" || ok "  ...and no stamp"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f6)" 0 "  ...serving's speed is 0"
key=$(key_of ipad)
engine_set 'port=8484' behaviour ok
repaste $'\n'
same "$RC" 0 "the line pasted again, the engine answering: exit 0"
says "The recipe household: OK." "  ...it prints OK for the recipe"
says "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...it checks the server, since serving's speed was 0"
says "The install is finished: the key for the device ipad is shown now." "  ...it says it shows the key the first run made"
same "$(qr_texts "$W/screen")" "$key" "  ...and the QR code drawn holds ipad's key, and nothing else"
same "$(cut -f1,2,3 "$DATA/_update/scripts" 2>/dev/null)" "auster-record 1	release	v0.1.0" "  ...and the stamp is written"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f6)" 36.9 "  ...with the speed in serving"
same "$(key_of ipad)" "$key" "  ...the key the same"
done_
