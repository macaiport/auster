# T44 after an update (U4; D3.3, D3.6): an update that moves the stamp to a newer version refreshes _update's registry,
# notes and offer from its tree, so that each recipe's line is judged at once and not `unknown` until the next check. A
# check has left the offer, the registry and the notes of v0.1.0; release now holds v0.2.0, and nothing changes for the
# recipe: the update writes the stamp of v0.2.0, the tree's registry and changelog, and the offer v0.2.0; the rule file
# then says current, the recipe the same, and `auster status` says so. An offer of a later version than the tree's is
# never lowered, and the registry is then left as it was. A no to a waiting build deploys nothing and writes no stamp; the
# run that then completes deploys the tree's updates.sh with the stamp. U9: a tree whose CHANGELOG.md names no version
# (the repo's own until a release's commit) moves the stamp and refreshes nothing in _update.
# Mutants: tests/mutants/T44c (no refresh of _update's registry after the update), T44d (a refresh whatever the
# changelog names).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
U="$DATA/_update"
cp "$FX/registry.tsv" "$U/registry"; printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
printf '# Changelog\n\n## v0.1.0 (2026-11-27)\n\nFirst.\n' > "$U/notes.md"
release_at v0.2.0 "$COMMIT2"
update_run ''
same "$RC" 0 "release at v0.2.0, nothing to change for the recipe: exit 0"
says "The recipe household: OK." "  ...the recipe OK"
same "$(cut -f2,3,4 "$U/scripts")" "release	v0.2.0	$COMMIT2" "  ...the stamp of v0.2.0"
cmp -s "$U/registry" "$FX/tree-src-$COMMIT2/registry.tsv" && ok "  ..._update/registry is the tree's" || bad "  ..._update/registry: $(head -n 1 "$U/registry")"
cmp -s "$U/notes.md" "$FX/tree-src-$COMMIT2/CHANGELOG.md" && ok "  ..._update/notes.md the tree's changelog" || bad "  ...notes.md"
same "$(cut -f1,2 "$U/offer")" "auster-record 1	v0.2.0" "  ...and the offer v0.2.0"
out=$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" --recipes)
same "$(printf '%s\n' "$out" | head -n 1 | cut -f1-3)" "current	v0.2.0	v0.2.0" "the rule file after the update: current"
same "$(printf '%s\n' "$out" | awk -F'\t' '$1 == "recipe" { print $3 }')" same "  ...and the recipe the same, not unknown"
auster status
outsays "Auster v0.2.0 is the newest version at the last update check." "auster status: the newest version"
outsays "The recipe household: the same, serving build $IB1" "  ...and the recipe the same"

# an offer of a later version is never lowered
printf 'auster-record 1\tv0.3.0\t1799990000\n' > "$U/offer"
cp "$FX/registry.tsv" "$U/registry"
release_at v0.2.1 0d1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
update_run ''
same "$RC:$(cut -f3 "$U/scripts")" "0:v0.2.1" "an update to v0.2.1 with v0.3.0 on offer: exit 0, the stamp v0.2.1"
same "$(cut -f2 "$U/offer")" v0.3.0 "  ...the offer of v0.3.0 not lowered"
cmp -s "$U/registry" "$FX/registry.tsv" && ok "  ...and the registry left as it was" || bad "  ...the registry was written"

# a no deploys nothing; the run that completes deploys the tree's updates.sh with the stamp
release_at v0.2.2 0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
printf '# a change in v0.2.2\n' >> "$FX/tree-src-0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d/common/updates.sh"
tree_archive "$FX/tree-src-0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d" auster-0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d \
  0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d "$FX/tree-0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d.tar.gz"
serving_put "$IB2" "$IMB" 4 32768 36.9
u0=$(shasum -a 256 < "$U/updates.sh"); s0=$(cat "$U/scripts")
update_run $'no\n'
same "$RC" 1 "a build waiting, answered no: exit 1"
same "$(shasum -a 256 < "$U/updates.sh"):$(cat "$U/scripts")" "$u0:$s0" "  ...updates.sh and the stamp as they were"
cp "$W/pristine/builds/$IR/serving" "$DATA/builds/$IR/serving"
update_run ''
same "$RC:$(cut -f3 "$U/scripts")" "0:v0.2.2" "the run that completes: exit 0, the stamp v0.2.2"
cmp -s "$U/updates.sh" "$FX/tree-src-0e1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d/common/updates.sh" && ok "  ...with the tree's updates.sh deployed" || bad "  ...updates.sh not the tree's"

# U9: a tree whose changelog names no version, as the repo's own does until a release's commit turns Unreleased into
# its heading: the stamp moves, and _update's registry, notes and offer are left as they were, for the next check
C4=0f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
release_at v0.2.3 "$C4"
printf '# Changelog\n\n## Unreleased\n\n**Next.** Soon.\n' > "$FX/tree-src-$C4/CHANGELOG.md"
tree_archive "$FX/tree-src-$C4" "auster-$C4" "$C4" "$FX/tree-$C4.tar.gz"
printf 'auster-record 1\tv0.2.2\t1799990000\n' > "$U/offer"; cp "$FX/registry.tsv" "$U/registry"; printf '# the notes before\n' > "$U/notes.md"
update_run ''
same "$RC:$(cut -f3 "$U/scripts")" "0:v0.2.3" "a tree whose changelog names no version: exit 0, the stamp v0.2.3"
same "$(cut -f2,3 "$U/offer")" "v0.2.2	1799990000" "  ...the offer as it was"
cmp -s "$U/registry" "$FX/registry.tsv" && ok "  ...the registry as it was" || bad "  ..._update/registry was written: $(head -n 1 "$U/registry")"
same "$(cat "$U/notes.md")" "# the notes before" "  ...and notes.md as it was"
done_
