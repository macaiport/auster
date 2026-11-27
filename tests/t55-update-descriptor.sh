# T55, the update's half (U5; A5, D3.1, D3.6 step 5): after an update to a new build, serving holds `auster-descriptor
# 1`, then the build, engine and model lines of the fixed commit's registry byte for byte -- with fields after the last
# one this version knows, an empty one and one not in ASCII among them -- then the launch line, and nothing else; the
# kept copy is the descriptor served before, byte for byte; and the lines come from the tree's registry, never from
# `_update/registry`, which an earlier check left with other figures. The engine job read it as it is, and the server
# check wrote the speed it measured.
# Mutants: tests/mutants/T55c (the update takes the figures from _update/registry), and T55a (the reader's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
T=$'\t'
update_install
waiting_b1   # serving order 2, order 1 waiting
R="$FX/registry-v0.2.0.tsv"
install_registry "$W/plain.tsv" v0.2.0
awk -v t="$T" -v b="$IB1" -v e="$IE" -v m="$IMA" '
  $1 == "build" && $2 == b { $0 = $0 t "later=1" }
  $1 == "engine" && $2 == e { $0 = $0 t t "more" }
  $1 == "model" && $2 == m { $0 = $0 t "future" t "caf\303\251" }
  { print }' "$W/plain.tsv" > "$R"
install_tree "$R" "$COMMIT2"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"
sed "s/${T}dev-mac-64gb\$/${T}other-mac/" "$W/plain.tsv" > "$DATA/_update/registry"   # an earlier check's copy, other figures
S="$DATA/builds/$IR/serving"
s0=$(cat "$S")

update_run $'yes\n'
same "$RC" 0 "updated to order 1: exit 0"
same "$(wc -l < "$S" | tr -d ' ')" 5 "serving: five lines, and nothing else"
same "$(sed -n 1p "$S")" "auster-descriptor 1" "the first, auster-descriptor 1"
for k in "2 build $IB1" "3 engine $IE" "4 model $IMA"; do
  set -- $k
  awk -F'\t' -v k="$2" -v i="$3" '$1 == k && $2 == i' "$R" > "$W/want"
  sed -n "${1}p" "$S" > "$W/got"
  cmp -s "$W/got" "$W/want" && ok "line $1, the $2 line, byte for byte as the tree's registry has it, with the fields this version does not know" ||
    bad "the $2 line: got [$(cat "$W/got")], expected [$(cat "$W/want")]"
done
same "$(sed -n 5p "$S" | awk -F'\t' '{ print NF, $1, $2, $3, $4 }')" "6 launch 4 32768 8484" "the launch line last: six fields"
grep -q other-mac "$S" && bad "serving holds _update/registry's figures" || ok "nothing from _update/registry"
same "$(sed -n 5p "$S" | cut -f6)" 36.9 "the engine job read it, and the server check wrote the speed it measured"
k=$(ls -d "$DATA/builds/$IR"/kept/* | head -n 1)
same "$(cat "$k")" "$s0" "the kept copy: the descriptor served before, byte for byte"
done_
