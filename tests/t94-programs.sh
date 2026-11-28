# T94 (U5; B3 step 6, BD18): an update that changes Auster's own programs. Right after the yes, before anything else
# changes or is fetched (a repair of the build in use alone comes first, every file of it whole:
# tests/t118-repair-order.sh), the new bin/auster answers `status` from its temporary name; the programs in use are
# copied into jobs/previous/; the new ones are put in place and checked on the build already serving (a restart and the
# server check), which deletes jobs/previous/ when it passes. A new bin/auster that does not answer `status`: nothing
# renamed, exit 3. New programs whose engine job does not start the engine: exit 4 naming `auster rollback`, the new
# programs left in place (nothing put back by itself), the previous ones in jobs/previous/, which `auster status`
# reports, and no stamp. A later update over it copies nothing (it holds the programs last checked); a later update with
# nothing to change, and one with a change of setting, check the server before anything else and write no stamp and
# switch nothing on a fail; `auster restart` deletes jobs/previous/ only when its check passes. (What `auster rollback`
# does with jobs/previous/, clauses (e) and (f), is tests/t94-rollback.sh; "before any model fetch" against a real
# download is tests/t94-programs-build.sh.)
# Mutants: tests/mutants/T94b (put the programs back by itself), T94c (delete jobs/previous/ before a check passes),
# T94d (copy over an existing jobs/previous/), T94g (skip the trial run), T94h (a later update that does not check first).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
P="$DATA/jobs/previous" S="$DATA/builds/$IR/serving"
progs() { snapshot "$DATA/bin"; snapshot "$DATA/jobs"; }
stamp() { cut -f3 "$DATA/_update/scripts"; }
sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
release() { # VERSION COMMIT -> release names COMMIT, whose tree is $ROOT's; T, its source folder, to be changed and packed
  release_at "$1" "$2"; T="$FX/tree-src-$2" TC=$2
}
pack() { tree_archive "$T" "auster-$TC" "$TC" "$FX/tree-$TC.tar.gz"; }
no_temp() { [ -z "$(ls -A "$DATA/bin" | grep -v '^auster$')" ] && ok "$1: no temporary program left in bin/" || bad "$1: bin/ holds $(ls -A "$DATA/bin")"; }

# --- v0.2.0: its bin/auster and engine job differ, and pass
release v0.2.0 "$COMMIT2"
printf '# a change in v0.2.0\n' >> "$T/common/auster"; printf '# a change in v0.2.0\n' >> "$T/common/auster-engine"; pack
s0=$(cat "$S"); n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "v0.2.0's programs, answered yes: exit 0"
says "Auster's own programs change (from v0.1.0 to v0.2.0)" "  ...the question names the change"
tail -n +$((n + 1)) "$STUB_LOG" | grep -q '^launchctl print-disabled' && ok "  ...the new bin/auster answered status (its trial run)" || bad "  ...no trial run of the new bin/auster"
cmp -s "$DATA/bin/auster" "$T/common/auster" && ok "  ...the new bin/auster in place" || bad "  ...bin/auster is not v0.2.0's"
same "$(stat -f %Lp "$DATA/bin/auster")" 755 "  ...with mode 0755"
cmp -s "$DATA/jobs/auster-engine" "$T/common/auster-engine" && ok "  ...the new engine job in place" || bad "  ...jobs/auster-engine is not v0.2.0's"
no_temp "v0.2.0"
case "$(job_calls "$n")" in *'launchctl kickstart'*) ok "  ...the engine restarted on the build it serves" ;; *) bad "  ...no restart: $(job_calls "$n")" ;; esac
says "Auster's programs pass." "  ...and the server check made"
[ -e "$P" ] && bad "  ...jobs/previous is left after a passed check" || ok "  ...jobs/previous deleted after the passed check"
same "$(cat "$S")" "$s0" "  ...serving as it was"
same "$(stamp)" v0.2.0 "  ...the stamp of v0.2.0"
same "$(requests | grep -cE 'huggingface|cdn\.example|github\.com/ggml')" 0 "  ...nothing fetched for a model or an engine"

# --- v0.3.0: its bin/auster does not answer `status`
release v0.3.0 0f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
{ sed '$d' "$ROOT/common/auster"; printf 'au_status() { return 1; }\n'; tail -n 1 "$ROOT/common/auster"; } > "$T/common/auster"; pack
before=$(progs); n=$(wc -l < "$STUB_LOG")
update_run $'yes\n'
same "$RC" 3 "v0.3.0, whose bin/auster does not answer status: exit 3"
says "The auster command of v0.3.0 did not answer \`auster status\` on this Mac, so none of Auster's programs was changed" "  ...it says so"
same "$(progs)" "$before" "  ...bin/ and jobs/ as they were: nothing renamed, no jobs/previous"
same "$(job_calls "$n")" "" "  ...the engine not restarted"
same "$(stamp)" v0.2.0 "  ...and no stamp"

