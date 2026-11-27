# T85: `auster remove` (B8), after an install that added its line to ~/.zprofile (B6). Answered no at the second
# question, with the engine running, the check job switched off in Login Items and a builds/stopped left from
# before: both jobs booted out, their disabled marks cleared (launchctl enable) and their files deleted,
# builds/stopped gone, the engine stopped, the marked line gone from ~/.zprofile with every other line byte for
# byte as it was (one of them names Auster too), and the data root otherwise unchanged. No answer at the second
# question keeps the files too. Answered yes: the home folder equals its snapshot from before the install.
# Mutants: tests/mutants/T85a and T85b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
install_env
cmd_hook
printf '# my own note: Auster serves the family; type auster status to see it\n' >> "$H/.zprofile"
cp "$H/.zprofile" "$W/zprofile-before"
home0=$(snapshot "$H")
line='export PATH="$HOME/Library/Application Support/Auster/bin:$PATH"   # added by Auster; auster remove removes this line'

run_install $'no\nyes\nipad\nyes\n' "$IR"
same "$RC" 0 "the install, yes to the line in ~/.zprofile"
{ cat "$W/zprofile-before"; printf '%s\n' "$line"; } > "$W/zprofile-with"
cmp -s "$H/.zprofile" "$W/zprofile-with" && ok "the line is added at the end of ~/.zprofile, the rest as it was" || bad "~/.zprofile: $(cat "$H/.zprofile")"
same "$(stat -f %Lp "$H/.zprofile")" "$(stat -f %Lp "$W/zprofile-before")" "~/.zprofile keeps its mode"
for i in $(seq 100); do engine_alive && break; sleep 0.1; done
engine_alive && ok "the engine runs" || bad "no engine runs"
epid=$(cat "$STUB_LAUNCHCTL_DIR/pids/$EJOB" 2>/dev/null)
printf 'auster-record 1\thousehold\t2026-11-26T08:00:00Z\n' > "$DATA/builds/stopped"   # a stopped left from before
launchctl disable "gui/$UIDN/$CJOB"   # the check job switched off in Login Items, as macOS does it
data0=$(snapshot "$DATA" | grep -v '	builds/stopped$' | awk -F'\t' -v OFS='\t' '$3 ~ /^logs\// { $2 = "-" } { print }')

ANSWERS=$'yes\nno\n' auster remove
same "$RC" 0 "remove, no at the second question: exit 0"
outsays "The files are kept." "it says the files are kept"
outsays "What is left, in $DATA:" "it listed what is left"
loaded "$EJOB" || loaded "$CJOB" && bad "a job is still loaded" || ok "both jobs are booted out"
same "$(override "$EJOB") $(override "$CJOB")" "enabled enabled" "neither label is left disabled"
same "$(ls -A "$H/Library/LaunchAgents")" "" "both job files are deleted"
[ -e "$DATA/builds/stopped" ] && bad "builds/stopped is left" || ok "builds/stopped is gone"
engine_alive && bad "the engine still runs" || ok "the engine is stopped"
[ -n "$epid" ] && kill -0 "$epid" 2>/dev/null && bad "the engine's process $epid is alive" || ok "its process is gone"
cmp -s "$H/.zprofile" "$W/zprofile-before" && ok "~/.zprofile is as it was, byte for byte: the other line naming Auster kept" || bad "~/.zprofile: $(cat "$H/.zprofile")"
same "$(stat -f %Lp "$H/.zprofile")" "$(stat -f %Lp "$W/zprofile-before")" "~/.zprofile keeps its mode"
same "$(snapshot "$DATA" | awk -F'\t' -v OFS='\t' '$3 ~ /^logs\// { $2 = "-" } { print }')" "$data0" "the data root is otherwise unchanged"

ANSWERS=$'yes\n' auster remove
same "$RC" 0 "remove, no answer at the second question: exit 0"
[ -f "$DATA/.auster-data-root" ] && ok "no answer keeps the files" || bad "no answer deleted the data root"

ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "remove, yes twice: exit 0"
outsays "Auster is removed from this Mac." "it says Auster is removed"
same "$(snapshot "$H")" "$home0" "the home folder equals its snapshot from before the install"
done_
