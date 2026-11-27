# T84: no key leaves the Mac (B7). After an install, a check (the check job's probe, and a notification), a
# `key add` and a `key revoke`, every key any engine was given (the devices', Auster's own, the install's test
# key: each start's keys, as the stub engine recorded them) is searched for in every stub's logged arguments
# (STUB_LOG), in the headers and bodies of every request the stub curl sent anywhere but to the engine's own
# addresses, in logs/, in the check job's output, in the notifier's arguments, in what each command printed, and
# in every file under the home folder but keys/, and found nowhere. The row's update waits for U4.
# Mutant: tests/mutants/T84a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
cp "$W/out" "$W/printed"
engine_up
AU_CHECK_LIMIT=5 check_job
same "$(probe_field probe)" ok "the check job's probe: ok"
engine_live 8484 open 1
AU_CHECK_LIMIT=5 check_job
same "$(probe_field probe)" open "the check job's probe of an open engine: open"
same "$(notes)" 1 "and a notification"
engine_live 8484 open 0
auster key add ipad2
same "$RC" 0 "key add: passed"
cat "$W/out" >> "$W/printed"
auster key revoke ipad
same "$RC" 0 "key revoke: passed"
cat "$W/out" >> "$W/printed"

cat "$STUB_ENGINE_DIR"/starts/*/keys "$DATA"/keys/k* "$DATA/keys/probe" 2>/dev/null | grep -E '^[0-9a-f]{32}$' | sort -u > "$W/keys"
same "$(wc -l < "$W/keys" | tr -d ' ')" 4 "four keys were made: the test's, ipad's, ipad2's and Auster's own"
grep -qF -f "$W/keys" "$STUB_ENGINE_DIR"/starts/*/keys && ok "the search can find them (the engines' own records hold them)" || bad "the keys are not in the engines' records"

sent=0 hits=
for d in "$STUB_CURL_DIR"/requests/*; do
  case "$(cat "$d/url")" in http://10.0.0.5:8484/*|http://127.0.0.1:8484/*|http://127.0.0.1:184[0-9][0-9]/*) continue ;; esac
  sent=$((sent + 1))
  grep -qF -f "$W/keys" "$d/headers" "$d/body" "$d/url" 2>/dev/null && hits+=" $(cat "$d/url")"
done
[ "$sent" -gt 0 ] && ok "requests went to $sent other addresses" || bad "no request to search"
same "$hits" "" "no key in a request to anywhere but the engine"
same "$(grep -F -f "$W/keys" "$STUB_LOG" | cut -c1-200)" "" "no key in any stub's logged arguments or input"
same "$(grep -lF -f "$W/keys" "$DATA"/logs/* "$W/check.out" 2>/dev/null)" "" "no key in logs/ or the check job's output"
same "$(grep -F -f "$W/keys" "$STUB_NOTIFY_LOG")" "" "no key in the notifier's arguments"
same "$(grep -F -f "$W/keys" "$W/printed")" "" "no key in what the install and the commands printed"
same "$(grep -rlF -f "$W/keys" --exclude-dir=keys "$H" 2>/dev/null)" "" "no key in any file under the home folder but keys/"
done_
