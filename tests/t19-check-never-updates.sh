# T19 (U4; D2.5, D3.4): the check job, with the state ready and no terminal, only checks. With release's changelog and
# registry naming v0.1.0 and a build waiting (the word ready), the check job runs: it makes its two requests and no
# other, hands nothing to the stub open and writes no .command file, logs no launchctl call, and changes no file outside
# _update/ and logs/. U7: it sends no notification then (a build waiting for a reason on this Mac is no new version,
# D3.3); and with release naming v0.2.0, a newer version, it notifies the update once, naming the version and the
# recipe whose build waits, and still only checks. Mutants: tests/mutants/T19a (start the update from --refresh when
# ready) and T19b (start the update when telling of one).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
route_drop "$CHANGELOG"; route_drop "$REGISTRY"
printf '# Changelog\n\n## v0.1.0 (2026-11-27)\n\nFirst.\n' > "$FX/changelog-1.md"
curl_route GET "$CHANGELOG" 200 "$FX/changelog-1.md"; curl_route GET "$REGISTRY" 200 "$FX/registry.tsv"
outside() { snapshot "$DATA" | grep -v -E $'\t(logs|_update)(/|$)'; }
before=$(outside); n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
AU_CHECK_LIMIT=5 check_job
grep -q 'the update check ran' "$W/check.out" && ok "the check job ran the update check" || bad "check.out: $(tail -n 5 "$W/check.out")"
same "$(AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" | cut -f1)" ready "  ...the word is ready, a build waiting"
same "$(requests | grep -v '://127\.0\.0\.1:' )" "GET $CHANGELOG
GET $REGISTRY" "  ...its two requests and no other (but the probe's, to 127.0.0.1)"
same "$(opened | grep -c .)" 0 "  ...nothing handed to the stub open"
same "$(ls -d "${TMPDIR%/}"/auster-update.* 2>/dev/null | wc -l | tr -d ' ')" 0 "  ...no .command file written"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep -c '^launchctl')" 0 "  ...no launchctl call"
same "$(outside)" "$before" "  ...and no file changed outside _update/ and logs/"
same "$(update_notes)" 0 "  ...and no notification: a build waiting for a reason on this Mac is no new version"

# U7: a newer version on offer, the next day
release_says v0.2.0; rm -f "$DATA/_update/tried"
before=$(outside); n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; : > "$STUB_NOTIFY_LOG"
AU_CHECK_LIMIT=5 check_job
same "$(update_notes)" 1 "release names v0.2.0: one notification of an update waiting"
same "$(last_update_note)" "Auster v0.2.0 is out, with a new build for the recipe household. auster status says what would change, and auster update asks before changing anything." \
  "  ...naming the version and the recipe whose build waits"
same "$(requests | grep -v '://127\.0\.0\.1:' )" "GET $CHANGELOG
GET $REGISTRY" "  ...its two requests and no other"
same "$(opened | grep -c .)" 0 "  ...nothing handed to the stub open"
same "$(ls -d "${TMPDIR%/}"/auster-update.* 2>/dev/null | wc -l | tr -d ' ')" 0 "  ...no .command file written"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep -c '^launchctl')" 0 "  ...no launchctl call"
same "$(outside)" "$before" "  ...and no file changed outside _update/ and logs/"
done_
