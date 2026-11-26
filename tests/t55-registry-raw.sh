# T55, the reader's half: each line a Mac reads keeps its raw text byte for byte, fields after the last one
# this version knows included, so that a descriptor can copy the build, engine and model lines word for
# word (A3, A5). That `serving` and the kept copy hold exactly those lines, and that they are taken from the
# fixed commit's registry, not from `_update/registry` (the plan's mutant (b)), is U2's half. Mutant:
# tests/mutants/T55a.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t55.XXXXXX")

# Order 2's build line with two fields this version does not know, one of them not ASCII; the engine line
# with an empty field after its last; Magistral's model line with an empty field and then another
awk -v t="$T" 'NR == 2 { $0 = $0 t } NR == 4 { $0 = $0 t t "later=1" } NR == 6 { $0 = $0 t "future" t "caf\303\251" } { print }' \
  "$REG/good-v0.1.0.tsv" > "$W/reg.tsv"
o=$(reader "$W/reg.tsv" "$HH"); same $? 0 "read"
same "$(passed_lines "$o")" "" "no line is passed over"
same "$(kind "$o" build | awk -F'\t' '{ print NF }' | paste -sd, -)" 33,33 "the build lines carry the known fields only"
same "$(kind "$o" build | awk -F'\t' '$5 == "'$B2'" { print $17, $33 }')" "dev-mac-64gb 131072" "the last known fields are read as they are"
for k in build:6 engine:2 model:4; do
  printf '%s\n' "$o" | awk -F'\t' -v b=$B2 -v k=${k%:*} '$1 == "raw" && $2 == b && $3 == k' | cut -f4- > "$W/got"
  sed -n "${k#*:}p" "$W/reg.tsv" > "$W/want"
  cmp -s "$W/got" "$W/want" && ok "the $k line, byte for byte, with what follows its last known field" || \
    bad "the $k line: got [$(cat "$W/got")], expected [$(cat "$W/want")]"
done
got=$(jxa "
var reg = auRegRead(argv[0]), b = reg.builds['$B2'];
return [b.raw === reg.lines[5].raw, b.extra, reg.models[b.model].extra, reg.engines[b.engine].extra, b.raw.length].join(' ');
" "$W/reg.tsv")
same "$got" "true 2 2 1 $(( $(sed -n 6p "$W/reg.tsv" | wc -c) - 1 ))" "the library keeps raw as bytes and counts the fields it did not read"
g=$(gate "$W/reg.tsv"); same "$?" 1 "the gate fails a field this version does not know (until a version that knows it changes the gate)"
same "$(printf '%s\n' "$g" | cut -d: -f1 | paste -sd, -)" "line 2,line 4,line 6" "and names the three lines"
done_
