# T70: the engine's arguments equal a list written here, for order 2 at two people and 32,768 (B4 step 8):
# `-c 65536 -np 2`, `--host 127.0.0.1,<address>`, the fixed options (`--fit off -ngl all` among them),
# `--temp 0.7 --top-p 0.95`, `--alias`, relative paths, and none of the options it must never pass. A
# descriptor trying to add options through any field gives the same list (a trailing field the Mac does not
# know) or no start at all (engine-hash). The engine's environment holds only PATH. The home's path holds a
# space, an apostrophe and &. Mutants: tests/mutants/T70a to T70c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
t2=$(shasum -a 256 < "$FX/assets/order-2.jinja" | cut -c1-64)
expected=$(printf '%s\n' -m "$SB" --alias "$IB2" -c 65536 -np 2 --host 127.0.0.1,10.0.0.5 --port 8484 \
  --api-key-file ../keys/engine.keys --offline --no-slots --no-webui-mcp-proxy \
  --cors-origins http://10.0.0.5:8484,http://test-mac.local:8484 --jinja --chat-template-file "$t2" \
  --ui-config-file "../builds/$IR/ui-config.json" --temp 0.7 --top-p 0.95 --fit off -ngl all)

serving_put "$IB2" "$IMB" 2 32768
engine_job; engine_wait
same "$EJ_CODE" starting "order 2 at two people: start says starting"
if [ -n "$EJ_START" ]; then
  ok "the engine started"
  same "$(cat "$EJ_START/args")" "$expected" "the engine's arguments are the list, in order"
  for o in --tools --mcp-config --mcp-server --media-path --mmproj --connect --props --slot-save-path; do
    if grep -qx -- "$o" "$EJ_START/args"; then bad "it passes $o"; else ok "it never passes $o"; fi
  done
  same "$(cat "$EJ_START/env")" "PATH=/usr/bin:/bin:/usr/sbin:/sbin" "the engine's environment holds only PATH"
  same "$(cat "$EJ_START/cwd")" "$(cd "$DATA/store" && pwd -P)" "its working folder is store/"
  same "$(cat "$EJ_START/program")" "$ED/root/llama-stub/llama-server" "its program is the installed engine's, by its whole path"
  same "$(cat "$DATA/builds/$IR/ui-config.json")" \
    '{"systemMessage":"You are the household assistant for a family. Answer briefly and plainly.\n"}' \
    "the UI config holds one key, systemMessage, with the system prompt"
else
  bad "the engine did not start: $(tail -n 5 "$W/engine-job.out")"
fi

# A descriptor whose field carries an option. LABEL LINE FIELD VALUE: that field of that line of serving
inject() {
  local n
  job_reset
  serving_put "$IB2" "$IMB" 2 32768
  awk -F'\t' -v OFS='\t' -v l="$2" -v f="$3" -v v="$4" 'NR == l { $f = v } { print }' "$DATA/builds/$IR/serving" > "$W/s" &&
    cat "$W/s" > "$DATA/builds/$IR/serving"
  engine_job; engine_wait
  if [ "$EJ_CODE" = starting ] && [ -n "$EJ_START" ]; then
    same "$(cat "$EJ_START/args")" "$expected" "$1: the engine started with the same list"
  else
    same "$EJ_CODE" engine-hash "$1: not started, and start says engine-hash"
    same "$(starts)" "$NSTARTS" "$1: no engine started"
  fi
  engine_job_end
}
inject "the build id" 2 2 "$IB2 --tools x"
inject "the temperature" 2 12 "0.7 --tools x"
inject "the top-p" 2 13 "0.95 --mcp-config /tmp/x"
inject "the template" 2 5 "$t2 --props"
inject "the model's sha256" 4 7 "$SB --connect http://x"
inject "the people" 5 2 "2 --tools"
inject "the context" 5 3 "-np"
inject "the port" 5 4 "8484 --slot-save-path /tmp"
inject "a field after the build line's last, which the Mac keeps and does not read" 2 15 "--tools x"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f15)" "--tools x" "that trailing field was there"
done_
