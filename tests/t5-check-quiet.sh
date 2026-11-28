# T5, the check job's half (U7; B5 step 6, D3.2, D3.5): with `off` present, or the stamp on `checkout` (or `tag`, an
# install by a named version), the check job sends no request and no notification, though release names v0.2.0, the
# scripts are v0.1.0, `offer` already holds v0.2.0 and nothing has been noted; --noted names nothing and writes no
# `noted`. With the stamp back on release, the same check job notifies an update waiting, once: so the quiet above is
# the word's doing, not the set-up's. Mutant: tests/mutants/T5d (announce a newer offer whatever the word; T5a to T5c
# are the rule file's, status's and update's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
U="$DATA/_update"
engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
release_says v0.2.0
printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$U/offer"
stampit() { printf 'auster-record 1\t%s\tv0.1.0\t%s\t2026-11-27T10:00:00Z\n' "$1" "$COMMIT" > "$U/scripts"; }

quiet() { # LABEL
  rm -rf "$STUB_CURL_DIR/requests"; rm -f "$U/tried" "$U/noted"
  check_job
  grep -q 'probe: ok' "$W/check.out" && ok "$1: the check job ran" || bad "$1: check.out: $(tail -n 5 "$W/check.out")"
  same "$(requests raw.githubusercontent.com | wc -l | tr -d ' ')" 0 "  ...no request"
  same "$(update_notes):$(notes)" 0:0 "  ...no notification"
  same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" --noted)" "" "  ...--noted names nothing"
  [ -e "$U/noted" ] && bad "  ...noted was written: $(cat "$U/noted")" || ok "  ...and writes no noted"
  : > "$W/check.out"
}
: > "$U/off"; quiet "_update/off present"
rm -f "$U/off"; stampit checkout; quiet "the stamp on checkout"
stampit tag; quiet "the stamp on tag"

stampit release; rm -f "$U/tried" "$U/noted"
check_job
same "$(requests raw.githubusercontent.com | wc -l | tr -d ' ')" 2 "the stamp on release: the check's two requests"
same "$(update_notes)" 1 "  ...and an update waiting notified, once"
done_
