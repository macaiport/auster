# T119 (U9; B5 step 1, D3.4): the check job's first run, which launchd makes as soon as a first install loads it at
# B3 step 12 (RunAtLoad), finds no _update, since step 15 writes it a minute later, while the install holds
# builds/updating; its log then says that a run holds builds/, and not "the checks are off until the installer line is
# pasted again", which the first real install found it saying (docs/phase-2.md section 13). Here the stub launchctl runs
# the real check job to its end inside the install's step 12, with its output where its job file sends it. After the
# install, its next run makes its update check and says nothing of checks being off; with _update gone (moved to the
# Trash, D3.1) and no live run, it says the checks are off, which is then true; and with _update gone while another
# live run holds builds/updating, it says that a run holds builds/. A lock whose process is gone counts for nothing.
# Mutant: tests/mutants/T119a (the lock not read before _update is judged).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
install_env
trap 'engine_job_end; install_cleanup' EXIT
fixture_hook
cat > "$STUB_LAUNCHCTL_DIR/hooks/local.auster.check" <<'EOF'
#!/bin/bash
S=$STUB_LAUNCHCTL_DIR L=local.auster.check
[ "$1" = bootstrap ] || exit 0
plist=$(cat "$S/loaded/$L")
prog=$(/usr/bin/plutil -extract ProgramArguments.1 raw -o - "$plist")
log=$(/usr/bin/plutil -extract StandardErrorPath raw -o - "$plist")
printf '%s\n' "$log" > "$S/check-log"
[ -d "${prog%/jobs/auster-check}/_update" ] && echo yes > "$S/update-at-load" || echo no > "$S/update-at-load"
AU_CHECK_LIMIT=5 /bin/bash "$prog" >> "$log" 2>&1 < /dev/null
exit 0
EOF
chmod 755 "$STUB_LAUNCHCTL_DIR/hooks/local.auster.check"
OFF="the checks are off until the installer line is pasted again"
HELD="a run of Auster holds builds/ and has not written _update yet, so no check now"
says_log() { if grep -qF -- "$1" "$2"; then ok "$3"; else bad "$3: [$1] not in: $(cat "$2")"; fi; }
not_log() { if grep -qF -- "$1" "$2"; then bad "$3: $(cat "$2")"; else ok "$3"; fi; }

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the install, with the check job run as launchd runs it when step 12 loads it: exit 0"
LOG=$(cat "$STUB_LAUNCHCTL_DIR/check-log")
same "$(cat "$STUB_LAUNCHCTL_DIR/update-at-load")" no "  ..._update did not exist yet when the job was loaded"
same "$(grep -c 'auster-check: ' "$LOG")" 1 "  ...the job ran once and logged one line"
says_log "$HELD" "$LOG" "  ...that a run holds builds/"
not_log "$OFF" "$LOG" "  ...and not that the checks are off"
[ -d "$DATA/_update" ] && [ -f "$DATA/_update/updates.sh" ] && ok "  ...step 15 wrote _update after it" || bad "  ...no _update after the install"
[ -e "$DATA/builds/updating" ] && bad "  ...the install left its lock" || ok "  ...and the install released its lock"

launchctl bootout "gui/501/local.auster.engine"
AU_CHECK_LIMIT=5 check_job
says_log "the update check ran" "$W/check.out" "the next run, after the install: it makes its update check"
not_log "$OFF" "$W/check.out" "  ...and says nothing of the checks being off"
not_log "$HELD" "$W/check.out" "  ...nor of a run holding builds/"

mv "$DATA/_update" "$W/update-in-the-trash"
: > "$W/check.out"; AU_CHECK_LIMIT=5 check_job
says_log "no _update folder: $OFF" "$W/check.out" "_update in the Trash, no run holding builds/: the checks are off, which is true"
stale_lock "$DATA/builds/updating"
: > "$W/check.out"; AU_CHECK_LIMIT=5 check_job
says_log "no _update folder: $OFF" "$W/check.out" "  ...the same with a lock whose process is gone"
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
stale_lock "$DATA/builds/updating" "$live" "$(sysctl -n kern.bootsessionuuid)" "Thu Nov 20 10:00:00 2026"
: > "$W/check.out"; AU_CHECK_LIMIT=5 check_job
says_log "$HELD" "$W/check.out" "_update gone while another live run holds builds/updating: a run holds builds/"
not_log "$OFF" "$W/check.out" "  ...not that the checks are off"
{ kill "$live"; wait "$live"; } 2>/dev/null
done_
