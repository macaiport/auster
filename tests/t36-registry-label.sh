# T36, the registry's half: renaming a recipe's label, by a later `recipe` line (A1, A3), changes nothing
# the reader finds a recipe or its builds by: the recipe is found by its id alone, and its builds and their
# lines come out byte for byte as before. That no path in the data root holds a label is U2's half of
# T36, since U2 writes the data root; a build has no label but its Mac label, which only a new build
# line can change (A3). Mutant: tests/mutants/T36a, the registry's form of "use the label as the folder
# name": key the recipe by its label.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t36.XXXXXX")
extend "$REG/good-v0.1.0.tsv" "$W/renamed.tsv" "$(rec recipe $HH family-helper publisher,endorsed 4 8192 32768)"

a=$(reader "$REG/good-v0.1.0.tsv" "$HH"); same $? 0 "before the rename: read"
b=$(reader "$W/renamed.tsv" "$HH"); same $? 0 "after the rename: read"
same "$(kind "$b" recipe)" "recipe${T}$HH${T}ok${T}0${T}family-helper${T}publisher,endorsed${T}4${T}8192${T}32768" \
  "after the rename the recipe is found by its id, with the new label"
same "$(kind "$a" recipe | cut -f5)" household "before it, the old label"
same "$(printf '%s\n' "$b" | grep -v '^recipe')" "$(printf '%s\n' "$a" | grep -v '^recipe')" \
  "its builds and their raw lines are the same, byte for byte"
same "$(reader "$W/renamed.tsv" | cut -f1,2 | grep '^recipe')" "recipe${T}$HH" "the whole registry still names one recipe, by its id"
reader "$W/renamed.tsv" family-helper > /dev/null 2>&1; same $? 2 "a label is not an id: asking by label is a usage error"
reader "$W/renamed.tsv" household > /dev/null 2>&1; same $? 2 "nor by the old one"
done_
