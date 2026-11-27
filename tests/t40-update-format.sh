# T40 (A3, D3.3): a registry whose first line says format 2 is fetched like any other (its version line agrees
# with the changelog's) but is not read: every recipe this Mac serves shows `passed over (cannot be read)`, nothing
# is waiting, and the word stays the versions'. In format 1, a line of an unknown kind is passed over and the rest
# are used: the recipe's line is what it would be without that line. Through the check itself and then through
# the recipe's line. Mutants: tests/mutants/T40a (read a format-2 file as format 1) and T40b (fail the whole
# file on an unknown kind).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.1.0
reg_as v0.1.0 "$W/format2.tsv" "$REGF/format-2.tsv"
same "$(head -n 1 "$W/format2.tsv")" "auster-registry${TAB}2${TAB}v0.1.0" "the fixture: format 2, of v0.1.0"

recipes() { # REGISTRY -> serving order 2 on the 64 GB Mac, after a check that fetched REGISTRY with the changelog
  fresh; stamp release v0.1.0; mac_put 53084 $GB64; served $HH $B2 4 32768
  answer_reg 200 "$1"; answer 200 "$W/cl"
  same "$(upd --refresh | cut -f5)" fetched "${1##*/}: the check fetched it"
  same "$(cmp -s "$U/registry" "$1" && echo same)" same "  ...and kept it as it came"
}

recipes "$W/format2.tsv"
o=$(upd --recipes)
same "$(printf '%s\n' "$o" | head -n 1 | cut -f1)" current "format 2: current, nothing waiting"
same "$(line_of $HH "$o" | cut -f3,4,7)" "passed-over${TAB}unreadable$TAB-" "  ...the recipe passed over, cannot be read, no build named"
same "$(line_of $HH "$o" | cut -f13)" "-" "  ...and no label read from it"
for f in good-v0.1.0.tsv unknown-kind.tsv; do
  recipes "$REGF/$f"
  same "$(upd --recipes | head -n 1 | cut -f1):$(rfield $HH 3):$(rfield $HH 7):$(rfield $HH 13)" "ready:waiting:$B1:household" \
    "$f: order 1 waiting, the recipe's label read"
done
same "$(grep -c '^tool' "$REGF/unknown-kind.tsv")" 1 "unknown-kind.tsv holds a line of the kind tool"
done_
