# T114: `auster restart`, `auster key add` and `auster key revoke` make the server check (B6, B3 step 13) after
# the engine's restart, and exit 0 when it passes and 4 otherwise. A request with no key answered after any of
# them stops the engine as T107 says (disable, then bootout; builds/stopped says open) and names `auster start`;
# not answered names `auster status` and stops nothing. `key add` shows the new key only after a passed check.
# Mutants: tests/mutants/T114a, T114b and T114c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up

passed() { # LABEL: after the command, a passed check
  same "$RC" 0 "$1: exit 0"
  outsays "The server answered" "$1: the check passed"
  [ -e "$DATA/builds/stopped" ] && bad "$1: builds/stopped was written" || ok "$1: no builds/stopped"
  engine_alive && ok "$1: the engine runs" || bad "$1: no engine"
}
open_() { # LABEL: after the command, a request with no key was answered
  same "$RC" 4 "$1, open: exit 4"
  outsays '`auster start`, which starts it' "$1, open: it names auster start"
  same "$(cut -f1,2 "$DATA/builds/stopped" 2>/dev/null)" "auster-record 1	open" "$1, open: builds/stopped says open"
  same "$(override "$EJOB")" disabled "$1, open: the engine's label is disabled"
  loaded "$EJOB" && bad "$1, open: the engine's job is still loaded" || ok "$1, open: and booted out"
  engine_alive && bad "$1, open: the engine still runs" || ok "$1, open: the engine is stopped"
  engine_set '*' behaviour ok
  auster start; same "$RC" 0 "$1, open: auster start, the engine answering as it should, passes"
}
unanswered() { # LABEL: after the command, the keyed question was not answered
  same "$RC" 4 "$1, not answered: exit 4"
  outsays '`auster status` says how' "$1, not answered: it names auster status"
  [ -e "$DATA/builds/stopped" ] && bad "$1, not answered: builds/stopped was written" || ok "$1, not answered: no builds/stopped"
  engine_set '*' behaviour ok
  auster restart; same "$RC" 0 "$1, not answered: a restart, the engine answering as it should, passes"
}

n=$(starts); auster restart; passed "restart"
same "$(starts)" $((n + 1)) "restart: the engine was started again"
engine_set '*' behaviour open; auster restart; open_ "restart"
engine_set '*' behaviour nolisten; AU_SERVER_CHECK_SECS=4 auster restart; unanswered "restart"

: > "$W/screen"; auster key add ipad2; passed "key add"
same "$(qr_texts "$W/screen")" "$(key_of ipad2)" "key add, passed: the new key shown"
engine_set '*' behaviour open; : > "$W/screen"; auster key add ipad3
same "$(qr_texts "$W/screen")" "" "key add, open: the new key is not shown"
outsays '`auster key show ipad3` shows it' "key add, open: it says how to show it later"
[ -n "$(key_of ipad3)" ] && ok "key add, open: the key is made" || bad "key add, open: no key"
open_ "key add"
engine_set '*' behaviour nolisten; : > "$W/screen"; AU_SERVER_CHECK_SECS=4 auster key add ipad4
same "$(qr_texts "$W/screen")" "" "key add, not answered: the new key is not shown"
unanswered "key add"

auster key revoke ipad3; passed "key revoke"
engine_set '*' behaviour open; auster key revoke ipad4; open_ "key revoke"
engine_set '*' behaviour nolisten; AU_SERVER_CHECK_SECS=4 auster key revoke ipad2; unanswered "key revoke"
same "$(cat "$DATA"/keys/k*.name | sort | tr '\n' ' ')" "ipad " "the keys left: ipad's"
done_
