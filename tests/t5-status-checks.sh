# T5, `auster status`'s half (U2; D3.1, D3.2): status says whether update checks are made, from the state line of
# the deployed rule file (_update/updates.sh, with no option: nothing is fetched; only its first line is read). Off,
# when _update/off exists, when there is no _update folder (moved to the Trash: D3.1), no updates.sh in it, or no
# stamp; not offered, on a stamp of a checkout or of a named version (`manual`); not yet made (`unknown`); and the
# offered version for `current` and `ready` (what would change: t35-status-waiting.sh). A rule file that answers
# `manual` for a checkout on its first line, whatever follows, is what status says: it asks the rule file,
# never the stamp.
# Mutant: tests/mutants/T5b (T5a is the rule file's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
U="$DATA/_update"
stampit() { printf 'auster-record 1\t%s\t%s\t%s\t2026-11-27T10:00:00Z\n' "$1" "$2" "$COMMIT" > "$U/scripts"; }
none_of() { # TEXT LABEL -> ok when the output does not hold TEXT
  if grep -qF -- "$1" "$W/out"; then bad "$2: $(cat "$W/out")"; else ok "$2"; fi
}

auster status
same "$RC" 0 "status after an install: exit 0"
outsays "No update check has been made yet. The check job makes one soon after the Mac starts, then once a day." "a release stamp and no check yet: unknown"
none_of "Update checks are off" "  ...not off"

: > "$U/off"
auster status; outsays "Update checks are off: _update/off exists. Deleting that file turns them on again." "_update/off: off"
rm -f "$U/off"; mkdir "$U/off"
auster status; outsays "Update checks are off: _update/off exists." "_update/off, a folder: off"
rmdir "$U/off"

stampit checkout v0.1.0
auster status; outsays "Update checks are not made: Auster was installed from a checkout, which is never offered an update." "a checkout's stamp: not offered"
stampit tag v0.1.0
auster status; outsays "Update checks are not made: Auster was installed as a named version (v0.1.0), which is never offered an update." "a named version's stamp: not offered"
stampit release v0.1.0

printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$U/offer"
auster status; outsays "Auster v0.2.0 is released; this Mac has v0.1.0." "an offer newer than the stamp: ready, with the two versions"
printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
auster status; outsays "Auster v0.1.0 is the newest version at the last update check." "an offer of the stamp's own version: current"
rm -f "$U/offer"

mv "$U/scripts" "$W/scripts"
auster status; outsays "Update checks are off: there is no record of what installed Auster (_update/scripts), so no update is looked for until the installer line is pasted again." "no stamp: off"
mv "$W/scripts" "$U/scripts"

mv "$U/updates.sh" "$W/updates.sh"
auster status; outsays "Update checks are off: _update holds no updates.sh, so no update is looked for until the installer line is pasted again." "no updates.sh: off"
printf '#!/bin/bash\nprintf "manual\\tv0.1.0\\t-\\tcheckout\\noff\\t-\\t-\\t-\\n"\n' > "$U/updates.sh"
auster status
outsays "Auster was installed from a checkout" "status says what the rule file's first line says, though the stamp is release's"
none_of "_update/off exists" "  ...and not what a second line says"
mv "$W/updates.sh" "$U/updates.sh"

mv "$U" "$W/update-in-the-trash"
auster status; outsays "Update checks are off: there is no _update folder, so no update is looked for until the installer line is pasted again." "no _update folder (in the Trash): off"
mv "$W/update-in-the-trash" "$U"
auster status; outsays "No update check has been made yet." "put back: unknown again"
done_
