# T46 (U4; D3.1, D3.6): with _update moved to the Trash while the server runs, the server keeps answering, and an
# `auster restart` brings it back with nothing read from _update; a second update still finds the lock, which lives in
# builds/; the check job then does nothing (no request, no _update made again); `auster status` says the update check is
# off until the line is pasted again; and pasting the line again writes _update again.
# Mutants: tests/mutants/T46a (keep the lock in _update), T46b (make the engine job read _update).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
mkdir -p "$W/Trash"; mv "$DATA/_update" "$W/Trash/_update"
same "$(ask_engine "$(key_of ipad)")" 200 "_update in the Trash: the server keeps answering"
auster restart
same "$RC" 0 "  ...auster restart: its check passes"
same "$(ask_engine "$(key_of ipad)")" 200 "  ...and the restarted server answers"

sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
stale_lock "$DATA/builds/updating" "$live" "$(sysctl -n kern.bootsessionuuid)" "Thu Nov 20 10:00:00 2026"
update_run ''
same "$RC" 1 "a second update, with an update's lock live: exit 1"
says "Another run of Auster (process $live) is installing, updating or changing the server." "  ...it finds the lock in builds/"
{ kill "$live"; wait "$live"; } 2>/dev/null; rm -f "$DATA/builds/updating"

route_drop "$CHANGELOG"; printf '# Changelog\n\n## v0.2.0 (2026-12-01)\n\nTwo.\n' > "$FX/changelog-2.md"
curl_route GET "$CHANGELOG" 200 "$FX/changelog-2.md"
rm -rf "$STUB_CURL_DIR/requests"
AU_CHECK_LIMIT=5 check_job
same "$(requests | grep -c .)" 0 "the check job with no _update: no request"
[ -e "$DATA/_update" ] && bad "  ..._update was made again" || ok "  ...and no _update made again"
auster status
outsays "Update checks are off: there is no _update folder, so no update is looked for until the installer line is pasted again." \
  "auster status: the update check is off until the line is pasted again"
repaste $'\n'
same "$RC" 0 "the line pasted again: exit 0"
[ -f "$DATA/_update/scripts" ] && [ -f "$DATA/_update/updates.sh" ] && ok "  ..._update is written again, the stamp and the rule file" || bad "  ...no _update: $(ls -A "$DATA")"
done_
