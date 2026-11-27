# T48: the gate fails a registry with an id defined twice, a line of 1,001 bytes, a file of 512 KiB plus
# one byte, a line with a field too few or too many, and a build, order or withdraw naming an undefined
# id, and names each; on a Mac each such line is passed over and the others are used, except that a field
# too many is kept and not read, and a file over 512 KiB is not read at all (A3, D3.9). Also D3.9's
# --tag and --release questions, which U9's release gate (T39) asks through tools/check-registry, and a
# recipe line with no people or a minimum context over its maximum (A3, settled at V2), which a Mac passes
# over and the gate fails. Mutants: tests/mutants/T48a to T48c (the plan's), T48d and T48e (the --tag and
# --release questions), T48f and T48g (the recipe line's two rules).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t48.XXXXXX")
has() { # OUTPUT LINE WHAT -> ok when OUTPUT holds LINE exactly
  if printf '%s\n' "$1" | grep -qxF -- "$2"; then ok "$3"; else bad "$3: no line [$2] in [$1]"; fi
}

# --- an id defined twice
g=$(gate "$REG/dup-ids.tsv"); same $? 1 "dup-ids: the gate fails"
has "$g" "line 9: maw6njwkqcc35 defined twice (first on line 4)" "dup-ids: the gate names the model defined twice"
has "$g" "line 10: $B1 defined twice (first on line 5)" "dup-ids: and the build"
o=$(reader "$REG/dup-ids.tsv" "$HH"); same $? 0 "dup-ids: a Mac reads it"
same "$(passed_lines "$o")" 9,10 "dup-ids: a Mac passes over the two second definitions"
same "$(kind "$o" build | cut -f5,11 | tr '\t\n' ' ')" "$B1 41923 $B2 13302 " "dup-ids: order 1's figures are the first line's"
same "$(kind "$o" build | awk -F'\t' '$5 == "'$B2'" { print $29 }')" 14334432256 "dup-ids: Magistral's size is the first line's"
extend "$REG/good-v0.1.0.tsv" "$W/cross.tsv" "$(sed -n 2p "$REG/good-v0.1.0.tsv" | sed "s/ebv74racygnzm/$B2/")"
g=$(gate "$W/cross.tsv"); same $? 1 "an engine line with a build's id: the gate fails"
has "$g" "line 9: $B2 defined twice (first on line 6)" "the gate names an id defined by lines of two kinds"
has "$g" "line 9: field 2 (id) fails its pattern" "and the engine id's pattern"

# --- lines of 1,000 and 1,001 bytes
g=$(gate "$REG/line-1000.tsv"); same "$?:$g" 0: "a line of 1,000 bytes passes the gate"
g=$(gate "$REG/line-1001.tsv"); same "$?:$g" "1:line 9: over 1000 bytes" "a line of 1,001 bytes: the gate fails and names it"
a=$(reader "$REG/line-1000.tsv" "$HH"); b=$(reader "$REG/line-1001.tsv" "$HH")
same "$(passed_lines "$(reader "$REG/line-1001.tsv")")" 9 "a Mac passes over the line of 1,001 bytes"
same "$(printf '%s\n' "$b" | grep -v '^passed')" "$a" "and reads the rest as it reads line-1000.tsv"
long=$(printf '%0970d' 0 | tr 0 x)
extend "$REG/good-v0.1.0.tsv" "$W/long-order.tsv" "$(rec order $HH $B2 $B1)${T}$long"
o=$(reader "$W/long-order.tsv" "$HH")
same "$(passed_lines "$o"):$(taken "$o")" "9:$B1" "an order line over 1,000 bytes is passed over, the earlier order stands"

# --- 512 KiB and one byte more
registry_sized "$REG/good-v0.1.0.tsv" 524288 "$W/512k.tsv"
registry_sized "$REG/good-v0.1.0.tsv" 524289 "$W/512k1.tsv"
g=$(gate "$W/512k.tsv"); same "$?:$g" 0: "a registry of 512 KiB passes the gate"
o=$(reader "$W/512k.tsv" "$HH"); same "$?:$(state "$o")" 0:ok "a Mac reads a registry of 512 KiB"
g=$(gate "$W/512k1.tsv"); same "$?:$g" "1:the registry is over 512 KiB (524,288 bytes), so no Mac reads it" \
  "512 KiB and one byte: the gate fails and names it"
o=$(reader "$W/512k1.tsv" "$HH"); same $? 3 "512 KiB and one byte: a Mac does not read it (exit 3)"
same "$o" "unread${T}too-large
recipe${T}$HH${T}unreadable${T}0${T}-${T}-${T}-${T}-${T}-" "and the recipe cannot be read"
same "$(printf '%s\n' "$o" | wc -l | tr -d ' ')" 2 "and nothing else is printed"

