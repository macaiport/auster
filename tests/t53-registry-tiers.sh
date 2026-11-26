# T53: tiers. Allowed `publisher,endorsed` takes order 1 (`endorsed`); allowed `publisher` takes order 2;
# the tier is read from the `model` line; an unknown tier passes its line over (A3, D3.7). Mutants:
# tests/mutants/T53a and T53b.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t53.XXXXXX")

# tier.tsv: a third-party build first in a later order, then order 1 and order 2
o=$(reader "$REG/tier.tsv" "$HH")
same "$(kind "$o" build | cut -f2,3,5,32 | tr '\t\n' ' ')" "1 tier b4cvp4l4ee5tl third-party 2 ok $B1 endorsed 3 ok $B2 publisher " \
  "tier.tsv: the third-party build is ruled out by its tier, with its tier shown"
same "$(taken "$o")" "$B1" "allowed publisher,endorsed: order 1 (endorsed) is taken"
extend "$REG/good-v0.1.0.tsv" "$W/publisher.tsv" "$(rec recipe $HH household publisher 4 8192 32768)"
o=$(reader "$W/publisher.tsv" "$HH")
same "$(kind "$o" build | cut -f3 | paste -sd, -):$(taken "$o")" "tier,ok:$B2" "allowed publisher: order 1 is ruled out, order 2 is taken"

# The tier is the model line's: the same build lines, Mistral's model line saying third-party
sed "3s/${T}endorsed${T}/${T}third-party${T}/" "$REG/good-v0.1.0.tsv" > "$W/model-tier.tsv"
o=$(reader "$W/model-tier.tsv" "$HH")
same "$(kind "$o" build | cut -f3,32 | tr '\t\n' ' '):$(taken "$o")" "tier third-party ok publisher :$B2" "a model line's tier decides"
same "$(sed -n 5p "$W/model-tier.tsv" | awk -F'\t' '{ print NF }')" 14 "a build line has no tier of its own (14 fields)"

# An unknown tier, on a model line and in a recipe's list
sed "3s/${T}endorsed${T}/${T}community${T}/" "$REG/good-v0.1.0.tsv" > "$W/unknown.tsv"
o=$(reader "$W/unknown.tsv")
same "$(kind "$o" passed | head -1 | cut -f2,4)" "3${T}field 9 (tier) fails its pattern" "a model line with an unknown tier is passed over"
extend "$REG/good-v0.1.0.tsv" "$W/unknown-recipe.tsv" "$(rec recipe $HH household publisher,community 4 8192 32768)"
o=$(reader "$W/unknown-recipe.tsv" "$HH")
same "$(kind "$o" passed | cut -f2,4):$(kind "$o" recipe | cut -f6)" "9${T}field 4 (tiers) fails its pattern:publisher,endorsed" \
  "a recipe line allowing an unknown tier is passed over, the earlier one stands"
done_
