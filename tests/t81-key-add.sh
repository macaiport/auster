# T81: `auster key add` (B7). A new device's key is 32 hex characters and a newline in keys/k..., mode 0600 in a
# folder of mode 0700, with its name beside it; the engine's key file holds every device's key in the order of
# their ids, then Auster's own; the engine is restarted and reads it, the server check asks with the new key,
# and the new key is answered. Two keys are never equal, and a key is not derived from the name: a device
# revoked and added again under the same name gets another key. Mutants: tests/mutants/T81a and T81b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up
k1=$(key_of ipad) probe=$(cat "$DATA/keys/probe")
n0=$(starts)
: > "$W/screen"

auster key add ipad2
same "$RC" 0 "key add: exit 0 after a passed check"
outsays "The server answered" "it says the server passed its check"
id2=$(id_of ipad2) k2=$(key_of ipad2)
case "$id2" in k[a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7][a-z2-7]) ok "the device has a minted id ($id2)" ;; *) bad "id: [$id2]" ;; esac
f="$DATA/keys/$id2"
same "$(stat -f %Lp "$f") $(stat -f %Lp "$DATA/keys")" "600 700" "its key has mode 0600, in a folder of mode 0700"
same "$(wc -c < "$f" | tr -d ' ')" 33 "its key file is 33 bytes"
if [[ $k2 =~ ^[0-9a-f]{32}$ ]] && [ "$(tail -c 1 "$f" | od -An -tx1 | tr -d ' \n')" = 0a ]; then ok "it holds 32 hex characters and a newline"; else bad "key file: $(od -c "$f" | head -3)"; fi
same "$(cat "$DATA/keys/$id2.name") $(stat -f %Lp "$DATA/keys/$id2.name")" "ipad2 600" "its name beside it, mode 0600"

expected=$(for n in "$DATA"/keys/k*.name; do cat "${n%.name}"; done; cat "$DATA/keys/probe")
same "$(cat "$DATA/keys/engine.keys")" "$expected" "engine.keys: each device's key in the order of their ids, then Auster's own"
same "$(wc -l < "$DATA/keys/engine.keys" | tr -d ' ') $(stat -f %Lp "$DATA/keys/engine.keys")" "3 600" "three keys, mode 0600"
same "$(tail -n 1 "$DATA/keys/engine.keys")" "$probe" "Auster's own key is last"

same "$(starts)" $((n0 + 1)) "the engine was started once more"
s=$(ls -d "$STUB_ENGINE_DIR"/starts/* | tail -n 1)
same "$(cat "$s/keys")" "$(cat "$DATA/keys/engine.keys")" "the new engine read the new key file"
asked=
for d in "$STUB_CURL_DIR"/requests/*; do
  [ "$(cat "$d/url")" = http://10.0.0.5:8484/v1/chat/completions ] || continue
  h=$(grep -i '^authorization: bearer ' "$d/headers" | sed 's/^[^ ]* [^ ]* //')
  [ -z "$h" ] || asked=$h
done
same "$asked" "$k2" "the server check asked its question with the new key"
same "$(ask_engine "$k2")" 200 "the new key is answered"
same "$(ask_engine "$k1")" 200 "the first device's key still is"
same "$(ask_engine 0123456789abcdef0123456789abcdef)" 401 "a key the engine was not given is refused"
same "$(qr_texts "$W/screen")" "$k2" "the new key was shown, as a QR code that reads back as the key"

same "$(printf '%s\n' "$k1" "$k2" "$probe" | sort -u | wc -l | tr -d ' ')" 3 "two keys are never equal"
auster key revoke ipad2
same "$RC" 0 "ipad2 revoked"
auster key add ipad2
same "$RC" 0 "ipad2 added again"
k3=$(key_of ipad2) id3=$(id_of ipad2)
[ -n "$k3" ] && [ "$k3" != "$k2" ] && ok "added again under the same name, it has another key: a key is not derived from the name" || bad "the same name gave the same key: $k3"
[ "$id3" != "$id2" ] && ok "and another id" || bad "the same id again: $id3"
same "$(ask_engine "$k2")" 401 "the old key of that name is refused"
same "$(ask_engine "$k3")" 200 "its new key is answered"
done_
