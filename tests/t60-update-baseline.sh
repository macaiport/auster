# T60, the update's clause (U5; A5, A7, BD8, B3 step 13, D3.6 step 5): the test's speed is never this Mac's baseline; the
# speed the server check measures after the switch is. On a Mac that holds both builds (a GPU limit of 100,000 MiB and
# 128 GB), serving order 2 with order 1 waiting, the candidate reports 99.9 tokens a second for every answer, the speed
# question among them, and the engine the engine job starts on the household's port reports 41.7 for the speed question
# (12.5 for anything else): after a side-by-side test and the switch, serving's launch line holds 41.7. In turn (this
# 64 GB Mac), the same.
# Mutants: tests/mutants/T60d (record the test's speed in serving at the switch), and T60a to T60c (recipe-test.js's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
engine_up
awk -F'\t' '{ print $2 "\t" $3 "\t99.9\t0" }' "$TESTS/fixtures/recipe-test/answers.tsv" > "$W/answers-fast"
printf 'Count from 1 to\t1\\n2\\n3\t99.9\t0\n' >> "$W/answers-fast"
printf 'Count from 1 to\t1\\n2\\n3\t41.7\t0\n*\tok\t12.5\t0\n' > "$W/answers-serving"
engine_set "port=$CPORT" answers "$W/answers-fast"
engine_set 'port=8484' answers "$W/answers-serving"
speed() { sed -n 5p "$DATA/builds/$IR/serving" | cut -f6; }

big_mac
waiting_b1
update_run $'yes\n'
same "$RC" 0 "side by side, updated to order 1: exit 0"
says "  speed 99.9 tok/s (reported only: it never decides the result)" "  ...the test reported 99.9"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2) $(speed)" "$IB1 41.7" "  ...the baseline is the server check's 41.7, not the test's"

unset AU_GPU_MIB STUB_MEMSIZE
waiting_b1
update_run $'yes\n'
same "$RC" 0 "in turn, updated to order 1: exit 0"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2) $(speed)" "$IB1 41.7" "  ...the baseline is the server check's 41.7, not the test's"
done_
