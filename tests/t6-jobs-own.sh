# T6's rule of ownership, the jobs' half (U7; D3.1, B4, B5): before any write, the data root (mode 0700) and every folder
# in it, at any depth, must be this account's and nobody else's to write, and no link in it may lead to a folder but
# inside an engine's unpacked tree. The engine job and the check job each hold to it: with a folder others may write in
# logs/, a folder its group may write deep in the engine's tree, or a link to a folder outside in a recipe's folder, the
# engine job writes no `start`, starts no engine and names the folder, and waits before it exits; the check job names it
# and does nothing (no `_update/engine`, no request, no notification); nothing in the data root changes. A data root of
# mode 0750 stops both. With the data root as the install left it both run, and the check job runs too with a link to a
# folder inside the engine's tree (the engine job would take that link for a changed engine, T34).
# Mutants: tests/mutants/T6h (the engine job) and T6i (the check job); T6e and T6f are common/auster's and the rule file's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
mkdir "$W/elsewhere"
PD=$(cd "$DATA" && pwd -P)   # the data root as the jobs find it (pwd -P), which is how they name its folders
RULE="must be a folder that only this account owns and can write, and no link in the data root may lead to a folder"

both_run() { # LABEL
  rm -f "$DATA/_update/engine"
  engine_job; engine_wait
  same "$EJ_CODE" starting "$1: the engine job starts the engine"
  check_job
  same "$(probe_field probe)" ok "  ...and the check job probes it and writes _update/engine"
  engine_job_end
}

refused() { # LABEL PATH -> both jobs refuse, naming PATH, and change nothing in the data root
  local before
  rm -f "$DATA/builds/$IR/start" "$DATA/_update/engine"
  rm -rf "$STUB_CURL_DIR/requests"; : > "$W/engine-job.out"; : > "$W/check.out"; : > "$STUB_NOTIFY_LOG"
  before=$(snapshot "$DATA")
  engine_job; engine_wait 30
  same "$EJ_CODE" none "$1: the engine job writes no start"
  same "$(starts)" "$NSTARTS" "  ...and starts no engine"
  kill -0 "$EJ" 2>/dev/null && ok "  ...and waits before it exits" || bad "  ...it exited at once: $(cat "$W/engine-job.out")"
  grep -qF "$2 must be a folder" "$W/engine-job.out" && grep -qF "nothing is written or started" "$W/engine-job.out" &&
    ok "  ...it names $2" || bad "  ...it says: $(cat "$W/engine-job.out")"
  engine_job_end
  check_job
  grep -qF "$2 must be a folder" "$W/check.out" && grep -qF "so nothing is done" "$W/check.out" && ok "  ...the check job names it and does nothing" ||
    bad "  ...the check job says: $(cat "$W/check.out")"
  [ -e "$DATA/_update/engine" ] && bad "  ...the check job wrote _update/engine" || ok "  ...no _update/engine"
  same "$(requests | wc -l | tr -d ' '):$(notes)" 0:0 "  ...no request, no notification"
  same "$(snapshot "$DATA")" "$before" "  ...and nothing in the data root changed"
}

both_run "the data root as the install left it"
mkdir -m 755 "$ED/root/lib-dir"; ln -s lib-dir "$ED/root/lib-link"
rm -f "$DATA/_update/engine"; : > "$W/check.out"
check_job
same "$(probe_field probe)" down "a link to a folder inside the engine's tree: the check job runs (the engine is not running: down)"
rm "$ED/root/lib-link"; rmdir "$ED/root/lib-dir"

mkdir "$DATA/logs/old"; chmod 777 "$DATA/logs/old"
refused "logs/old open to all" "$PD/logs/old"
grep -qF "$RULE" "$W/check.out" && ok "  ...in the rule's words" || bad "  ...the check job says: $(cat "$W/check.out")"
rmdir "$DATA/logs/old"
chmod 775 "$ED/root/llama-stub"
refused "a folder its group may write deep in the engine's tree" "$ED/root/llama-stub"
chmod 755 "$ED/root/llama-stub"
ln -s "$W/elsewhere" "$DATA/builds/$IR/more"
refused "a link to a folder outside, in the recipe's folder" "$PD/builds/$IR/more"
rm "$DATA/builds/$IR/more"

chmod 750 "$DATA"
rm -f "$DATA/builds/$IR/start"; : > "$W/engine-job.out"; : > "$W/check.out"
engine_job; engine_wait 30
same "$EJ_CODE:$(starts)" "none:$NSTARTS" "the data root of mode 0750: the engine job writes no start and starts nothing"
grep -qF "$PD must be a folder of mode 0700" "$W/engine-job.out" && ok "  ...and says the data root must be of mode 0700" ||
  bad "  ...it says: $(cat "$W/engine-job.out")"
engine_job_end
rm -f "$DATA/_update/engine"; check_job
[ -e "$DATA/_update/engine" ] && bad "  ...the check job wrote _update/engine" || ok "  ...and the check job does nothing"
chmod 700 "$DATA"

both_run "all put back"
done_
