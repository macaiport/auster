# T37 (U7; B5 step 6, D3.3, D3.5): a third check of the same version sends no notification. On an installed Mac whose
# scripts are v0.1.0, with release naming v0.2.0 and the engine answering, the check job notifies an update waiting once
# at the check that finds it (naming the version, in the fixed sentence) and once at the next check a day later, and
# `_update/noted` then holds the version twice; the third check, a day after that, sends none, and --noted names
# nothing. A firing between checks (four hours on, the day's try used up) asks nothing and sends nothing, so the second
# notification comes a check later, never at the next firing. A newer version is told again, from one.
# Mutants: tests/mutants/T37a (do not write `noted`) and T37b (ask --noted on every firing, not only after a check).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
U="$DATA/_update" T0=1800000000 DAY=86400
same "$(cut -f2,3 "$U/scripts")" "release${TAB:=	}v0.1.0" "the install's stamp: release, v0.1.0"
engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
release_says v0.2.0
noted() { cat "$U/noted" 2>/dev/null || echo none; }
sentence() { printf "Auster %s is out. auster status says what would change, and auster update asks before changing anything." "$1"; }

check_job AU_UPDATE_NOW=$T0
same "$(probe_field probe)" ok "the first check: the engine answers its probe"
same "$(update_notes)" 1 "  ...and the check that finds v0.2.0 notifies an update waiting"
same "$(last_note)" "$(sentence v0.2.0)" "  ...in the fixed sentence, naming the version"
same "$(noted)" "auster-record 1${TAB}v0.2.0${TAB}1" "  ...and _update/noted holds v0.2.0 once"
rm -rf "$STUB_CURL_DIR/requests"; check_job AU_UPDATE_NOW=$((T0 + 14400))
same "$(requests raw.githubusercontent.com | wc -l | tr -d " ")" 0 "four hours later, the day's try used up: no check"
same "$(update_notes)" 1 "  ...and no notification"
same "$(noted)" "auster-record 1${TAB}v0.2.0${TAB}1" "  ...and noted unchanged"

check_job AU_UPDATE_NOW=$((T0 + DAY))
same "$(update_notes)" 2 "the second check of v0.2.0, a day later: notified a second time"
same "$(last_note)" "$(sentence v0.2.0)" "  ...in the same sentence"
same "$(noted)" "auster-record 1${TAB}v0.2.0${TAB}2" "  ...and noted holds it twice"
check_job AU_UPDATE_NOW=$((T0 + DAY + 14400))
same "$(update_notes)" 2 "four hours after that: nothing"

rm -rf "$STUB_CURL_DIR/requests"; check_job AU_UPDATE_NOW=$((T0 + 2 * DAY))
same "$(requests raw.githubusercontent.com | wc -l | tr -d " ")" 2 "the third check, a day later: its two requests"
same "$(update_notes)" 2 "the third check of the same version: no notification"
same "$(AU_UPDATE_DIR=$U AU_UPDATE_NOW=$((T0 + 2 * DAY)) /bin/bash "$U/updates.sh" --noted)" "" "  ...and --noted names nothing"
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" | cut -f1,3)" "ready${TAB}v0.2.0" "  ...though the update still waits: ready, v0.2.0"

release_says v0.3.0
check_job AU_UPDATE_NOW=$((T0 + 3 * DAY))
same "$(update_notes)" 3 "a newer version, v0.3.0: notified"
same "$(last_note)" "$(sentence v0.3.0)" "  ...naming v0.3.0"
same "$(noted)" "auster-record 1${TAB}v0.3.0${TAB}1" "  ...and noted holds v0.3.0 once"
same "$(notes)" 3 "no other notification all along"
done_