# --- a field too few, a field too many
g=$(gate "$REG/field-count.tsv"); same $? 1 "field-count: the gate fails"
has "$g" "line 9: too few fields (6 of 7)" "the gate names the recipe line with a field too few"
has "$g" "line 10: too many fields (4 of 3)" "and the withdraw line with a field too many"
o=$(reader "$REG/field-count.tsv" "$HH")
same "$(passed_lines "$o")" 9 "a Mac passes over the line with a field too few, and only it"
same "$(kind "$o" recipe | cut -f5,7)" "household${T}4" "the recipe keeps its first line"
same "$(kind "$o" build | cut -f2-5 | head -1)" "1${T}withdrawn${T}security${T}$B1" \
  "the withdraw line with a field too many is kept: order 1 is withdrawn, for security"
same "$(taken "$o")" "$B2" "so order 2 is taken"
extend "$REG/good-v0.1.0.tsv" "$W/order65.tsv" "$(rec order $HH $(for i in $(seq 32); do printf '%s %s ' $B2 $B1; done) $B2)"
g=$(gate "$W/order65.tsv"); has "$g" "line 9: too many fields (67 of at most 66)" "an order of 65 builds: the gate fails it"

# --- a recipe line with no people, or a minimum context over its maximum (A3, settled at V2)
extend "$REG/good-v0.1.0.tsv" "$W/recipe-rules.tsv" "$(rec recipe $HH family-helper publisher 0 8192 16384)" \
  "$(rec recipe $HH family-helper publisher 2 16385 16384)"
g=$(gate "$W/recipe-rules.tsv"); same $? 1 "recipe lines with no people, or a minimum over the maximum: the gate fails"
has "$g" "line 9: field 5 (people) is 0: a recipe has at least one person" "the gate names the recipe line with no people"
has "$g" "line 10: field 6 (contextMin) is over field 7 (contextMax)" "and the one whose minimum context is over its maximum"
o=$(reader "$W/recipe-rules.tsv" "$HH")
same "$(passed_lines "$o")" 9,10 "a Mac passes both over"
same "$(kind "$o" recipe | cut -f5-9 | tr '\t' ' ')" "household publisher,endorsed 4 8192 32768" "the recipe keeps its first line"

# --- a build, order or withdraw naming an id no line defines
g=$(gate "$REG/withdraw-unknown.tsv"); same $? 1 "withdraw-unknown: the gate fails"
has "$g" "line 9: names build bqcj2a3zgsijq, which no line defines" "the gate names a withdrawal of an undefined build"
has "$g" "line 10: field 2 (build) fails its pattern" "and one naming a model's id"
o=$(reader "$REG/withdraw-unknown.tsv" "$HH")
same "$(passed_lines "$(reader "$REG/withdraw-unknown.tsv")"):$(kind "$o" build | cut -f3 | paste -sd, -)" "9,10:ok,ok" "a Mac passes both over and withdraws nothing"
bline=$(sed -n 6p "$REG/good-v0.1.0.tsv" | sed "s/^build${T}$B2${T}ebv74racygnzm/build${T}by5tj7eyogjys${T}ewiqx4pcoartv/")
extend "$REG/good-v0.1.0.tsv" "$W/undef.tsv" "$bline" "$(rec order $HH by5tj7eyogjys $B1)" "$(rec order $HH bicef73fxu6v2 $B2)"
g=$(gate "$W/undef.tsv"); same $? 1 "builds and orders naming undefined ids: the gate fails"
has "$g" "line 9: names engine ewiqx4pcoartv, which no line defines" "the gate names a build naming an undefined engine"
has "$g" "line 10: names build by5tj7eyogjys, whose line was passed over" "an order naming that build"
has "$g" "line 11: names build bicef73fxu6v2, which no line defines" "and an order naming an undefined build"
o=$(reader "$W/undef.tsv" "$HH")
same "$(passed_lines "$o"):$(kind "$o" build | cut -f5 | paste -sd, -)" "9,10,11:$B1,$B2" "a Mac passes the three over and keeps the first order"
extend "$REG/good-v0.1.0.tsv" "$W/norecipe.tsv" "$(rec order rsvh4l2c3prht $B2)"
g=$(gate "$W/norecipe.tsv"); has "$g" "line 9: names recipe rsvh4l2c3prht, which no recipe line defines" "an order for a recipe no line defines"

