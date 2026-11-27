# T22, the update's half (U3; A3, D3.3): a registry fetched by the check, holding lines with ../, a leading -,
# $(...), a non-hex sha256 or letters in a size (hostile.tsv), and here a build of the model whose file name is
# $(touch f).gguf put first by a later order line: each such line is passed over, the build and the order line
# that name what was passed over go with it, the other lines are used, and the recipe's line is what the earlier
# order makes it (serving order 1: same, nothing waiting). No file f is made, in the folder the check runs in or
# beside the registry, and nothing of those lines is printed. Mutant: tests/mutants/T22a, the registry's
# (split the line and use the fields unmatched), which runs this file with t22-registry-hostile.sh.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
BX=bnvcxbtneqk7r   # a build of the model whose file is $(touch f).gguf (tests/fixtures/registry/README)
changelog "$W/cl" v0.1.0
{ cat "$REGF/hostile.tsv"
  grep "^build${TAB}$B2${TAB}" "$REGF/hostile.tsv" | awk -F'\t' -v OFS='\t' -v b=$BX '{ $2 = b; $4 = "mxxcb4456zr2v"; print }'
  printf 'order\t%s\t%s\t%s\t%s\n' $HH $BX $B1 $B2; } > "$W/hostile.tsv"
same "$(grep -c '$(touch f).gguf' "$W/hostile.tsv"):$(tail -n 1 "$W/hostile.tsv" | cut -f3)" "1:$BX" "the fixture: hostile.tsv, a build of \$(touch f).gguf, ordered first"
mkdir "$W/run"; cd "$W/run" || exit 1

fresh; stamp release v0.1.0; mac_put 53084 $GB64; served $HH $B1 4 32768
answer_reg 200 "$W/hostile.tsv"; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,5)" "current${TAB}fetched" "the check takes the registry (it agrees with the changelog): current"
o=$(upd --recipes)
same "$(line_of $HH "$o" | cut -f3-8)" "same$TAB-$TAB$B1$TAB-$TAB-$TAB-" "the recipe serving order 1: same, nothing waiting, nothing withdrawn"
same "$(line_of $HH "$o" | cut -f13)" household "  ...its label read from the lines that were used"
case "$o" in *touch*|*'../'*|*-rf*|*zz594d*|*17e6*) bad "something from a hostile line was printed: $o" ;; *) ok "nothing from a hostile line is printed" ;; esac
same "$(ls -A "$W/run"):$([ -e "$W/f" ] || [ -e "$U/f" ] && echo f || echo none)" ":none" "no file f was made, here or beside the registry"

# The same lines on a Mac serving order 2: order 1 is waiting, as it is without them, and the build the hostile
# order puts first is never offered
fresh; stamp release v0.1.0; offer v0.1.0; cp "$W/hostile.tsv" "$U/registry"; mac_put 53084 $GB64; served $HH $B2 4 32768
same "$(rfield $HH 3):$(rfield $HH 7)" "waiting:$B1" "serving order 2 with the hostile lines present: order 1 waiting, as without them"
same "$(ls -A "$W/run")" "" "  ...and still no file made"
done_
