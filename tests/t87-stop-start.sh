# T87: `auster stop` and `auster start` (B6). Stop is launchctl disable, then bootout, so that it lasts across a
# simulated login, and builds/stopped says household. While stopped, `update`, `restart`, `people`, `key add`
# and `key revoke` refuse, name `auster start`, and leave the engine stopped and keys/ as it was; `status`,
# `key show`, `verify`, `network` and `rollback` are not refused for it. Start is enable, then bootstrap; it
# deletes builds/stopped and makes the server check, and a start whose check is not answered leaves no stopped
# behind (exit 4, naming `auster status`). Mutants: tests/mutants/T87a, T87b and T87c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
calls() { tail -n +$(($1 + 1)) "$STUB_LOG" | grep '^launchctl \(enable\|disable\|bootstrap\|bootout\|kickstart\)' | cut -d' ' -f1-2 | tr '\n' ' '; }

n=$(wc -l < "$STUB_LOG")
auster start
same "$RC" 0 "start: exit 0 after a passed check"
same "$(calls "$n")" "launchctl enable launchctl bootstrap " "start: enable, then bootstrap"
engine_alive && ok "start: the engine runs" || bad "start: no engine"

n=$(wc -l < "$STUB_LOG")
auster stop
same "$RC" 0 "stop: exit 0"
same "$(calls "$n")" "launchctl disable launchctl bootout " "stop: disable, then bootout"
same "$(override "$EJOB")" disabled "stop: the engine's label is disabled"
loaded "$EJOB" && bad "stop: the engine's job is still loaded" || ok "stop: the engine's job is booted out"
engine_alive && bad "stop: the engine still runs" || ok "stop: the engine is stopped"
same "$(cut -f1,2 "$DATA/builds/stopped")" "auster-record 1	household" "stop: builds/stopped says household"
login
loaded "$EJOB" && bad "a login started the engine's job again" || ok "a simulated login leaves the engine stopped"
loaded "$CJOB" && ok "and the check job loaded" || bad "the check job is not loaded"

cp "$DATA/builds/stopped" "$W/stopped"
keys0=$(snapshot "$DATA/keys")
for c in update restart 'people 2' 'key add ipad2' 'key revoke ipad'; do
  auster $c
  same "$RC" 1 "while stopped, $c: refused"
  outsays '`auster start` starts it' "while stopped, $c: it names auster start"
  loaded "$EJOB" || engine_alive && bad "while stopped, $c: the engine was started" || ok "while stopped, $c: the engine stays stopped"
  cmp -s "$DATA/builds/stopped" "$W/stopped" && ok "while stopped, $c: builds/stopped as it was" || bad "while stopped, $c: builds/stopped changed"
done
same "$(snapshot "$DATA/keys")" "$keys0" "while stopped: keys/ as it was"
for c in status 'key show ipad' verify network rollback; do
  auster $c
  grep -q 'Nothing is done while it is stopped' "$W/out" && bad "while stopped, $c: refused" || ok "while stopped, $c: not refused for it"
done
auster status; same "$RC" 0 "while stopped, status: exit 0"
auster verify; same "$RC" 0 "while stopped, verify: exit 0, every file the registry's"
auster network; same "$RC" 0 "while stopped, network: exit 0"
same "$(sed -n 6p "$DATA/builds/mac")" "router	00:00:5e:00:53:01" "network: the router recorded, in the record's form"

n=$(wc -l < "$STUB_LOG")
auster start
same "$RC" 0 "start: exit 0"
same "$(calls "$n")" "launchctl enable launchctl bootstrap " "start: enable, then bootstrap"
[ -e "$DATA/builds/stopped" ] && bad "start: builds/stopped is left" || ok "start: builds/stopped is deleted"
engine_alive && ok "start: the engine runs" || bad "start: no engine"

auster stop
same "$RC" 0 "stopped again"
engine_set '*' behaviour nolisten
AU_SERVER_CHECK_SECS=4 auster start
same "$RC" 4 "a start whose check is not answered: exit 4"
outsays '`auster status` says how' "it names auster status"
[ -e "$DATA/builds/stopped" ] && bad "a failed start left builds/stopped: $(cat "$DATA/builds/stopped")" || ok "a failed start leaves no builds/stopped"
engine_set '*' behaviour ok
done_
