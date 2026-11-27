# T75: the job files, read with plutil (B4, B5). The engine's: KeepAlive, ProcessType Interactive,
# ThrottleInterval 30, an environment of PATH only, its program and logs/ by whole paths. The check's:
# RunAtLoad, StartCalendarInterval at minute 7 of hours 0, 4, 8, 12, 16 and 20, ProcessType Background, no
# KeepAlive and no StartInterval. Both pass plutil -lint. Mutants: tests/mutants/T75a and T75b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
e="$H/Library/LaunchAgents/local.auster.engine.plist" c="$H/Library/LaunchAgents/local.auster.check.plist"
x() { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }
for f in "$e" "$c"; do
  if plutil -lint "$f" > /dev/null 2>&1; then ok "${f##*/} passes plutil -lint"; else bad "${f##*/}: $(plutil -lint "$f" 2>&1)"; fi
done

same "$(x "$e" Label)" local.auster.engine "the engine's Label"
same "$(x "$e" ProgramArguments) $(x "$e" ProgramArguments.0) $(x "$e" ProgramArguments.1)" "2 /bin/bash $DATA/jobs/auster-engine" "the engine's program: /bin/bash and jobs/auster-engine"
same "$(x "$e" KeepAlive)" true "the engine's KeepAlive is true"
same "$(x "$e" ProcessType)" Interactive "the engine's ProcessType is Interactive"
same "$(x "$e" ThrottleInterval)" 30 "the engine's ThrottleInterval is 30"
same "$(plutil -extract EnvironmentVariables json -o - "$e")" '{"PATH":"\/usr\/bin:\/bin:\/usr\/sbin:\/sbin"}' "the engine's environment holds PATH only"
same "$(x "$e" StandardOutPath) $(x "$e" StandardErrorPath)" "$DATA/logs/engine.log $DATA/logs/engine.log" "the engine's logs are in logs/"
x "$e" RunAtLoad > /dev/null && bad "the engine's job has RunAtLoad" || ok "the engine's job has no RunAtLoad (KeepAlive starts it)"

same "$(x "$c" Label)" local.auster.check "the check's Label"
same "$(x "$c" ProgramArguments.0) $(x "$c" ProgramArguments.1)" "/bin/bash $DATA/jobs/auster-check" "the check's program: /bin/bash and jobs/auster-check"
same "$(x "$c" RunAtLoad)" true "the check's RunAtLoad is true"
same "$(x "$c" StartCalendarInterval)" 6 "the check fires at six times a day"
when=
for i in 0 1 2 3 4 5; do when+="$(x "$c" "StartCalendarInterval.$i.Hour"):$(x "$c" "StartCalendarInterval.$i.Minute") "; done
same "$when" "0:7 4:7 8:7 12:7 16:7 20:7 " "at seven minutes past every fourth hour"
for i in 0 1 2 3 4 5; do
  same "$(plutil -extract "StartCalendarInterval.$i" json -o - "$c" | tr -cd ',' | wc -c | tr -d ' ')" 1 "firing $i has two keys, Hour and Minute"
done
same "$(x "$c" ProcessType)" Background "the check's ProcessType is Background"
x "$c" KeepAlive > /dev/null && bad "the check has KeepAlive" || ok "the check has no KeepAlive"
x "$c" StartInterval > /dev/null && bad "the check has StartInterval" || ok "the check has no StartInterval"
same "$(x "$c" StandardOutPath) $(x "$c" StandardErrorPath)" "$DATA/logs/check.log $DATA/logs/check.log" "the check's logs are in logs/"
done_
