# T82: `auster key revoke` (B7). Once it returns, the revoked key is refused and the other device's key and
# Auster's own are answered: its key is out of the engine's key file, its files are deleted, and the engine was
# restarted. Auster's own key cannot be revoked or shown. Names such as ../x, -rf, $(touch f) and an empty name
# are refused by add, revoke and show (exit 2), a duplicate by add (exit 1), and none of them changes keys/; a
# file outside keys/ survives, and f is never made. Mutants: tests/mutants/T82a and T82b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up
auster key add ipad2
same "$RC" 0 "a second device's key is added"
k1=$(key_of ipad) id1=$(id_of ipad) k2=$(key_of ipad2) probe=$(cat "$DATA/keys/probe")
mkdir -p "$W/cwd"; cd "$W/cwd" || exit 1
echo keep > "$DATA/x"; echo keep > "$DATA/x.name"; echo keep > "$DATA/keys/../keep-too"
keys0=$(snapshot "$DATA/keys")
: > "$W/screen"

for name in '../x' '-rf' '$(touch f)' '' 'iPad' 'a b'; do
  for c in add revoke show; do
    auster key "$c" "$name"
    same "$RC" 2 "key $c [$name]: refused as a usage error"
    outsays "That is not a name Auster gives a device" "key $c [$name]: it says why"
  done
done
auster key add ipad
same "$RC" 1 "key add of a name a device already has: refused"
outsays "A device named ipad already has a key" "it says so"
auster key revoke ipad3
same "$RC" 1 "key revoke of a name no device has: refused"
for c in revoke show; do
  for name in probe engine; do
    auster key "$c" "$name"
    same "$RC" 1 "key $c $name: Auster's own key is no device's"
  done
done
same "$(snapshot "$DATA/keys")" "$keys0" "keys/ is as it was, byte for byte"
same "$(cat "$DATA/x" "$DATA/x.name" "$DATA/keep-too")" "keep
keep
keep" "the files outside keys/ survive"
made=
for d in "$W/cwd" "$DATA" "$DATA/keys" "$W"; do [ -e "$d/f" ] && made+=" $d"; done
same "$made" "" "no f was made"
same "$(qr_texts "$W/screen")" "" "no key was drawn"
same "$(cat "$DATA/keys/probe")" "$probe" "Auster's own key is unchanged"

n0=$(starts)
auster key revoke ipad
same "$RC" 0 "key revoke ipad: exit 0 after a passed check"
[ -e "$DATA/keys/$id1" ] || [ -e "$DATA/keys/$id1.name" ] && bad "ipad's files are left" || ok "ipad's key and name are deleted"
same "$(cat "$DATA/keys/engine.keys")" "$k2
$probe" "engine.keys: ipad2's key, then Auster's own"
same "$(starts)" $((n0 + 1)) "the engine was started once more"
s=$(ls -d "$STUB_ENGINE_DIR"/starts/* | tail -n 1)
same "$(cat "$s/keys")" "$(cat "$DATA/keys/engine.keys")" "the new engine read the new key file"
same "$(ask_engine "$k1")" 401 "the revoked key is refused once the command returns"
same "$(ask_engine "$k2")" 200 "ipad2's key is answered"
same "$(ask_engine "$probe" 127.0.0.1)" 200 "Auster's own key is answered, on 127.0.0.1"
same "$(cat "$DATA/x" "$DATA/x.name")" "keep
keep" "the files outside keys/ still survive"
done_
