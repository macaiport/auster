# T83: the QR code (B7). After an install (B3 step 14) and an `auster key show`, no key appears in any stub's
# logged arguments (STUB_LOG: osascript's among them, the drawing program's source with them), in logs/, in what
# the installer printed, or in any file the install wrote outside keys/; the code itself goes to the terminal
# (AU_SCREEN) only, never to standard output. The drawing program gets the key on its input: the key is in none
# of its arguments, yet the code it draws reads back (tests/qr-read.js) as exactly the key. The code is drawn on
# the alternate screen, and the screen and scrollback are erased only after the person says they are done:
# `key show` is answered through a pipe, and nothing is erased while it waits. Mutants: tests/mutants/T83a, T83b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
cp "$W/out" "$W/install-out"; cp "$W/screen" "$W/install-screen"
key=$(key_of ipad) probe=$(cat "$DATA/keys/probe")
printf '%s\n' "$key" "$probe" > "$W/keys"
ESC=$'\033'

nowhere() { # LABEL -> ok when no key is in STUB_LOG, logs/, the install's output, or a file the install wrote
  local hits
  hits=$( { grep -lF -f "$W/keys" "$STUB_LOG" "$W/install-out" "$DATA"/logs/* 2>/dev/null
            grep -rlF -f "$W/keys" --exclude-dir=keys "$H" 2>/dev/null; } | sort -u)
  same "$hits" "" "$1: no key in STUB_LOG, logs/, the install's output, or a file it wrote outside keys/"
}

# The install's step 14
nowhere "after the install"
grep -qF "$ESC[38;5;16;48;5;231m" "$W/install-out" && bad "the install printed a QR code on its standard output" || ok "the install's standard output holds no QR code"
same "$(qr_texts "$W/install-screen")" "$key" "the install drew ipad's key, as a code that reads back as the key"
grep -qF "$ESC[?1049h" "$W/install-screen" && grep -qF "$ESC[3J" "$W/install-screen" && ok "on the alternate screen, the scrollback erased after it" || bad "install screen: $(cat -v "$W/install-screen" | head -3)"
grep 'osascript' "$STUB_LOG" | grep -q 'CIQRCodeGenerator' && ok "the drawing program ran" || bad "no drawing program in STUB_LOG"

# `auster key show`, answered through a pipe
mkfifo "$W/tty"
exec 5<> "$W/tty"
: > "$W/scr"
HOME="$H" AU_TTY="$W/tty" AU_SCREEN="$W/scr" /bin/bash "$DATA/bin/auster" key show ipad > "$W/show-out" 2>&1 &
pid=$!
for i in $(seq 150); do grep -qF "Press Return when ipad has read it" "$W/scr" 2>/dev/null && break; sleep 0.1; done
grep -qF "Press Return when ipad has read it" "$W/scr" && ok "key show: it asks the person to say when the device has read the code" || bad "key show: no question: $(cat -v "$W/scr" | head -5)"
sleep 0.5
kill -0 "$pid" 2>/dev/null && ok "key show: it waits for the answer" || bad "key show: it did not wait"
cp "$W/scr" "$W/scr-waiting"
grep -qF "$ESC[?1049h" "$W/scr-waiting" && ok "key show: the code is on the alternate screen" || bad "key show: no alternate screen"
same "$(qr_texts "$W/scr-waiting")" "$key" "key show: the code reads back as ipad's key"
grep -qF "$ESC[3J" "$W/scr-waiting" && bad "key show: the scrollback was erased before the person was done" || ok "key show: nothing is erased while it waits"
grep -qF "$ESC[?1049l" "$W/scr-waiting" && bad "key show: it left the alternate screen before the person was done" || ok "key show: it stays on the alternate screen while it waits"
printf '\n' >&5
for i in $(seq 100); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
kill -0 "$pid" 2>/dev/null && { kill "$pid"; bad "key show: it did not end after the answer"; }
wait "$pid"; rc=$?
exec 5>&-
same "$rc" 0 "key show: exit 0"
tail -c 64 "$W/scr" | grep -qF "$ESC[2J$ESC[?1049l$ESC[3J" && ok "key show: after the answer, the screen erased, the alternate screen left and the scrollback erased" || bad "key show: the end of the screen: $(tail -c 64 "$W/scr" | cat -v)"
grep -qF "$ESC[38;5;16;48;5;231m" "$W/show-out" && bad "key show printed the code on its standard output" || ok "key show's standard output holds no code"
grep -qF -f "$W/keys" "$W/show-out" && bad "key show printed a key" || ok "key show's standard output holds no key"
args=$(grep '^osascript' "$STUB_LOG" | grep -F -f "$W/keys")
same "$args" "" "the drawing program's arguments and source hold no key: it had the key on its input"
nowhere "after key show"
done_
