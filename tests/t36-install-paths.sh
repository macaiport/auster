# T36, the data root's half (U2; A1, A2, D3.1): renaming a recipe's label, by a later `recipe` line, and the Mac label
# of its builds changes no path in the data root. Two first installs from registries that differ only in those
# labels make the same paths, every one of them; a device's key, minted at random, is named by its id and is matched
# as an id; and no path holds a label. Mutant: tests/mutants/T36b (use the label as the folder name; T36a is the
# registry's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
paths() { (cd "$DATA" && find . -print) | sed -E 's/k[a-z2-7]{12}/<key id>/g' | LC_ALL=C sort; }

install_env
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the first install, with the label household: exit 0"
paths > "$TMPDIR/t36-paths-1"
launchctl bootout "gui/$(id -u)/local.auster.engine"
for i in $(seq 100); do [ -f "$STUB_ENGINE_DIR/ports/8484" ] || break; sleep 0.1; done
rm -rf "$DATA"   # the same home, engine archive and stand-ins: only the labels differ

install_registry "$W/r.tsv"
T=$'\t'
sed -e "s/^recipe${T}$IR${T}household${T}/recipe${T}$IR${T}family-helper${T}/" -e "s/${T}dev-mac-64gb\$/${T}other-mac/" "$W/r.tsv" > "$FX/registry.tsv"
grep -q "family-helper" "$FX/registry.tsv" && [ "$(grep -c 'other-mac$' "$FX/registry.tsv")" = 2 ] && ok "the second registry: other labels" || bad "the second registry"
install_tree "$FX/registry.tsv"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the second install, with the label family-helper: exit 0"
says "ready to install family-helper" "it says the new label"
paths > "$TMPDIR/t36-paths-2"
same "$(diff "$TMPDIR/t36-paths-1" "$TMPDIR/t36-paths-2")" "" "the two data roots hold the same paths"
same "$(grep -c . "$TMPDIR/t36-paths-2" | awk '{ print ($1 > 20) }')" 1 "  ...of which there are many"
same "$(grep -E 'household|family-helper|dev-mac|other-mac' "$TMPDIR/t36-paths-1" "$TMPDIR/t36-paths-2")" "" "no path holds a label"
same "$(grep -c "^\./builds/$IR\$" "$TMPDIR/t36-paths-2")" 1 "the recipe's folder is named by its id"
done_
