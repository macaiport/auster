# T94 (e, f), and the row "a record's format and rollback" (U6; B3 step 6, BD18, D3.6): `auster rollback` while
# jobs/previous/ exists puts Auster's previous programs back and changes no build, whatever kept/ holds and whatever is
# answered. v0.2.0 (its bin/auster differs, its engine job does not start the engine, and it reads `start` and
# _update/engine in a newer format, as a release that changed theirs would): after its update fails (exit 4), with a
# `start` and an _update/engine of that newer format left: rollback puts the programs back byte for byte with their
# modes, deletes jobs/previous, deletes the records the programs write again themselves, and the bin/auster put back
# starts the engine (kickstart -k, its job loaded) and checks it, exit 0, serving and kept/ as they were, `auster status`
# naming no record of a newer format. v0.2.1 (its bin/auster differs) whose server answers a request with no key: the
# update stops it (exit 4, builds/stopped open); rollback starts it with enable and bootstrap, deletes builds/stopped,
# exit 0. v0.2.2 as v0.2.0, the engine then not answering: rollback still puts the programs back and deletes
# jobs/previous, exit 4.
# Mutants: tests/mutants/T94e (rollback changing the build while jobs/previous exists), T94f (rollback using kickstart
# while stopped), T94i (leave the records the programs taken out wrote, for the ones put back).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
P="$DATA/jobs/previous" S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept"
progs() { snapshot "$DATA/bin"; snapshot "$DATA/jobs"; }
kept_put "$IB2" "$IMB" 4 32768 36.9 2026-11-20T10:00:00Z
p0=$(progs) s0=$(cat "$S") k0=$(ls "$K")
release() { # VERSION COMMIT [broken] -> release names COMMIT, its bin/auster changed; with broken, its engine job exits at once
  release_at "$1" "$2"
  local t="$FX/tree-src-$2"
  printf '# a change in %s\n' "$1" >> "$t/common/auster"
  if [ "${3:-}" = broken ]; then awk '{ print } /^set -u$/ && !d { print "exit 1"; d = 1 }' "$ROOT/common/auster-engine" > "$t/common/auster-engine"; fi
  tree_archive "$t" "auster-$2" "$2" "$FX/tree-$2.tar.gz"
}
back() { # LABEL -> the programs as they were before the update, jobs/previous gone, and no build changed
  same "$(progs)" "$p0" "$1: the programs put back, byte for byte, with their modes, and jobs/previous gone"
  same "$(cat "$S"):$(ls "$K")" "$s0:$k0" "$1: no build changed: serving and kept/ as they were"
}

# --- v0.2.0: the engine job does not start the engine; it reads `start` and _update/engine in a newer format
release v0.2.0 "$COMMIT2" broken
t="$FX/tree-src-$COMMIT2"
awk '{ print } /^au_newer\(\) \{/ { print "  case \"$1\" in */start|*/_update/engine) return 1 ;; esac" }' "$t/common/auster" > "$W/a" && cat "$W/a" > "$t/common/auster"
tree_archive "$t" "auster-$COMMIT2" "$COMMIT2" "$FX/tree-$COMMIT2.tar.gz"
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "v0.2.0, whose engine job does not start the engine: exit 4"
[ -d "$P" ] && ok "  ...jobs/previous holds the programs before" || bad "  ...no jobs/previous"
printf 'auster-record 2\ncode\tstarting\n' > "$DATA/builds/$IR/start"
printf 'auster-record 2\n' > "$DATA/_update/engine"
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'1\n' auster rollback
same "$RC" 0 "auster rollback with jobs/previous there: exit 0"
outsays "Putting back Auster's programs from before the last update changed them (jobs/previous); no build is changed." "  ...it says so"
back "  ..."
case "$(job_calls "$n")" in *'launchctl enable launchctl kickstart'*) ok "  ...the engine restarted (its job loaded: kickstart -k)" ;; *) bad "  ...no kickstart: $(job_calls "$n")" ;; esac
outsays "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...and checked by the programs put back"
same "$(head -n 1 "$DATA/builds/$IR/start")" "auster-record 1" "  ...start written again, by the engine job put back"
auster status
grep -q 'newer version' "$W/out" && bad "  ...status reports a record of a newer format: $(grep 'newer version' "$W/out")" || ok "  ...and status reports no record of a newer format"
grep -q 'jobs/previous' "$W/out" && bad "  ...status still reports jobs/previous" || ok "  ...nor jobs/previous"

# --- v0.2.1: the server answers a request with no key, so the update stops it
release v0.2.1 1a1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
engine_set '*' behaviour open
update_run $'yes\n'
same "$RC" 4 "v0.2.1, whose server answers a request with no key: exit 4"
same "$(cut -f1,2 "$DATA/builds/stopped" 2>/dev/null)" "auster-record 1	open" "  ...builds/stopped says open"
engine_set '*' behaviour ok
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'1\n' auster rollback
same "$RC" 0 "auster rollback while stopped: exit 0"
same "$(job_calls "$n")" "launchctl enable launchctl bootstrap " "  ...the engine started with enable, then bootstrap"
[ -e "$DATA/builds/stopped" ] && bad "  ...builds/stopped is left" || ok "  ...builds/stopped deleted"
engine_alive && ok "  ...the engine runs" || bad "  ...no engine"
back "  ..."

# --- v0.2.2: the engine job does not start the engine, and after rollback the engine does not answer
release v0.2.2 2a1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d broken
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "v0.2.2: exit 4"
engine_set '*' behaviour nolisten
AU_SERVER_CHECK_SECS=4 ANSWERS=$'1\n' auster rollback
same "$RC" 4 "auster rollback, the engine not answering: exit 4"
back "  ...whatever the check gives"
engine_set '*' behaviour ok
done_
