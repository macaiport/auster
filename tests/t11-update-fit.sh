# T11 (D3.7, section C): a build the capability rule rejects for this Mac, or above the recipe's trust tiers, is
# never `waiting` there. With the scripts, the offer and the registry of one version: on the 36 GB Mac (27,648
# MiB, builds/mac), serving order 2, order 1 does not fit, so the recipe is the same and the word current; the
# same records on the 64 GB Mac (53,084 MiB) give order 1 waiting. Serving order 1 on the 64 GB Mac, with a
# third-party build put first by a later order line (tier.tsv; the recipe allows publisher,endorsed): same. A
# Mac whose memory no longer holds the build served (order 1 on the 36 GB Mac) moves to order 2, the next that
# fits (D3.7). The figures come from builds/mac: with none the recipe is passed over, never waiting.
# Mutants: tests/mutants/T11a (offer every build the registry lists, fit or not) and T11b (ignore the tier).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env

fresh; known v0.1.0; mac_put 27648 $GB36; served $HH $B2 4 15360
same "$(upd | cut -f1):$(rfield $HH 3)" "current:same" "the 36 GB Mac serving order 2: order 1 does not fit, same, current"
mac_put 53084 $GB64
same "$(upd | cut -f1):$(rfield $HH 3):$(rfield $HH 7)" "ready:waiting:$B1" "the same records on the 64 GB Mac: order 1 waiting"
same "$(rfield $HH 9):$(rfield $HH 10):$(rfield $HH 11):$(rfield $HH 12)" "4:32768:45136:45620" \
  "  ...for four people at 32,768 each, 45,136 MiB on the GPU and 45,620 in all (C2)"

fresh; known v0.1.0 "$REGF/tier.tsv"; mac_put 53084 $GB64; served $HH $B1 4 32768
same "$(upd | cut -f1):$(rfield $HH 3)" "current:same" "a third-party build ordered first, serving order 1: same, current"
same "$(grep -c "^order${TAB}$HH${TAB}b4cvp4l4ee5tl${TAB}$B1" "$U/registry")" 1 "  ...the registry's latest order puts the third-party build first"

fresh; known v0.1.0; mac_put 27648 $GB36; served $HH $B1 4 32768
same "$(upd | cut -f1):$(rfield $HH 3):$(rfield $HH 7):$(rfield $HH 10)" "ready:waiting:$B2:15360" \
  "the 36 GB Mac serving order 1, which no longer fits: order 2 waiting, at 15,360 each"

fresh; known v0.1.0; served $HH $B2 4 32768
same "$(upd | cut -f1):$(rfield $HH 3):$(rfield $HH 4)" "current:passed-over:figures" "no builds/mac: passed over, this Mac's figures unread, never waiting"
done_
