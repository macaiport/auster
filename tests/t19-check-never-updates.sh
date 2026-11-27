# T19 (U4; D2.5, D3.4): the check job, with the state ready and no terminal, only checks. With release's changelog and
# registry naming v0.1.0 and a build waiting (the word ready), the check job runs: it makes its two requests and no
# other, hands nothing to the stub open and writes no .command file, logs no launchctl call, and changes no file outside
# _update/ and logs/. Mutant: tests/mutants/T19a (start the update from --refresh when ready).
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
done_
