# T55, the installer's half (U2; A5, D3.1): after an install, `serving` holds `auster-descriptor 1`, then the build,
# engine and model lines of the fixed commit's registry byte for byte -- with the fields after the last one this
# version knows, empty ones and one not in ASCII among them -- then the launch line, and nothing else; and they
# come from the tree's registry, never from `_update/registry`, which an earlier check may have left with other
# figures. The engine job and the server check read it as it is. The kept copy is the switch's (U5). Mutants:
# tests/mutants/T55a (the reader's: rewrite only the known fields) and T55b (take the figures from _update/registry).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
T=$'\t'
install_registry "$W/plain.tsv"
awk -v t="$T" -v b="$IB1" -v e="$IE" -v m="$IMA" '
  $1 == "build" && $2 == b { $0 = $0 t "later=1" }
  $1 == "engine" && $2 == e { $0 = $0 t t "more" }
  $1 == "model" && $2 == m { $0 = $0 t "future" t "caf\303\251" }
  { print }' "$W/plain.tsv" > "$FX/registry.tsv"
install_tree "$FX/registry.tsv"
mkdir -m 700 "$DATA" "$DATA/_update"
: > "$DATA/.auster-data-root"
sed "s/${T}dev-mac-64gb\$/${T}other-mac/" "$W/plain.tsv" > "$DATA/_update/registry"   # an earlier check's copy, other figures
grep -q other-mac "$DATA/_update/registry" && ok "the fixture: _update/registry names other figures" || bad "the fixture's _update/registry"

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "installed: exit 0"
S="$DATA/builds/$IR/serving"
same "$(wc -l < "$S" | tr -d ' ')" 5 "serving: five lines, and nothing else"
same "$(sed -n 1p "$S")" "auster-descriptor 1" "the first, auster-descriptor 1"
for k in "2 build $IB1" "3 engine $IE" "4 model $IMA"; do
  set -- $k
  awk -F'\t' -v k="$2" -v i="$3" '$1 == k && $2 == i' "$FX/registry.tsv" > "$W/want"
  sed -n "${1}p" "$S" > "$W/got"
  cmp -s "$W/got" "$W/want" && ok "line $1, the $2 line, byte for byte as the tree's registry has it, with the fields this version does not know" ||
    bad "the $2 line: got [$(cat "$W/got")], expected [$(cat "$W/want")]"
done
same "$(sed -n 2,4p "$S" | cut -f1 | paste -sd, -)" "build,engine,model" "in the order build, engine, model"
same "$(sed -n 5p "$S" | awk -F'\t' '{ print NF, $1, $2, $4 }')" "6 launch 4 8484" "the launch line last: six fields"
grep -q other-mac "$S" && bad "serving holds _update/registry's figures" || ok "nothing from _update/registry"
same "$(sed -n 5p "$S" | cut -f6)" 36.9 "the server check read it, and wrote the speed it measured"
done_
