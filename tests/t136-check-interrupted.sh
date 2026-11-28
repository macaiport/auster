# T136 (the conventions' audit, 2026-11-28; B7, docs/conventions.md section 1, "A run's own temporary files"): an
# interrupted server check leaves no household key outside keys/. The check (B3 step 13) writes the key it asks with into a
# folder of its own in $TMPDIR, which the EXIT traps of bin/auster and of the driver delete on any exit. With the stub
# engine slow to answer (HTTP 503 for 60 s after each start), `auster restart`, and then a second paste whose serving has
# a speed of 0 (the driver's own check), are each sent TERM once the check has asked with the key: each ends 143, and no
# auster-check folder, no folder of Auster's at all, and no key is left anywhere under the test's own TMPDIR, while the
# stub curl's records show that the check did ask with a household key.
# Mutants: tests/mutants/T136a (bin/auster's EXIT trap leaves the folder), T136b (the driver's cleanup leaves it), T136c
# (the check's folder made by mktemp alone, as before the audit).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
cmd_install
T="$W/tmp"; mkdir -p "$T"; export TMPDIR="$T/"   # this test's own, so that whatever is left in it is these runs'
engine_up
cat "$DATA"/keys/k* "$DATA/keys/probe" 2>/dev/null | grep -E '^[0-9a-f]{32}$' | sort -u > "$W/keys"
same "$(wc -l < "$W/keys" | tr -d ' ')" 2 "two keys to look for: ipad's and Auster's own"

ours() { ls -A "$T" | grep '^auster-' | tr '\n' ' '; }   # Auster's temporary folders left in TMPDIR
asked() { grep -lF -f "$W/keys" "$STUB_CURL_DIR"/requests/*/headers 2>/dev/null | wc -l | tr -d ' '; }
wait_asked() { # N -> 0 once a request carrying a household key has been sent after the first N, with the check's folder
  # there (30 s at most)
  local i
  for i in $(seq 600); do
    [ "$(asked)" -gt "$1" ] && [ -n "$(ls -d "$T"/auster-check.* 2>/dev/null)" ] && return 0
    sleep 0.05
  done
  return 1
}

engine_set '*' load 60   # every request answered 503 for 60 s after each start: the check keeps asking

n=$(asked)
printf '' > "$W/answers"
HOME="$H" AU_TTY="$W/answers" AU_SCREEN="$W/screen" AU_SERVER_CHECK_SECS=60 /bin/bash "$DATA/bin/auster" restart > "$W/out" 2>&1 &
p=$!
wait_asked "$n" && ok "auster restart: its server check asked with a household key, from its folder in TMPDIR" ||
  bad "auster restart: no request with a key, or no check folder: $(cat "$W/out")"
kill -TERM "$p"; wait "$p"; rc=$?
same "$rc" 143 "auster restart, sent TERM during its server check: exit 143"
same "$(ours)" "" "  ...no folder of Auster's is left in TMPDIR"
same "$(grep -rlF -f "$W/keys" "$T" 2>/dev/null)" "" "  ...and no key in any file under it"
[ -e "$DATA/builds/updating" ] && bad "  ...the lock was left" || ok "  ...and the lock released"

speed_set 0   # A5: not checked since its switch, so a second paste starts the engine again and checks it
n=$(asked)
( repaste ''; echo "$RC" > "$W/rc" ) &
up=$!
wait_asked "$n" && ok "a second paste: the driver's server check asked with a household key" ||
  bad "a second paste: no request with a key, or no check folder: $(cat "$W/out")"
p=$(cut -f2 "$DATA/builds/updating" 2>/dev/null)
/bin/ps -p "$p" -o command= 2>/dev/null | grep -q 'driver\.sh' && ok "  ...the lock names the driver" ||
  bad "  ...the lock names $p: $(/bin/ps -p "$p" -o command= 2>/dev/null)"
kill -TERM "$p"; wait "$up"
same "$(cat "$W/rc")" 143 "  ...sent TERM during its check, the pasted line ends with the driver's 143"
same "$(ours)" "" "  ...no folder of Auster's is left in TMPDIR (the check's, the run's and the installer's)"
same "$(grep -rlF -f "$W/keys" "$T" 2>/dev/null)" "" "  ...and no key in any file under it"
engine_set '*' load 0
done_
