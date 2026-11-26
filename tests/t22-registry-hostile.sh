# T22: a registry line with ../, a leading -, $(...), a non-hex sha256 or letters in a size is passed
# over, the other lines are used, and no file is made by it (plan A3, D3.3). Mutant: tests/mutants/T22a.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t22.XXXXXX")
cd "$W" || exit 1

# hostile.tsv: lines 9 to 13 are a repository ../mistralai, a file -rf.gguf, a file $(touch f).gguf, a
# sha256 holding z and a size 17e6, on model and engine lines nothing names
out=$(reader "$REG/hostile.tsv"); same $? 0 "hostile.tsv is read"
same "$(passed_lines "$out")" 9,10,11,12,13 "the five hostile lines are passed over, and only they"
same "$(kind "$out" passed | cut -f4 | paste -sd'|' -)" \
  "field 3 (repository) fails its pattern|field 5 (file) fails its pattern|field 5 (file) fails its pattern|field 7 (sha256) fails its pattern|field 6 (size) fails its pattern" \
  "each is passed over for the field that holds it"
same "$(state "$out")" ok "the recipe is still used"
out=$(reader "$REG/hostile.tsv" "$HH")
same "$(kind "$out" build | cut -f2,3,5 | tr '\t\n' ' ')" "1 ok $B1 2 ok $B2 " "both of its builds are offered"

# More of the same, on a line a build names: the build line and the order line that name what was
# passed over go with it (A3), so the recipe cannot be read
for v in '-rf/mistralai' 'mistralai/-rf' 'a/..' '../b' 'a/b/../c' '$(touch f)/x'; do
  sed "4s|mistralai/Magistral-Small-2509-GGUF|$v|" "$REG/good-v0.1.0.tsv" > "$W/repo.tsv"
  o=$(reader "$W/repo.tsv" "$HH")
  same "$(own_passed "$o") $(passed_lines "$o")" "4 4,6,8" "repository $v: its model line is passed over, and the lines naming it"
  same "$(state "$o") $(kind "$o" build | wc -l | tr -d ' ')" "unreadable 0" "repository $v: the recipe cannot be read"
done
sed "6s|^build${T}$B2${T}ebv74racygnzm|build${T}$B2${T}-ebv74racygnz|" "$REG/good-v0.1.0.tsv" > "$W/dash.tsv"
o=$(reader "$W/dash.tsv"); same "$(own_passed "$o")" 6 "a build naming an engine id with a leading - is passed over"
sed "6s|${T}0.7${T}|${T}\$(touch f)${T}|" "$REG/good-v0.1.0.tsv" > "$W/subst.tsv"
o=$(reader "$W/subst.tsv"); same "$(own_passed "$o")" 6 "a build with \$(touch f) for its temperature is passed over"
sed "4s|${T}14334432256${T}|${T}14e9${T}|" "$REG/good-v0.1.0.tsv" > "$W/size.tsv"
o=$(reader "$W/size.tsv"); same "$(own_passed "$o")" 4 "letters in a size used by a build: passed over"

# The gate fails the same lines, and neither prints what they hold
g=$(gate "$REG/hostile.tsv"); same $? 1 "the gate fails hostile.tsv"
same "$(printf '%s\n' "$g" | cut -d: -f1 | paste -sd, -)" "line 9,line 10,line 11,line 12,line 13" "the gate names the five lines"
all="$out$g$(reader "$REG/hostile.tsv")"
same "$(printf '%s\n' "$all" | grep -c -e '\.\./' -e '-rf' -e 'touch' -e '17e6' -e 'zz594')" 0 "no hostile value is printed"

# Nothing was made by any of it
for d in "$W" "$REG" "$ROOT" "$HOME"; do
  [ -e "$d/f" ] && bad "a file f exists in $d" || ok "no file f in ${d##*/}"
done
done_
