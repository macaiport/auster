# T106: `auster status` (B6) reports a job that `launchctl print-disabled` lists as disabled (switched off in
# Login Items, as macOS does it), the engine's or the check's, apart from the engine stopped by Auster itself,
# whose reason it gives from builds/stopped: household, open, or one that cannot be read. With nothing switched
# off it says nothing of the kind, and it names the devices and the check job's last probe.
# Mutant: tests/mutants/T106a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
auster start
same "$RC" 0 "the engine started"
AU_CHECK_LIMIT=5 check_job
OFF="switched off (System Settings, General, Login Items"

auster status
same "$RC" 0 "status: exit 0"
grep -qF "$OFF" "$W/out" && bad "with nothing switched off, status says a job is: $(cat "$W/out")" || ok "with nothing switched off, status says none is"
outsays "Devices with a key: ipad." "it names the devices"
outsays "The check job's last probe: the server answered, at 36.9 tokens a second (ok)." "it gives the check job's last probe"

launchctl disable "gui/$UIDN/$CJOB"
auster status
outsays "macOS has Auster's check job $OFF" "the check job switched off: status says so"
launchctl enable "gui/$UIDN/$CJOB"

launchctl disable "gui/$UIDN/$EJOB"
auster status
outsays "macOS has Auster's engine job $OFF" "the engine job switched off by macOS: status says so"
outsays '`auster start` switches it on again' "and that auster start switches it on"
grep -qF "The engine is stopped" "$W/out" && bad "it calls that a stop of Auster's" || ok "it does not call that a stop of Auster's"

auster start
same "$RC" 0 "started again"
auster stop
same "$RC" 0 "auster stop"
auster status
outsays "The engine is stopped: the household stopped it (auster stop)" "Auster's own stop: status gives the reason household"
grep -qF "engine job $OFF" "$W/out" && bad "Auster's own stop is reported as switched off by macOS" || ok "and does not report it as switched off by macOS"

printf 'auster-record 1\topen\t2026-11-26T08:00:00Z\n' > "$DATA/builds/stopped"
auster status
outsays "because it answered a request that carried no key" "stopped as open: status gives the reason open"
grep -qF "engine job $OFF" "$W/out" && bad "the open stop is reported as switched off by macOS" || ok "and does not report it as switched off by macOS"

rm -f "$DATA/builds/stopped"; mkdir "$DATA/builds/stopped"
auster status
outsays "The engine is stopped, for a reason that cannot be read" "stopped, unreadable: status says the reason cannot be read"
grep -qF "engine job $OFF" "$W/out" && bad "the unreadable stop is reported as switched off by macOS" || ok "and does not report it as switched off by macOS"
done_
