# T109, its clauses that need no download (U5; B3 step 13, D3.6): after an update's switch, a server that answers HTTP 500
# (the stub engine failing at the new setting, as a build that does not fit with its fitting off; the change here is of
# setting, since a change of build is U5's second half): nothing switches back, serving holds the new setting with a
# speed of 0, failed/ is unchanged, no stamp is written (release is at v0.2.0, so a stamp would move), the run says the
# server did not answer and names `auster rollback`, exit 4. A second update then prints OK for the recipe, makes the
# server check, and exits 4 again with no stamp. A `start` older than this run's start of the engine (the engine job
# waiting on a live `paused`) is reported as "the engine job has not run since", never as its last code. At a first
# install: exit 4, both jobs still loaded, the keys not shown, no stamp, and `auster status` giving the start code.
# (`auster rollback` serving the old setting with a speed of 0 until its check passes, and holding nothing for a change
# of setting, is U6's.) Mutants: tests/mutants/T109a (report success), T109b (put the build in failed/), T109c (report a
# stale start code as current), T109d (unload the jobs at a first install), T109e (switch back by itself), T109f (write
# the stamp on the second run).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving"
launch() { sed -n 5p "$S" | cut -f1-4,6; }
stamp() { cut -f3 "$DATA/_update/scripts"; }
failed() { ls -A "$DATA/builds/$IR/failed" 2>/dev/null | tr '\n' ' '; }

release_at v0.2.0 "$COMMIT2"
serving_put "$IB1" "$IMA" 4 16384 36.9      # 32,768 fits this Mac: a change of setting
engine_set 'ctx=131072' behaviour http500   # four at 32,768 answers every question with HTTP 500
f0=$(failed)
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "a switch whose server answers HTTP 500: exit 4"
says "The server did not answer its check within 4 s" "  ...it says the server did not answer"
says "\`auster rollback\` goes back to what it served before, with no download." "  ...and names auster rollback"
same "$(sed -n 2p "$S" | cut -f2) $(launch)" "$IB1 launch	4	32768	8484	0" "  ...serving holds the new setting with a speed of 0: nothing switches back"
same "$(sed -n 5p "$DATA"/builds/$IR/kept/* | cut -f1-4,6)" "launch	4	16384	8484	36.9" "  ...the setting before in kept/"
same "$(failed)" "$f0" "  ...failed/ unchanged"
same "$(stamp)" v0.1.0 "  ...no stamp"

AU_SERVER_CHECK_SECS=4 update_run ''
same "$RC" 4 "a second update: exit 4 again"
says "The recipe household: OK. Build $IB1 serves it, for 4 people at 32,768 tokens each." "  ...it prints OK for the recipe"
says "The server has not passed a check since its build was last switched" "  ...it makes the server check"
same "$(launch)" "launch	4	32768	8484	0" "  ...serving as it was"
same "$(stamp)" v0.1.0 "  ...no stamp"

# --- a start older than this run's start of the engine: the engine job waits on a live `paused`
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
printf 'auster-record 1\t%s\t%s\tThu Nov 20 10:00:00 2026\n' "$live" "$(sysctl -n kern.bootsessionuuid)" > "$DATA/builds/paused"
awk -F'\t' -v OFS='\t' -v t=$(( $(date +%s) - 100 )) '$1 == "time" { $2 = t } { print }' "$DATA/builds/$IR/start" > "$W/start" &&
  cat "$W/start" > "$DATA/builds/$IR/start"
AU_SERVER_CHECK_SECS=3 auster restart
same "$RC" 4 "auster restart while the engine job waits on paused: exit 4"
outsays "the engine job has not run since this run started it" "  ...the start before this run is reported as such"
grep -q 'last start says' "$W/out" && bad "  ...it reports the stale start code as current" || ok "  ...and not as its last code"
rm -f "$DATA/builds/paused"; { kill "$live"; wait "$live"; } 2>/dev/null
engine_set 'ctx=131072' behaviour ok

# --- a first install
release_at v0.1.0 "$COMMIT"   # release back at the installer's own version, so that the paste is not a named version's
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 0 "auster remove, everything deleted"
engine_set 'port=8484' behaviour nolisten
rm -rf "$STUB_ENGINE_DIR/ports/8484"; : > "$W/screen"
AU_SERVER_CHECK_SECS=4 run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 4 "a first install whose server does not answer: exit 4"
says "The server did not answer its check within 4 s" "  ...it says so"
loaded "$EJOB" && loaded "$CJOB" && ok "  ...both jobs still loaded" || bad "  ...a job was unloaded"
says "The device keys are made but not shown" "  ...the keys made but not shown"
same "$(wc -c < "$W/screen" | tr -d ' ')" 0 "  ...no QR code drawn"
[ -e "$DATA/_update/scripts" ] && bad "  ...a stamp was written" || ok "  ...no stamp"
auster status
outsays "The engine job's last start: starting." "  ...auster status gives the engine job's start code"
engine_set 'port=8484' behaviour ok
done_
