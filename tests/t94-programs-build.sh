# T94 (a, h), for a yes to a new build (U5; B3 step 6, BD18, D3.6): Auster's own programs change before anything is fetched
# for the model, and an earlier change never checked is checked before anything is fetched. On a Mac serving order 2 with
# order 1 waiting and release v0.2.0, whose bin/auster and engine job differ: after the yes, the new bin/auster answers
# `status` (its trial run), the engine restarts on order 2 and the server check passes, all before the model's download
# starts; then order 1 is fetched, tested and switched, exit 0, the programs of v0.2.0 in place and no jobs/previous left.
# With jobs/previous there (a change never checked), order 1 waiting again and the engine on the household's port not
# answering: the question says the server restarts first to check the programs, the yes makes that check before anything
# is fetched, and it fails: exit 4, naming `auster rollback`, nothing asked of Hugging Face's CDN, jobs/previous kept,
# serving order 2 as it was.
# Mutants: tests/mutants/T94a (change the programs after the download), and T94h (a later update that does not check first).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, order 1 waiting
engine_up
release_at v0.2.0 "$COMMIT2"
T="$FX/tree-src-$COMMIT2"
printf '# a change in v0.2.0\n' >> "$T/common/auster"; printf '# a change in v0.2.0\n' >> "$T/common/auster-engine"
tree_archive "$T" "auster-$COMMIT2" "$COMMIT2" "$FX/tree-$COMMIT2.tar.gz"
S="$DATA/builds/$IR/serving"
first() { tail -n +$((n + 1)) "$STUB_LOG" | grep -n -m 1 -E "$1" | cut -d: -f1; }   # PATTERN -> its first line after n

n=$(wc -l < "$STUB_LOG")
update_run $'yes\n'
same "$RC" 0 "programs and a new build, answered yes: exit 0"
says "Auster's programs pass." "  ...the programs' server check passed"
trial=$(first '^launchctl print-disabled') restart=$(first '^launchctl kickstart') dl=$(first '^curl .* -C - .*huggingface\.co/')
[ -n "$trial" ] && [ -n "$restart" ] && [ -n "$dl" ] && [ "$trial" -lt "$dl" ] && [ "$restart" -lt "$dl" ] &&
  ok "  ...the trial run (line $trial) and the restart on order 2 (line $restart) before the model's download (line $dl)" ||
  bad "  ...trial run at [$trial], restart at [$restart], download at [$dl]"
cmp -s "$DATA/bin/auster" "$T/common/auster" && cmp -s "$DATA/jobs/auster-engine" "$T/common/auster-engine" &&
  ok "  ...v0.2.0's programs in place" || bad "  ...the programs in place are not v0.2.0's"
[ -e "$DATA/jobs/previous" ] && bad "  ...jobs/previous left" || ok "  ...no jobs/previous left"
same "$(sed -n 2p "$S" | cut -f2)" "$IB1" "  ...order 1 serves"

# --- an earlier change never checked, the engine on the household's port not answering
mkdir -m 700 "$DATA/jobs/previous"; cp -p "$DATA/bin/auster" "$DATA/jobs/previous/auster"
waiting_b1
engine_set 'port=8484' behaviour nolisten
s0=$(cat "$S"); rm -rf "$STUB_CURL_DIR/requests"
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "jobs/previous there, the engine not answering: exit 4"
says "Auster's own programs were changed by an earlier update and never checked: the server restarts" "  ...the question says the programs are checked first"
says "The server restarts once to check them, before anything else changes" "  ...and the yes checks them first"
says "\`auster rollback\` puts the previous programs back" "  ...it names auster rollback"
same "$(requests | grep -c '^GET https://cdn\.example\.test/')" 0 "  ...nothing fetched from Hugging Face's CDN"
[ -d "$DATA/jobs/previous" ] && ok "  ...jobs/previous kept" || bad "  ...jobs/previous deleted"
same "$(cat "$S")" "$s0" "  ...serving as it was"
engine_set 'port=8484' behaviour ok
done_
