# T9 (U5; D3.6 steps 4 and 5, B3 step 10): a candidate that fails its test. On a Mac serving order 2 with order 1 waiting,
# the candidate (the stub engine on the candidate's port) answering every question badly: in turn (this 64 GB Mac cannot
# hold both builds), exit 3, serving byte for byte as it was, the candidate's descriptor in failed/ (named by the date and
# the build, with the household's setting and a speed of 0), builds/paused gone, the candidate stopped before the engine
# job started again, and the server answering a household key on the old build. Side by side (a Mac that holds both),
# the same, the candidate tested for one person at 8,192, the serving engine restarted after the fail (kickstart -k), and
# no candidate left running.
# Mutants: tests/mutants/T9a (rewrite serving before the test), T9b (in turn, leave the engine job stopped), T9c (side by
# side, leave the candidate running).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2 for four at 32,768, order 1 waiting
engine_up
engine_set "port=$CPORT" answers "$FX/answers-bad"
S="$DATA/builds/$IR/serving"
failed() { ls "$DATA/builds/$IR/failed" 2>/dev/null | tr '\n' ' '; }
checks() { # LABEL -> what both ways must leave
  local c f e
  same "$(cat "$S")" "$s0" "$1: serving byte for byte as it was"
  f=$(ls "$DATA/builds/$IR/failed" | grep -vxF -f "$W/failed-before" | head -n 1)
  [[ $f =~ ^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z-$IB1$ ]] && ok "$1: the candidate's descriptor in failed/, named by the date and the build" ||
    bad "$1: failed/ holds [$(failed)]"
  same "$(sed -n 2p "$DATA/builds/$IR/failed/$f" | cut -f2) $(sed -n 5p "$DATA/builds/$IR/failed/$f" | cut -f1-4,6)" "$IB1 launch	4	32768	8484	0" \
    "$1: ...a descriptor of order 1 at the household's setting, with a speed of 0"
  [ -e "$DATA/builds/paused" ] && bad "$1: builds/paused is left" || ok "$1: no builds/paused left"
  c=$(start_on $CPORT); e=$(start_on 8484)
  [ -n "$c" ] && [ "$(arg_of "$c" --alias)" = "$IB1" ] && ok "$1: the candidate was order 1" || bad "$1: no candidate of order 1: [$c]"
  [ -f "$c/stopped" ] && [ ! -f "$STUB_ENGINE_DIR/ports/$CPORT" ] && ok "$1: the candidate is stopped" || bad "$1: the candidate is still running"
  [ -f "$c/stopped" ] && [ "$(cut -d' ' -f1 "$c/stopped")" -le "$(cat "$e/started")" ] && ok "$1: ...before the engine served again" ||
    bad "$1: the candidate stopped at $(cat "$c/stopped" 2>/dev/null), the engine started at $(cat "$e/started")"
  same "$(arg_of "$e" --alias) $(ask_engine "$(key_of ipad)")" "$IB2 200" "$1: the server answers a household key, on order 2"
}

# --- in turn
s0=$(cat "$S"); ls "$DATA/builds/$IR/failed" > "$W/failed-before" 2>/dev/null
update_run $'yes\n'
same "$RC" 3 "in turn, a candidate that fails its test: exit 3"
says "This Mac cannot hold both builds at once: the server stops while build $IB1 is tested." "  ...the server stopped for the test"
says "Build $IB1 did not pass the recipe's test on this Mac. The recipe household stays on build $IB2." "  ...it says the test failed"
says "The server answered on build $IB2" "  ...and the server check passed on the old build"
checks "in turn"
same "$(arg_of "$(start_on $CPORT)" -c) $(arg_of "$(start_on $CPORT)" -np)" "131072 4" "in turn: the candidate tested at the household's setting"

# --- side by side
big_mac
rm -f "$DATA/builds/$IR"/failed/*   # so that order 1 is offered again without --retry
s0=$(cat "$S"); : > "$W/failed-before"
n=$(wc -l < "$STUB_LOG")
update_run $'yes\n'
same "$RC" 3 "side by side, a candidate that fails its test: exit 3"
says "This Mac can hold both builds at once: build $IB1 is tested beside the one serving, which keeps answering." "  ...tested side by side"
checks "side by side"
same "$(arg_of "$(start_on $CPORT)" -c) $(arg_of "$(start_on $CPORT)" -np)" "8192 1" "side by side: the candidate tested for one person at 8,192"
case "$(job_calls "$n")" in *'launchctl kickstart'*) ok "side by side: the serving engine restarted after the fail" ;; *) bad "side by side: no restart: $(job_calls "$n")" ;; esac
done_
