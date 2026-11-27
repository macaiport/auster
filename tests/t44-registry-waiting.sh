# T44, the registry's half: D3.7's "which build a recipe takes", against the build served
# (auRegRecipeLine). A registry listing builds 1 to 3: serving the first gives `same`; serving the
# second with the first held gives `same`; serving the second with the first free gives `waiting`;
# serving a withdrawn first gives the second as `waiting`. The Mac's word `current` (D3.2), and these
# cases through the rule file, are t44-update-recipes.sh (U3); `hold` is U6's, and section C's fit V3's:
# a judge function stands in for both here, through the hook registry-lib.js describes. Mutant: tests/mutants/T44a.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t44.XXXXXX")
extend "$REG/good-v0.1.0.tsv" "$W/three.tsv" "$(sed -n 9p "$REG/judgements.tsv")" "$(rec order $HH $B1 $B2 $B3)"
extend "$W/three.tsv" "$W/withdrawn.tsv" "$(rec withdraw $B1 security)"
extend "$W/three.tsv" "$W/narrowed.tsv" "$(rec recipe $HH household publisher 4 8192 32768)"

got=$(jxa "
var reg = auRegRead(argv[0]), regW = auRegRead(argv[1]), regN = auRegRead(argv[2]), R = '$HH', B1 = '$B1', B2 = '$B2', B3 = '$B3';
function says(code, ids) { return function (e) { return ids.indexOf(e.id) >= 0 ? [code] : []; }; }
function show(l) {
  return l.state + ' ' + (l.pick ? l.pick.id : '-') + ' ' + (l.servingWithdrawn ? l.servingWithdrawn.reason : '-') +
    (l.reasons.length ? ' ' + l.reasons.join(',') : '');
}
return [
  show(auRegRecipeLine(reg, R, B1)),
  show(auRegRecipeLine(reg, R, B2, says('held', [B1]))),
  show(auRegRecipeLine(reg, R, B2)),
  show(auRegRecipeLine(regW, R, B1)),
  show(auRegRecipeLine(reg, R, B3)),
  show(auRegRecipeLine(reg, R, B3, says('held', [B1, B2]))),
  show(auRegRecipeLine(reg, R, B2, says('fit', [B1]))),
  show(auRegRecipeLine(reg, R, B1, says('fit', [B1]))),
  show(auRegRecipeLine(reg, R, null)),
  show(auRegRecipeLine(reg, R, B1, says('held', [B1, B2, B3]))),
  show(auRegRecipeLine(regW, R, B1, says('held', [B2, B3]))),
  show(auRegRecipeLine(reg, 'rsvh4l2c3prht', B1)),
  show(auRegRecipeLine(regN, R, B1))
].join('\n');
" "$W/three.tsv" "$W/withdrawn.tsv" "$W/narrowed.tsv")
i=0
while IFS='|' read -r want what; do
  i=$((i + 1))
  same "$(printf '%s\n' "$got" | sed -n "${i}p")" "$want" "$what"
done <<EOF
same $B1 -|serving the first: same
same $B2 -|serving the second with the first held: same
waiting $B1 -|serving the second with the first free: waiting, for the first
waiting $B2 security|serving a withdrawn first: the second is waiting, and the withdrawal is said
waiting $B1 -|serving the third with the first free: waiting, for the first
same $B3 -|serving the third with the first two held: same
same $B2 -|serving the second when the first does not fit: same
waiting $B2 -|serving the first when it no longer fits: the second is waiting
waiting $B1 -|nothing served yet (a first install): the first is picked
passed over - - held|every build held: passed over, saying why
withdrawn - security withdrawn,held|serving a withdrawn first with the rest held: withdrawn
absent - -|a recipe the registry does not name: absent
same $B1 -|serving the first after a recipe line drops its tier: a later build is not offered (D3.7)
EOF
same "$(printf '%s\n' "$got" | wc -l | tr -d ' ')" "$i" "every case was answered"
done_
