# T91, the update's half (U4; D3.6 step 2, C4): an update keeps the household's number of people, and a change of build
# or of context is named in the question in figures. Serving order 2 for two people, order 1 waiting: the question
# names both builds and their model files, two people at 32,768 tokens each before and after, what order 1 would hold
# (43.1 GB of 64.0 GB, 42.7 GB on the GPU), that the number of people is kept, and the download of 3,400 bytes. The
# sizes come from the tree's registry: an _update/registry that says otherwise changes nothing. Serving order 1 at
# 16,384 where 32,768 fits: the question names a change of setting on the same build, from 16,384 to 32,768, with no
# download, and a restart only. A release whose own programs differ: the question says they change; and with no recipe
# to change, the programs alone are asked about, and a no changes nothing (what a yes does is T94's, U5).
# Mutants: tests/mutants/T91b (reset people to the recipe's default), T91c (take the figures from _update/registry),
# T91d (never say that Auster's programs change), and T91a (section C's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
serving_put "$IB2" "$IMB" 2 32768 36.9
awk -F'\t' -v OFS='\t' '$1 == "model" && $6 == 3400 { $6 = 9999 } { print }' "$FX/registry.tsv" > "$DATA/_update/registry"   # another size
update_run $'no\n'
same "$RC" 1 "two people, order 1 waiting, answered no: exit 1"
says "  Now         build $IB2 (standin-b.gguf), 2 people at a time, each with a context of 32,768 tokens." "the question: the build served, at two people"
says "  After       build $IB1 (standin-a.gguf), 2 people at a time, each with a context of 32,768 tokens," "  ...order 1, at two people"
says "holding 43.1 GB of this Mac's 64.0 GB of memory, 42.7 GB of it on the GPU." "  ...what order 1 would hold, in figures"
says "  People      The household's number of people, 2, is kept." "  ...the number of people kept"
says "  Download    3,400 bytes: standin-a.gguf from Hugging Face ($REPO_A)." "  ...the download, by the tree's registry, not _update's"
grep -q 'Programs' "$W/out" && bad "  ...it says the programs change" || ok "  ...and no change of Auster's programs"

cp "$W/pristine/store/$SA" "$DATA/store/$SA"
serving_put "$IB1" "$IMA" 4 16384 36.9
update_run $'no\n'
same "$RC" 1 "order 1 at 16,384 where 32,768 fits, answered no: exit 1"
says "The recipe household: its setting would change, on the build it serves." "the question: a change of setting"
says "  Now         build $IB1 (standin-a.gguf), 4 people at a time, each with a context of 16,384 tokens." "  ...from 16,384"
says "  After       the same build, 4 people at a time, each with a context of 32,768 tokens," "  ...to 32,768"
says "  Download    Nothing: it is the build this Mac serves" "  ...nothing to download"
says "the server restarts once on the new setting" "  ...a restart only"

serving_put "$IB2" "$IMB" 4 32768 36.9
release_at v0.2.0 "$COMMIT2"
printf '# a change in v0.2.0\n' >> "$FX/tree-src-$COMMIT2/common/auster"
tree_archive "$FX/tree-src-$COMMIT2" "auster-$COMMIT2" "$COMMIT2" "$FX/tree-$COMMIT2.tar.gz"
update_run $'no\n'
same "$RC" 1 "a release whose programs differ, order 1 waiting, answered no: exit 1"
says "  Programs    Auster's own programs change too (from v0.1.0 to v0.2.0)" "  ...the question says Auster's programs change"
cp "$W/pristine/builds/$IR/serving" "$DATA/builds/$IR/serving"
before=$(data_snap)
update_run $'no\n'
same "$RC" 1 "the programs alone change, answered no: exit 1"
says "Auster's own programs change (from v0.1.0 to v0.2.0), and no recipe on this Mac changes." "  ...the question is about the programs"
says "The recipe household: OK." "  ...after the recipe's OK"
same "$(data_snap)" "$before" "  ...and the no changed nothing: no program, no stamp"
done_
