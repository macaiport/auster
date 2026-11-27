# T28 (U5; D3.6 step 4, D3.10, B3 step 10): the candidate is isolated during its test. On a Mac serving order 2 with order
# 1 waiting, the candidate slowed so that it is alive for two seconds before its test, and answering the last reading
# question with a tool call that would create a file: while it runs, a request to its port at the Mac's home address is
# refused (it listens on 127.0.0.1 only), and one on 127.0.0.1 with a household key is refused (401). It was started
# with --host 127.0.0.1 alone, a key file of its own that is not keys/engine.keys and holds no household key, and none
# of --tools, --mcp-*, --media-path, --mmproj, --connect, --props, --slot-save-path; that key file is gone afterwards.
# The tool call is graded as an answer (that question fails, the test still passes at 11 of 12) and nothing is run: the
# file it names does not exist. The update then switches to order 1.
# Mutant: tests/mutants/T28a (start the candidate with the household's address and key file).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
engine_up
candidate_slow 2
grep -v 'next flea treatment' "$FX/answers-good" > "$W/answers-tool"
printf 'next flea treatment\t{"tool_calls":[{"type":"function","function":{"name":"shell","arguments":"{\\"cmd\\":\\"touch %s\\"}"}}]}\t36.9\t0\n' \
  "$W/tool-ran" >> "$W/answers-tool"
engine_set "port=$CPORT" answers "$W/answers-tool"
ask_candidate() { # KEY HOST -> the HTTP code the candidate gives a question asked with KEY at HOST
  printf 'Authorization: Bearer %s\n' "$1" > "$W/cand-header"
  printf '{"messages":[{"role":"user","content":"Count from 1 to 3"}],"max_tokens":8,"temperature":0}' > "$W/cand-body"
  curl -q -s --max-time 5 -o /dev/null -w '%{http_code}' -H @"$W/cand-header" -H 'Content-Type: application/json' \
    --data-binary @"$W/cand-body" "http://$2:$CPORT/v1/chat/completions"
}
look() { # -> once the candidate has loaded: what it answers from the home address, and on 127.0.0.1 with a household key
  local i
  for i in $(seq 100); do [ "$(curl -q -s --max-time 2 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$CPORT/health")" = 200 ] && break; sleep 0.05; done
  printf 'home address %s\n' "$(ask_candidate "$(key_of ipad)" 10.0.0.5)"
  printf 'household key %s\n' "$(ask_candidate "$(key_of ipad)" 127.0.0.1)"
}

during_test look
update_run $'yes\n'
wait "$DURING"
same "$RC" 0 "the update finishes: exit 0"
same "$(cat "$W/during")" "home address 000
household key 401" "while the candidate runs: refused at the home address, and refused a household key"
c=$(start_on $CPORT)
same "$(arg_of "$c" --host)" 127.0.0.1 "the candidate listens on 127.0.0.1 alone"
kf=$(cat "$c/keyfile")
case "$kf" in */keys/engine.keys) bad "  ...it read the household's key file" ;; *) ok "  ...with a key file of its own" ;; esac
grep -qxF -f "$c/keys" "$DATA/keys/engine.keys" && bad "  ...which holds a household key" || ok "  ...which holds no household key"
[ -e "$kf" ] && bad "  ...left on disk after the test" || ok "  ...and is gone after the test"
grep -qE '^--(tools|mcp-config|mcp-server|media-path|mmproj|connect|props|slot-save-path)$' "$c/args" && bad "  ...started with a forbidden option: $(tr '\n' ' ' < "$c/args")" ||
  ok "  ...with none of the options that could reach the network or run a tool"
says "  Q12 FAIL optional reading: answered in" "the tool call is graded as an answer, and fails"
says "  result pass 11/12 mandatory 8/8" "  ...the test still passes"
[ -e "$W/tool-ran" ] && bad "  ...and the tool call was run" || ok "  ...and nothing was run"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB1" "order 1 serves"
done_
