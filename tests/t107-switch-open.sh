# T107 (U5, U6; B3 step 13, B6): after a switch (`auster people 2`, a change of setting), a server that answers a request
# with no key is stopped at once, disable then bootout, builds/stopped says open, the run says so, names `auster rollback`
# and exits 4, and a simulated login starts nothing. While builds/stopped exists, saying open or unreadable, `update`,
# `people`, `restart`, `key add` and `key revoke` refuse and name `auster start`, and `start`, `rollback`, `status` and
# `key show` are not refused for it. `auster start` deletes builds/stopped, starts the engine, checks it, and while the
# server is still open stops it again and writes builds/stopped anew, exit 4 naming `auster start`; once the engine
# answers as it should, exit 0 and the switch's speed written. `auster rollback` while stopped (open) goes back, starts
# the engine with enable and bootstrap and checks it: still open, it is stopped again, exit 4 naming `auster start`;
# refusing a request with no key, builds/stopped is deleted, exit 0. The request with no key is sent only after the
# keyed question is answered, so that an engine still loading (HTTP 503) is not taken for an open one. At a first
# install an open server ends the run with exit 4, the keys made but not shown and no stamp.
# (t107-server-check-closed.sh holds the check's no-key rule, mutants T107f and T107g.)
# Mutants: tests/mutants/T107a (warn and leave it running), T107b (bootout without disable), T107c (start without the
# check), T107d (the request with no key before the keyed question is answered), T107e (refuse start while it says open),
# T107h (refuse rollback while stopped), T107i (rollback starting a stopped engine with kickstart -k).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
calls() { tail -n +$(($1 + 1)) "$STUB_LOG" | grep '^launchctl \(enable\|disable\|bootstrap\|bootout\|kickstart\)' | cut -d' ' -f1-2 | tr '\n' ' '; }
stopped_open() { # LABEL -> the engine stopped as T107 says, builds/stopped saying open
  same "$(cut -f1,2 "$DATA/builds/stopped" 2>/dev/null)" "auster-record 1	open" "$1: builds/stopped says open"
  same "$(override "$EJOB")" disabled "$1: the engine's label is disabled"
  loaded "$EJOB" && bad "$1: the engine's job is still loaded" || ok "$1: and booted out"
  engine_alive && bad "$1: the engine still runs" || ok "$1: the engine is stopped"
}

# --- after a switch
engine_set '*' behaviour open
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'yes\n' auster people 2
same "$RC" 4 "a switch whose server answers a request with no key: exit 4"
outsays "The server did not refuse a request that carried no key, so Auster stopped it." "  ...it says so"
outsays "\`auster rollback\` goes back to what it served before and starts it" "  ...and names auster rollback"
stopped_open "after the switch"
same "$(calls "$n")" "launchctl enable launchctl kickstart launchctl disable launchctl bootout " "  ...restarted, then disabled, then booted out"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f1-3,6)" "launch	2	32768	0" "  ...serving holds the switch, with a speed of 0"
login
loaded "$EJOB" && bad "a simulated login started the engine's job again" || ok "a simulated login leaves it stopped"

# --- while stopped: open, then unreadable
refused_while() { # LABEL
  local c
  for c in update restart 'people 1' 'key add ipad2' 'key revoke ipad'; do
    ANSWERS=$'yes\n' auster $c
    same "$RC" 1 "$1, $c: refused"
    outsays '`auster start` starts it' "$1, $c: it names auster start"
    loaded "$EJOB" || engine_alive && bad "$1, $c: the engine was started" || ok "$1, $c: the engine stays stopped"
  done
  for c in status 'key show ipad' rollback; do
    ANSWERS=$'\n' auster $c
    grep -q 'Nothing is done while it is stopped' "$W/out" && bad "$1, $c: refused" || ok "$1, $c: not refused for it"
  done
}
refused_while "stopped, open"
auster status
outsays "Auster stopped it at" "status, open: it says Auster stopped it"
cp "$DATA/builds/stopped" "$W/stopped-open"
printf 'a[$(touch f)]\n' > "$DATA/builds/stopped"
refused_while "stopped, unreadable"
cp "$W/stopped-open" "$DATA/builds/stopped"

# --- auster start, the server still open, then answering as it should
sleep 1
n=$(wc -l < "$STUB_LOG")
auster start
same "$RC" 4 "auster start, the server still open: exit 4"
outsays "It stays stopped until \`auster start\`, which starts it and checks it again." "  ...it names auster start"
same "$(calls "$n")" "launchctl enable launchctl bootstrap launchctl disable launchctl bootout " "  ...started, checked, and stopped again"
stopped_open "start, still open"
cmp -s "$DATA/builds/stopped" "$W/stopped-open" && bad "  ...builds/stopped is the old one" || ok "  ...builds/stopped written anew"
engine_set '*' behaviour ok
auster start
same "$RC" 0 "auster start, the server refusing a request with no key: exit 0"
[ -e "$DATA/builds/stopped" ] && bad "  ...builds/stopped is left" || ok "  ...builds/stopped deleted"
engine_alive && ok "  ...the engine runs" || bad "  ...no engine"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f6)" 36.9 "  ...and its check wrote the switch's speed"

# --- auster rollback while stopped: back, started with enable and bootstrap, and checked
engine_set '*' behaviour open
auster restart
same "$RC:$(cut -f2 "$DATA/builds/stopped" 2>/dev/null)" "4:open" "auster restart, the server open: exit 4, stopped again"
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'1\n' auster rollback
same "$RC" 4 "auster rollback while stopped, the server still open: exit 4"
outsays "It stays stopped until \`auster start\`, which starts it and checks it again." "  ...it names auster start"
same "$(calls "$n")" "launchctl enable launchctl bootstrap launchctl disable launchctl bootout " "  ...started, checked, and stopped again"
stopped_open "rollback, still open"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f1-3,6)" "launch	4	32768	0" "  ...back at four people, with a speed of 0"
engine_set '*' behaviour ok
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'1\n' auster rollback
same "$RC" 0 "auster rollback while stopped, the server refusing a request with no key: exit 0"
same "$(calls "$n")" "launchctl enable launchctl bootstrap " "  ...started with enable, then bootstrap"
[ -e "$DATA/builds/stopped" ] && bad "  ...builds/stopped is left" || ok "  ...builds/stopped deleted"
engine_alive && ok "  ...the engine runs" || bad "  ...no engine"
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f1-3,6)" "launch	2	32768	36.9" "  ...back at two people, its check passed"

# --- the request with no key only after the keyed question is answered
engine_set '*' load 3
auster restart
same "$RC" 0 "an engine that answers 503 while it loads: restart's check passes, not open"
[ -e "$DATA/builds/stopped" ] && bad "  ...builds/stopped was written" || ok "  ...no builds/stopped"
engine_set '*' load 0

# --- a first install
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "auster remove, everything deleted"
engine_set '*' behaviour open
: > "$W/screen"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 4 "a first install whose server answers a request with no key: exit 4"
says "The server did not refuse a request that carried no key, so Auster stopped it." "  ...it says so"
says "The device keys are made but not shown" "  ...the keys made but not shown"
same "$(wc -c < "$W/screen" | tr -d ' ')" 0 "  ...no QR code drawn"
[ -e "$DATA/_update/scripts" ] && bad "  ...a stamp was written" || ok "  ...no stamp"
stopped_open "a first install"
engine_set '*' behaviour ok
done_
