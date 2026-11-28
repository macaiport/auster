# T120 (U9; D3.2, B6): after an update check that could not read the release, `_update/tried` written and no `offer`,
# as when release's CHANGELOG.md answers 404 because there is no release branch yet (the first real install,
# docs/phase-2.md section 13), `auster status` says when that check was tried and that it did not read the release,
# and `auster update` refuses saying the same, rather than that no check has been made. The check here is the check
# job's own, against the stub curl's 404s (install-helpers.sh). With no `tried`, or one that cannot be read (a value
# that is not a time, or a newer format), both say no check has been made yet, as before.
# Mutants: tests/mutants/T120a (status does not read tried), T120b (update does not read it).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
U="$DATA/_update"
none_of() { if grep -qF -- "$1" "$W/out"; then bad "$2: $(cat "$W/out")"; else ok "$2"; fi; }
NEVER="No update check has been made yet. The check job makes one soon after the Mac starts, then once a day."
NEVER_U="No update check has been made yet, so no update is known to be waiting. The check job makes one soon after the Mac starts, then once a day."
tried_s() { printf 'No update check has read the release yet: the last, at %s, could not. The check job tries again a day after it.' "$1"; }
tried_u() { printf 'No update check has read the release yet (the last, at %s, could not), so no update is known to be waiting. The check job tries again a day after it.' "$1"; }

[ -e "$U/tried" ] && bad "a check was tried during the install" || ok "after the install, no check has been tried"
auster status; outsays "$NEVER" "status before any check: none has been made"

AU_CHECK_LIMIT=5 check_job
{ [ -f "$U/tried" ] && [ ! -e "$U/offer" ]; } && ok "the check job's check, with release's changelog answering 404: tried written, no offer" \
  || bad "the check job's check: tried $( [ -f "$U/tried" ] && echo written || echo missing ), offer $( [ -e "$U/offer" ] && echo written || echo absent )"
when=$(date -u -r "$(cut -f2 "$U/tried")" '+%Y-%m-%d %H:%M:%S UTC')
auster status
same "$RC" 0 "status after that check: exit 0"
outsays "$(tried_s "$when")" "  ...it says when the last check was tried, and that it could not read the release"
none_of "No update check has been made yet" "  ...and not that no check has been made"
auster update
same "$RC" 1 "auster update after that check: refused, exit 1"
outsays "$(tried_u "$when")" "  ...saying when the last check was tried, and that it could not read the release"
none_of "No update check has been made yet" "  ...and not that no check has been made"

printf 'auster-record 1\t1796000000\n' > "$U/tried"
auster status; outsays "$(tried_s "2026-11-30 00:53:20 UTC")" "a tried of 1796000000: the time in UTC, as the rest of status gives times"
printf 'auster-record 1\tsoon\n' > "$U/tried"
auster status; outsays "$NEVER" "a tried that is not a time counts as none"
auster update; outsays "$NEVER_U" "  ...for auster update too"
printf 'auster-record 2\t1796000000\n' > "$U/tried"
auster status; outsays "$NEVER" "a tried of a newer format counts as none"
rm -f "$U/tried"
auster status; outsays "$NEVER" "no tried: none has been made"
done_
