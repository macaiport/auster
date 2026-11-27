# T72, its revoke clause (B7): `auster key revoke` writes the engine's key file to a temporary file and renames
# it, never in place (a new file, not the old one rewritten), so that the engine never meets it half written or
# empty; it then holds the other device's key and Auster's own. Revoking the last device's key is refused and
# leaves the key file as it was, its key and Auster's own in it: the file is never empty, and the server keeps
# a household key to answer (V7 resolves the row's "leaves Auster's own key" so; see the report).
# Mutant: tests/mutants/T72b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up
kf="$DATA/keys/engine.keys"
auster key add ipad2
same "$RC" 0 "a second device's key is added"
k2=$(key_of ipad2) probe=$(cat "$DATA/keys/probe")
cp "$kf" "$W/before"; ino=$(stat -f %i "$kf")

auster key revoke ipad
same "$RC" 0 "ipad's key revoked"
[ "$(stat -f %i "$kf")" != "$ino" ] && ok "the key file is a new file, renamed into place" || bad "the key file was rewritten in place (inode $ino)"
same "$(cat "$kf")" "$k2
$probe" "it holds ipad2's key, then Auster's own"
same "$(stat -f '%Lp %z' "$kf")" "600 66" "mode 0600, two keys"
ls -A "$DATA/keys" | grep -q '^\.engine\.keys\.new' && bad "a temporary key file is left" || ok "no temporary key file is left"

cp "$kf" "$W/before"; ino=$(stat -f %i "$kf"); n0=$(starts)
auster key revoke ipad2
same "$RC" 1 "revoking the last device's key: refused"
outsays "ipad2 has the only device key, so it is not revoked" "it says why"
cmp -s "$kf" "$W/before" && [ "$(stat -f %i "$kf")" = "$ino" ] && ok "the key file is as it was: ipad2's key and Auster's own" || bad "the key file changed: $(cat "$kf")"
[ -s "$kf" ] && ok "the key file is not empty" || bad "the key file is empty"
same "$(starts)" "$n0" "the engine was not restarted"
same "$(ask_engine "$k2")" 200 "ipad2's key is still answered"
done_
