# T26, the update's half (U4, U6; D3.1, D3.6): while the lock, builds/updating, names a live run, an update (install.sh
# update), a second paste, `auster update`, `auster stop`, `auster key revoke`, `auster rollback`, `auster unhold` and
# `auster cleanup` (whose list would name order 1's template, which no descriptor names once order 2 serves) each refuse,
# leave the lock as it is and change nothing (the engine still serving), and the check job makes no update check, so that
# `offer` does not change during an update. A lock whose process is gone, whose number now belongs to another process, or
# from an earlier boot is taken over: the update runs and leaves no lock. With the lock gone, the same check writes the
# offer.
# Mutants: tests/mutants/T26a and T26b (the lock's, shared with the install's half), T26d (check during an update), T26e
# (`auster cleanup` without the lock).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
engine_up
U="$DATA/_update"
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
BOOT=$(sysctl -n kern.bootsessionuuid)
stale_lock "$DATA/builds/updating" "$live" "$BOOT" "Thu Nov 20 10:00:00 2026"
lock=$(cat "$DATA/builds/updating"); before=$(data_snap); pid=$(engine_pid)
held() { # LABEL -> refused, naming the live run; the lock and the data root as they were; the engine serving
  same "$RC" 1 "$1: exit 1"
  outsays "Another run of Auster (process $live) is installing, updating or changing the server." "  ...it names the run that holds the lock"
  same "$(cat "$DATA/builds/updating")" "$lock" "  ...the lock as it was"
  same "$(data_snap)" "$before" "  ...the data root as it was"
  same "$(engine_pid)" "$pid" "  ...and the engine still serving"
}
update_run $'no\n'; held "install.sh update while the lock is live"
grep -q 'an update is waiting' "$W/out" && bad "  ...it asked its question" || ok "  ...it asks nothing"
repaste $'no\n'; held "a second paste while the lock is live"
auster update; held "auster update while the lock is live"
same "$(opened | grep -c .)" 0 "  ...and it opens nothing"
auster stop; held "auster stop while the lock is live"
[ -e "$DATA/builds/stopped" ] && bad "  ...builds/stopped written" || ok "  ...no builds/stopped"
auster key revoke ipad; held "auster key revoke while the lock is live"
auster rollback; held "auster rollback while the lock is live"
auster unhold; held "auster unhold while the lock is live"
ANSWERS=$'yes\n' auster cleanup; held "auster cleanup while the lock is live, answered yes"

# the check job during an update
route_drop "$CHANGELOG"; route_drop "$REGISTRY"
printf '# Changelog\n\n## v0.2.0 (2026-12-01)\n\nTwo.\n' > "$FX/changelog-2.md"
install_registry "$FX/registry-check.tsv" v0.2.0
curl_route GET "$CHANGELOG" 200 "$FX/changelog-2.md"; curl_route GET "$REGISTRY" 200 "$FX/registry-check.tsv"
o=$(cat "$U/offer"); rm -rf "$STUB_CURL_DIR/requests"
AU_CHECK_LIMIT=5 check_job
same "$(cat "$U/offer")" "$o" "the check job while the lock is live: offer as it was"
same "$(requests raw.githubusercontent.com | grep -c .)" 0 "  ...no request to GitHub"
[ -e "$U/tried" ] && bad "  ...tried written" || ok "  ...and tried not written, so the next firing checks"

# taken over
taken() { # LABEL
  same "$RC" 1 "$1: the update runs (its question answered no): exit 1"
  outsays "The recipe household: an update is waiting." "  ...the lock taken over, the update reached its question"
  [ -e "$DATA/builds/updating" ] && bad "  ...a lock is left" || ok "  ...and no lock is left"
}
stale_lock "$DATA/builds/updating"
update_run $'no\n'; taken "a lock whose process is gone"
stale_lock "$DATA/builds/updating" "$live" "$BOOT" "Thu Nov 19 09:00:00 2026"
update_run $'no\n'; taken "a lock whose number now belongs to another process"
stale_lock "$DATA/builds/updating" "$live" 00000000-1111-2222-3333-444444444444 "Thu Nov 20 10:00:00 2026"
update_run $'no\n'; taken "a lock from an earlier boot"

AU_CHECK_LIMIT=5 check_job
same "$(cut -f2 "$U/offer")" v0.2.0 "with no live lock, the same check writes the offer"
{ kill "$live"; wait "$live"; } 2>/dev/null
done_