# --- v0.3.1: its engine job does not start the engine
release v0.3.1 1f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
printf '# a change in v0.3.1\n' >> "$T/common/auster"
awk '{ print } /^set -u$/ && !d { print "exit 1"; d = 1 }' "$ROOT/common/auster-engine" > "$T/common/auster-engine"; pack
mkdir "$W/v020"; cp -p "$DATA/bin/auster" "$DATA"/jobs/* "$W/v020/"
s0=$(cat "$S")
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "v0.3.1, whose engine job does not start the engine: exit 4"
says "Only Auster's own programs changed, on the build it served, so the fault is theirs." "  ...it says the fault is the programs'"
says "\`auster rollback\` puts the previous programs back" "  ...and names auster rollback"
same "$(ls "$P" 2>/dev/null | tr '\n' ' ')" "auster auster-check auster-engine capability-lib.js capability.js mint-id registry-lib.js registry.js " \
  "  ...jobs/previous holds the programs that were in use"
same "$(cd "$P" 2>/dev/null && for f in *; do printf '%s %s %s\n' "$f" "$(stat -f %Lp "$f")" "$(sha_of "$f")"; done)" \
  "$(cd "$W/v020" && for f in *; do printf '%s %s %s\n' "$f" "$(stat -f %Lp "$f")" "$(sha_of "$f")"; done)" "  ...byte for byte, with their modes"
same "$(stat -f %Lp "$P")" 700 "  ...in a folder of mode 0700"
cmp -s "$DATA/bin/auster" "$T/common/auster" && cmp -s "$DATA/jobs/auster-engine" "$T/common/auster-engine" &&
  ok "  ...v0.3.1's programs left in place: nothing put back by itself" || bad "  ...the programs in place are not v0.3.1's"
same "$(cat "$S")" "$s0" "  ...serving as it was"
same "$(stamp)" v0.2.0 "  ...no stamp"
auster status
outsays "Auster's own programs were changed by an update, and the server has not passed a check since (jobs/previous holds the ones before)." \
  "auster status reports jobs/previous"
prev=$(snapshot "$P")

# --- v0.3.2 (its programs as they should be) over jobs/previous, the engine not answering: nothing copied over it
release v0.3.2 2f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
engine_set '*' behaviour nolisten
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "v0.3.2 over jobs/previous, the engine not answering: exit 4"
says "jobs/previous already holds the programs from before an earlier change that was never checked, so nothing is copied over it." "  ...it says so"
same "$(snapshot "$P")" "$prev" "  ...jobs/previous still holds the programs last checked"
cmp -s "$DATA/bin/auster" "$ROOT/common/auster" && ok "  ...v0.3.2's programs in place" || bad "  ...bin/auster is not v0.3.2's"
same "$(stamp)" v0.2.0 "  ...no stamp"

# --- a later update with nothing to change finds jobs/previous: it checks first, and writes no stamp on a fail
rm -rf "$STUB_CURL_DIR/requests"
AU_SERVER_CHECK_SECS=4 update_run ''
same "$RC" 4 "an update with nothing to change, jobs/previous there, the engine not answering: exit 4"
says "Auster's own programs were changed by an earlier update whose server check never passed" "  ...it checks the server first"
says "\`auster rollback\` puts Auster's previous programs back" "  ...and names auster rollback"
same "$(stamp)" v0.2.0 "  ...no stamp"
[ -e "$P" ] && ok "  ...jobs/previous kept" || bad "  ...jobs/previous deleted"
same "$(requests | grep -cE 'huggingface|cdn\.example|github\.com/ggml')" 0 "  ...and nothing fetched"

# --- and one with a change of setting: the check comes first, on the setting served, and a fail switches nothing
engine_set '*' behaviour ok; engine_set 'ctx=65536' behaviour http500   # four at 16,384 fails, four at 32,768 answers
serving_put "$IB1" "$IMA" 4 16384 36.9
s0=$(cat "$S") k0=$(ls "$DATA/builds/$IR/kept")
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "a change of setting with jobs/previous there, the setting served failing: exit 4"
says "The server restarts once to check them, before anything else changes" "  ...the programs are checked first"
same "$(cat "$S"):$(ls "$DATA/builds/$IR/kept")" "$s0:$k0" "  ...and nothing switched: serving and kept/ as they were"
same "$(stamp)" v0.2.0 "  ...no stamp"

# --- auster restart deletes jobs/previous only when its check passes
AU_SERVER_CHECK_SECS=4 auster restart
same "$RC" 4 "auster restart, the check failing: exit 4"
[ -e "$P" ] && ok "  ...jobs/previous kept" || bad "  ...jobs/previous deleted before a check passed"
cp "$W/pristine/builds/$IR/serving" "$S"
auster restart
same "$RC" 0 "auster restart, the check passing: exit 0"
[ -e "$P" ] && bad "  ...jobs/previous left" || ok "  ...jobs/previous deleted"
auster status
grep -q 'jobs/previous' "$W/out" && bad "  ...status still reports it" || ok "  ...and status no longer reports it"
done_
