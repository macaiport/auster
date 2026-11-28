# T137 (the conventions' audit, 2026-11-28; docs/conventions.md section 1, "A run's own temporary files"): the temporary
# folders of `auster people` (the installer it fetches), `auster cleanup` (the disk holdings and section C's answer) and
# updates.sh --recipes (the disk holdings and `df`) go on any exit, an interruption included. Each run is sent TERM while
# its folder exists in the test's own TMPDIR: `people` while GitHub's stub takes 3 s to answer, `cleanup` while a slow
# df (a wrapper of this test's own, 3 s) measures the disk, and --recipes while it judges the recipe (it is run again
# until TERM finds its folder). Each ends 143 and leaves no folder of Auster's in TMPDIR; run to its end, --recipes leaves
# none either and gives the recipe's line.
# Mutants: tests/mutants/T137a (people's folder by mktemp alone), T137b (cleanup's), T137c (updates.sh with no EXIT trap).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
cmd_install
T="$W/tmp"; mkdir -p "$T"; export TMPDIR="$T/"   # this test's own, so that whatever is left in it is these runs'
ours() { ls -A "$T" | grep '^auster-' | tr '\n' ' '; }   # Auster's temporary folders left in TMPDIR
seen() { # NAME -> 0 once $T/auster-NAME.* exists (30 s at most)
  local i
  for i in $(seq 1500); do [ -n "$(ls -d "$T/auster-$1".* 2>/dev/null)" ] && return 0; sleep 0.02; done
  return 1
}
bg_auster() { # ARG... -> bin/auster in the background as `auster` runs it; P its process
  printf '' > "$W/answers"
  HOME="$H" AU_TTY="$W/answers" AU_SCREEN="$W/screen" /bin/bash "$DATA/bin/auster" "$@" > "$W/out" 2>&1 &
  P=$!
}

# --- auster people: the installer fetched into a folder of its own
curl_route GET "$INSTALL_SH" sleep:3 -
bg_auster people 2
seen people && ok "auster people: its folder is made in TMPDIR" || bad "auster people: no folder: $(cat "$W/out")"
kill -TERM "$P"; wait "$P"; rc=$?
same "$rc" 143 "auster people, sent TERM while it fetches the installer: exit 143"
same "$(ours)" "" "  ...no folder of Auster's is left in TMPDIR"

# --- auster cleanup: the disk holdings and section C's answer
mkdir -p "$W/slow"
printf '#!/bin/bash\n/bin/sleep 3\nexec /bin/df "$@"\n' > "$W/slow/df"; chmod 755 "$W/slow/df"
PATH="$W/slow:$PATH" bg_auster cleanup
seen cleanup && ok "auster cleanup: its folder is made in TMPDIR" || bad "auster cleanup: no folder: $(cat "$W/out")"
kill -TERM "$P"; wait "$P"; rc=$?
same "$rc" 143 "auster cleanup, sent TERM while df measures the disk: exit 143"
same "$(ours)" "" "  ...no folder of Auster's is left in TMPDIR"
[ -e "$DATA/builds/updating" ] && bad "  ...the lock was left" || ok "  ...and the lock released"

# --- updates.sh --recipes: judged only with the release's registry and offer, as a check leaves them
waiting_b1
recipes() { AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" --recipes; }
out=$(recipes)
printf '%s\n' "$out" | grep -q "^recipe	$IR	waiting	" && ok "--recipes, run to its end: the recipe judged waiting" ||
  bad "--recipes: no waiting line: $out"
same "$(ours)" "" "  ...and no folder of Auster's is left in TMPDIR"
hit=0
for try in 1 2 3 4 5; do
  AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" --recipes > "$W/recipes.out" 2>&1 &
  P=$!
  if seen recipes && kill -TERM "$P" 2>/dev/null; then { wait "$P"; rc=$?; } 2>/dev/null; hit=1; break; fi
  wait "$P"
done
same "$hit:$rc" "1:143" "--recipes, sent TERM while its folder exists: exit 143"
same "$(ours)" "" "  ...no folder of Auster's is left in TMPDIR"
done_
