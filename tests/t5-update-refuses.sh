# T5, `auster update`'s half (U4; D3.2, D3.6, B6): `auster update` asks the deployed rule file for its word and goes on
# only when it is ready. On a stamp of a checkout or of a named version (`manual`) it refuses, exit 1, saying the Mac is
# never offered an update, and opens nothing, writes no .command file and sends no request; the same, each in its own
# words, with update checks off (_update/off), with no stamp (none), before the first check (unknown), and with nothing
# waiting (current). A newer version on offer (the scripts behind) is ready, and so is a build
# waiting with the scripts current: each opens the update. Mutant: tests/mutants/T5c (go on for a checkout).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
U="$DATA/_update"
stampit() { printf 'auster-record 1\t%s\t%s\t%s\t2026-11-27T10:00:00Z\n' "$1" "$2" "$COMMIT" > "$U/scripts"; }
refused() { # TEXT LABEL -> exit 1, TEXT said, nothing opened, no .command file, no request
  same "$RC" 1 "$2: exit 1"
  outsays "$1" "  ...it says why"
  same "$(opened | grep -c .)" 0 "  ...nothing handed to the stub open"
  same "$(ls -d "${TMPDIR%/}"/auster-update.* 2>/dev/null | wc -l | tr -d ' ')" 0 "  ...no .command file written"
  same "$(requests | grep -c .)" 0 "  ...no request sent"
}
rm -rf "$STUB_CURL_DIR/requests"
cp "$FX/registry.tsv" "$U/registry"; printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$U/offer"   # something on offer

stampit checkout v0.1.0
auster update; refused "Auster was installed from a checkout, which is never offered an update, so nothing was changed." "a checkout's stamp"
stampit tag v0.1.0
auster update; refused "Auster was installed as a named version (v0.1.0), which is never offered an update, so nothing was changed." "a named version's stamp"
stampit release v0.1.0
: > "$U/off"
auster update; refused "Update checks are off (_update/off exists), so no update is offered." "_update/off"
rm -f "$U/off"
mv "$U/scripts" "$W/scripts"
auster update; refused "There is no record of what installed Auster (_update/scripts), so no update is offered." "no stamp"
mv "$W/scripts" "$U/scripts"
mv "$U/offer" "$W/offer"
auster update; refused "No update check has been made yet, so no update is known to be waiting." "no check yet"
printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
auster update; refused "Nothing is waiting: Auster v0.1.0 is the newest version at the last update check" "the newest version, the build for this Mac served"

mv "$W/offer" "$U/offer"   # v0.2.0: the scripts behind, no build waiting
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" | cut -f1,3)" "ready	v0.2.0" "a newer version on offer (the scripts behind): ready"
auster update
same "$RC:$(opened | grep -c .)" "0:1" "  ...auster update opens the update"
printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
waiting_b1
auster update
same "$RC:$(opened | grep -c .)" "0:2" "a build waiting with the scripts current: auster update opens the update"
done_
