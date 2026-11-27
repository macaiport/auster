# T31 (U5; D3.6 step 4, C5): fit is worked out again immediately before the test, and a way that changed stops the recipe.
# On a Mac with a GPU limit of 100,000 MiB serving order 2 for four at 32,768 with order 1 waiting, a stand-in sysctl
# reports 128 GB at the question and 64 GB when the memory is measured again: the question says the build is tested beside
# the one serving; after the download, worked out again, both no longer fit at once (order 1 alone still does), so the
# recipe stops with exit 3 and says why, before any candidate starts: the engine never stopped, serving as it was, and
# model A kept in store/ for the next update.
# Mutant: tests/mutants/T31a (decide the way once, at the question).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
engine_up
export AU_GPU_MIB=100000
mkdir -p "$W/fakebin"
cat > "$W/fakebin/sysctl" <<EOF
#!/bin/bash
if [ "\$*" = '-n hw.memsize' ]; then
  n=\$(cat "$W/mem-calls" 2>/dev/null || echo 0); n=\$((n + 1)); echo "\$n" > "$W/mem-calls"
  if [ "\$n" = 1 ]; then echo 137438953472; else echo 68719476736; fi
  exit 0
fi
exec "$TESTS/stubs/sysctl" "\$@"
EOF
chmod 755 "$W/fakebin/sysctl"
s0=$(cat "$DATA/builds/$IR/serving") pid=$(engine_pid) n=$(wc -l < "$STUB_LOG") c0=$(start_on $CPORT)   # c0: the install's own test
PATH="$W/fakebin:$PATH" update_run $'yes\n'
same "$RC" 3 "room for both at the question, not before the test: exit 3"
says "This Mac can hold both builds at once: the new one is tested beside the one serving" "  ...the question said side by side"
says "Worked out again before the test, this Mac can no longer hold both builds at once, as the question said it could." "  ...it says the way changed"
says "The recipe household is not updated: it keeps serving build $IB2. Build $IB1's files stay on this Mac, and \`auster update\` asks again." \
  "  ...and that the recipe keeps its build"
same "$(cat "$W/mem-calls")" 2 "  ...the memory measured at the question and again before the test"
same "$(start_on $CPORT)" "$c0" "  ...no candidate started"
same "$(job_calls "$n"):$(engine_pid)" ":$pid" "  ...the engine never stopped"
same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"
same "$(shasum -a 256 < "$DATA/store/$SA" 2>/dev/null | cut -c1-64)" "$SA" "  ...model A kept in store/"
done_