# --- D3.9's other registry questions: a build in two recipes' orders, named twice, withdrawn twice
extend "$REG/good-v0.1.0.tsv" "$W/two.tsv" "$(rec recipe rsvh4l2c3prht fit-test publisher 1 4096 8192)" "$(rec order rsvh4l2c3prht $B2 $B2)" \
  "$(rec withdraw $B1 superseded)" "$(rec withdraw $B1 security)"
g=$(gate "$W/two.tsv")
has "$g" "line 10: names build $B2 twice" "the gate names an order naming a build twice"
has "$g" "line 10: build $B2 is already in the order of recipe $HH (line 8)" "and a build in two recipes' orders"
has "$g" "line 12: build $B1 already withdrawn on line 11" "and a build withdrawn twice"
o=$(reader "$W/two.tsv" "$HH"); same "$(kind "$o" build | head -1 | cut -f4)" superseded "a Mac keeps the first withdrawal"

# --- --tag and --release
g=$(gate "$REG/good-v0.2.0.tsv" --tag v0.2.0 --release "$REG/good-v0.1.0.tsv"); same "$?:$g" 0: "v0.2.0 against v0.1.0, tag v0.2.0: passes"
g=$(gate "$REG/good-v0.2.0.tsv" --tag v0.2.1); same "$?:$g" "1:line 1: the version v0.2.0 is not the tag v0.2.1" "a tag that is not the version line: fails"
g=$(gate "$REG/good-v0.2.0.tsv" --tag 0.2.0); same "$?:$g" "1:the tag is not of the form vX.Y.Z" "a tag not of the form vX.Y.Z: fails"
sed '5s/41923/41924/' "$REG/good-v0.2.0.tsv" > "$W/changed.tsv"
g=$(gate "$W/changed.tsv" --release "$REG/good-v0.1.0.tsv"); same "$?:$g" "1:line 5 of the release (build $B1) is missing, changed or moved" \
  "a released fact line changed: fails, naming it"
sed '8d' "$REG/good-v0.2.0.tsv" > "$W/dropped.tsv"
g=$(gate "$W/dropped.tsv" --release "$REG/good-v0.1.0.tsv")
has "$g" "line 8 of the release (order $HH) is missing, changed or moved" "a released judgement line removed: fails, naming it"
{ head -7 "$REG/good-v0.1.0.tsv"; rec order $HH $B2 $B1; tail -1 "$REG/good-v0.1.0.tsv"; } | sed '1s/v0.1.0/v0.1.1/' > "$W/above.tsv"
g=$(gate "$W/above.tsv" --release "$REG/good-v0.1.0.tsv")
same "$?:$g" "1:line 8: a new order line above the release's line 9 for the same recipe" "a new judgement above the released one: fails"
g=$(gate "$REG/good-v0.1.0.tsv" --release "$REG/good-v0.1.0.tsv")
same "$?:$g" "1:line 1: the version v0.1.0 is not newer than the release's v0.1.0" "the same version as the release: fails"
{ cat "$REG/good-v0.1.0.tsv"; printf '# a comment added\n'; } | sed '1s/v0.1.0/v0.1.1/' > "$W/comment.tsv"
g=$(gate "$W/comment.tsv" --release "$REG/good-v0.1.0.tsv"); same "$?:$g" 0: "a comment added, the version raised: passes"
g=$(gate "$REG/good-v0.2.0.tsv" --release "$W/nothing-here.tsv")
same "$?:$g" "1:the release's registry cannot be read (missing, a link, or not a regular file)" "a release registry that cannot be read: fails"

gate > /dev/null 2>&1; same $? 2 "the gate with no registry: usage"
gate "$REG/good-v0.1.0.tsv" --frob > /dev/null 2>&1; same $? 2 "an unknown option: usage"
reader > /dev/null 2>&1; same $? 2 "the reader with no registry: usage"
reader "$REG/good-v0.1.0.tsv" "$HH" extra > /dev/null 2>&1; same $? 2 "the reader with three arguments: usage"
reader "$REG/good-v0.1.0.tsv" 'r$(touch f)' > /dev/null 2>&1; same $? 2 "a recipe id that fails its pattern: usage"
o=$(reader "$W/nothing-here.tsv" "$HH"); same "$?:$o" "3:unread${T}unreadable
recipe${T}$HH${T}unreadable${T}0${T}-${T}-${T}-${T}-${T}-" "a missing registry: not read"
ln -s "$REG/good-v0.1.0.tsv" "$W/link.tsv"
o=$(reader "$W/link.tsv"); same "$?:$o" "3:unread${T}unreadable" "a registry that is a link: not read (D3.1)"
done_
