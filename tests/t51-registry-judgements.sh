# T51: two `recipe` lines for one recipe: the later label, people and context range are used, and both
# stay in the file. Two `order` lines: the later order is used. A build in no `order` line is never chosen
# (A3, D3.7). Mutants: tests/mutants/T51a and T51b.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"

# judgements.tsv: a build in no order line (line 9), a later recipe line (family-helper, 2 people,
# 8,192 to 16,384) and a later order line (order 2, then order 1)
o=$(reader "$REG/judgements.tsv" "$HH"); same $? 0 "judgements: read"
same "$(passed_lines "$o")" "" "no line is passed over"
same "$(grep -c '^recipe' "$REG/judgements.tsv") $(grep -c '^order' "$REG/judgements.tsv")" "2 2" "both recipe lines and both order lines are in the file"
same "$(kind "$o" recipe | cut -f5-9 | tr '\t' ' ')" "family-helper publisher,endorsed 2 8192 16384" "the later recipe line is used"
same "$(kind "$o" build | cut -f2,5 | tr '\t\n' ' ')" "1 $B2 2 $B1 " "the later order is used, and lists only its two builds"
same "$(taken "$o")" "$B2" "order 2 is taken"
got=$(jxa "
var reg = auRegRead(argv[0]);
var held = function (e) { return e.id === '$B1' || e.id === '$B2' ? ['held'] : []; };
var c = auRegChoose(reg, '$HH', held);
return (c ? c.id : 'none') + ' ' + ('$B3' in reg.builds) + ' ' + reg.lines[9].kind + ' ' + reg.lines[10].accepted;
" "$REG/judgements.tsv")
same "$got" "none true recipe true" "with both ordered builds held, nothing is chosen: the build in no order line is read but never chosen"
done_
