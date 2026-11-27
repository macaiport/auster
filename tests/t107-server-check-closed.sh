# B3 step 13, the server check fails closed on the request with no key (V6, at the coordinator's word; this
# file is not T107's row, which U5 builds with its mutants (a) to (e), but carries T107's number so that
# `run.sh --mutants 107` runs it). The check, common/auster's au_server_check, is called as a first install
# calls it, against the stub curl's routes for the home address: the question with a household key answered,
# then the request with no key. Refused is HTTP 401 or 403 and nothing else: those pass. A 500, a 404, a 200,
# or a request that times out (the stub curl's sleep, cut by the check's limit) is open: the engine is stopped
# (disable, then bootout) and builds/stopped records the reason open. That request asks for one token and
# carries no key. Mutants: tests/mutants/T107f and T107g.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
. "$ROOT/common/auster"
HOME=$H au_identity > "$W/identity" 2>&1 || bad "au_identity: $(cat "$W/identity")"
same "$AU_DATA" "$DATA" "the library finds the data root"
CH=http://10.0.0.5:8484/v1/chat/completions
printf '{"choices":[{"message":{"role":"assistant","content":"1"}}],"timings":{"predicted_per_second":36.9}}' > "$W/answer.json"
plist="$H/Library/LaunchAgents/local.auster.engine.plist"
[ -f "$STUB_ENGINE_DIR/ports/8484" ] && bad "an engine still listens on 8484" || ok "no engine listens: the routes answer"

check() { # LABEL NO-KEY-ANSWER RESULT
  local t0 last
  rm -f "$DATA/builds/stopped" "$STUB_CURL_DIR"/.count-*
  echo enabled > "$STUB_LAUNCHCTL_DIR/overrides/local.auster.engine"
  printf '%s\n' "$plist" > "$STUB_LAUNCHCTL_DIR/loaded/local.auster.engine"
  route_drop "$CH"; curl_route POST "$CH" "200,$2" "$W/answer.json"
  printf 'auster-record 1\ncode\tstarting\naddress\t10.0.0.5\nboot\t%s\ntime\t%s\n' "$AU_BOOT" "$(date +%s)" > "$DATA/builds/$IR/start"
  t0=$(( $(date +%s) - 175 ))   # 5 s left of the check's 180: the request with no key gets at least 5 s
  au_server_check "$IR" "$t0"
  same "$AU_CHECK" "$3" "$1: the check gives $3"
  last=$(ls -d "$STUB_CURL_DIR"/requests/* | tail -n 1)
  grep -qi '^authorization:' "$last/headers" && bad "$1: the request with no key carried a key" || ok "$1: the request with no key carried none"
  same "$(plutil -extract max_tokens raw -o - "$last/body")" 1 "$1: it asked for one token"
  if [ "$3" = open ]; then
    same "$(cat "$STUB_LAUNCHCTL_DIR/overrides/local.auster.engine")" disabled "$1: the engine's job is disabled"
    [ -f "$STUB_LAUNCHCTL_DIR/loaded/local.auster.engine" ] && bad "$1: the engine's job is still loaded" || ok "$1: and booted out"
    same "$(cut -f1,2 "$DATA/builds/stopped" 2>/dev/null)" "auster-record 1	open" "$1: builds/stopped says open"
  else
    same "$(cat "$STUB_LAUNCHCTL_DIR/overrides/local.auster.engine")" enabled "$1: the engine's job is left enabled"
    [ -f "$STUB_LAUNCHCTL_DIR/loaded/local.auster.engine" ] && ok "$1: and loaded" || bad "$1: the engine's job was booted out"
    [ -e "$DATA/builds/stopped" ] && bad "$1: builds/stopped was written" || ok "$1: no builds/stopped"
  fi
}
check "401" 401 passed
check "403" 403 passed
check "500" 500 open
check "404" 404 open
check "200" 200 open
t=$(date +%s)
check "a time-out" sleep:30 open
t=$(( $(date +%s) - t ))
[ "$t" -ge 5 ] && [ "$t" -le 15 ] && ok "a time-out: given up after the check's limit ($t s)" || bad "a time-out: took $t s"
done_
