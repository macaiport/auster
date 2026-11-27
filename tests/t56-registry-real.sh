# T56: the repo's own registry.tsv passes the gate with the repo's own assets/, and its household lines
# equal A6: sizes, hashes, the 73-byte system prompt c44bab6b...d02e49, the templates (39f03c38...81fdcda
# for order 2; for order 1 f29aa080...e291f4, the model file's own, d579fedf...298f954, taken out by
# scripts/phase-2/gguf-template.py and kept in tests/fixtures/templates/, with its date block replaced
# (BD20)), the test, the figures, the tiers, the temperatures, the recipe and its order. One newline added
# to the system prompt turns the gate red. Order 1's template differs from the model file's own only in its
# date block, which raises nothing and names no year (scripts/phase-2/template-dates.sh renders it
# through the engine; this suite has none). Also: the lines are the capability
# fixture's (tests/fixtures/capability/household.tsv, the same ids and figures) but for the values listed
# below; assets/ holds only files a build names; the install tests' copy of the test file is the one that
# ships. Mutants: tests/mutants/T56a (the gate checks the format but not the asset hashes), T56b (it
# accepts an editor's added newline), T56c (a figure in registry.tsv that is not A6's), T56d (the date
# block raises again, as Unsloth's did).
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t56.XXXXXX")
REAL=$ROOT/registry.tsv
A=$ROOT/assets
sha() { shasum -a 256 < "$1" | cut -c1-64; }

# --- the gate, with the assets and the tag
g=$(gate "$REAL" --assets "$A" --tag v0.1.0); same "$?:$g" 0: "registry.tsv with assets/ and the tag v0.1.0: the gate passes"

# --- A6, field by field: the records but the comments, in the file's order
ENG=82b00abc740160e1b9980e6cc79c117345fa34af058c80e6c0a69aa8ddccde75
MS4=c56fdf063ad8c215c0e56c322383b3fb242189ce9047cdbb3e7dcad11380c1b8
MAG=d3a024d29e0e8f35d9353f5d4f08fc3715406835c8ae1328ce2f3bd212a43434
TPL1=f29aa0803a2d0346a20a384690cf1eb8eef71cdffd90b178751592bfa3e291f4
TPL1_OWN=d579fedfe0a78b11376089da957bbd4299ffb3f95cf827ab00c9cdc77298f954
TPL2=39f03c383413f531fd302c06c7e982ad98c83f0657a8339ae25478ccb81fdcda
SYS=c44bab6bddc7d9f48e834d2120bffeda2aa087b0bb4a2f1c74d17ab103d02e49
TST=$(sha "$A/household-test.json")
want=$(
  printf 'auster-registry\t1\tv0.1.0\n'
  rec engine ebv74racygnzm macos-arm64 b12359 llama-b12359-bin-macos-arm64.tar.gz 16907811 $ENG 14
  rec model mjhs5h65av6o4 unsloth/Mistral-Small-4-119B-2603-GGUF bd93c721735aa32c035c0f19e738cb3371fd56ff \
    Mistral-Small-4-119B-2603-UD-IQ3_S.gguf 44407639744 $MS4 apache-2.0 endorsed 1048576
  rec model maw6njwkqcc35 mistralai/Magistral-Small-2509-GGUF 429b90d8a8f0037241db6fab46a20b0f90859b03 \
    Magistral-Small-2509-Q4_K_M.gguf 14334432256 $MAG apache-2.0 publisher 40960
  rec build $B1 ebv74racygnzm mjhs5h65av6o4 $TPL1 $SYS $TST 41923 333 484 23040 0 0.95 m5-max-64gb
  rec build $B2 ebv74racygnzm maw6njwkqcc35 $TPL2 $SYS $TST 13302 665 432 163840 0.7 0.95 m5-max-64gb
  rec recipe $HH household-assistant publisher,endorsed 4 8192 32768
  rec order $HH $B1 $B2
)
same "$(grep -v '^#' "$REAL")" "$want" "the household's records equal A6, field by field, order 1 first"
same "$(grep -c . "$REAL") $(grep -c '^#' "$REAL")" "10 2" "ten lines: the version line, two comments and the seven records"

# --- the capability fixture's lines, but for the placeholder hashes, and for the fixture values its
# README names: the model files' context limits (the files' own: 1,048,576 and 40,960), the Mac label and
# the recipe label (recipes/<label>/, A1)
sed -e "s/d54dd73b805021458132f1abadff68e79dde941432f6940c32cdecdeb1190767/$TPL1/" \
    -e "s/41bb822fb2b3768364f4676059d99b4d9115cc958eafe7dac3e6a5e02747faf9/$TST/g" \
    -e "s/${T}endorsed${T}262144\$/${T}endorsed${T}1048576/" -e "s/${T}publisher${T}131072\$/${T}publisher${T}40960/" \
    -e "s/${T}dev-mac-64gb\$/${T}m5-max-64gb/" -e "s/^recipe${T}$HH${T}household${T}/recipe${T}$HH${T}household-assistant${T}/" \
    "$TESTS/fixtures/capability/household.tsv" > "$W/fixture-real.tsv"
same "$(cat "$W/fixture-real.tsv")" "$(grep -v '^#' "$REAL")" "the capability fixture's lines but for the placeholders and the fixture values: the same ids and figures"

# --- the assets: each by its hash, the system prompt as A6 gives it, and nothing a build does not name
same "$(wc -c < "$A/household-system.txt" | tr -d ' ') $(sha "$A/household-system.txt")" "73 $SYS" "the system prompt: 73 bytes, c44bab6b...d02e49"
printf 'You are the household assistant for a family. Answer briefly and plainly.' > "$W/sentence"
cmp -s "$W/sentence" "$A/household-system.txt" && ok "the system prompt is A6's sentence, with no newline" || bad "the system prompt is not A6's sentence"
same "$(sha "$A/mistralai-Ministral-3-14B-Reasoning-2512.jinja")" $TPL2 "order 2's template, by its name: 39f03c38...81fdcda"
P1=$A/unsloth-Mistral-Small-4-119B-2603-dates-fixed.jinja
O1=$TESTS/fixtures/templates/unsloth-Mistral-Small-4-119B-2603.jinja
same "$(sha "$P1") $(wc -c < "$P1" | tr -d ' ')" "$TPL1 9732" "order 1's template, by its name: f29aa080...e291f4, 9,732 bytes"
same "$(sha "$O1") $(wc -c < "$O1" | tr -d ' ')" "$TPL1_OWN 14121" "the model file's own template, kept as a fixture: d579fedf...298f954, 14,121 bytes"
same "$(head -n 1 "$P1")" "$(head -n 1 "$O1")" "order 1's template: its first line is the model file's own"
tail -n +39 "$P1" > "$W/p1-rest"; tail -n +144 "$O1" > "$W/o1-rest"
cmp -s "$W/p1-rest" "$W/o1-rest" && ok "order 1's template: everything after its date block is the model file's own, byte for byte" \
  || bad "order 1's template differs from the model file's own outside its date block"
sed -n '2,38p' "$P1" > "$W/p1-block"
same "$(head -n 1 "$W/p1-block" | cut -c1-14) $(tail -n 1 "$W/p1-block" | cut -c1-27)" "{#- Auster: th {%- set yesterday_date = (y" \
  "order 1's template: lines 2 to 38 are Auster's date block"
same "$(grep -c -e raise_exception -e "'20[0-9][0-9]'" -e "'19[0-9][0-9]'" "$W/p1-block")" 0 \
  "the date block raises nothing and names no year"
named=$(grep '^build' "$REAL" | cut -f5-7 | tr '\t' '\n' | sort -u)
n=0
for f in "$A"/*; do
  n=$((n + 1))
  printf '%s\n' "$named" | grep -qx "$(sha "$f")" || bad "assets/${f##*/} is named by no build"
done
same "$n $(printf '%s\n' "$named" | wc -l | tr -d ' ')" "4 4" "assets/ holds the four files the builds name, and no other"
cmp -s "$A/household-test.json" "$TESTS/fixtures/recipe-test/household-test.json" \
  && ok "the install tests' copy of the test file is assets/household-test.json, byte for byte" \
  || bad "tests/fixtures/recipe-test/household-test.json differs from assets/household-test.json"

# --- one newline added to the system prompt: the gate fails, naming both builds
cp -R "$A" "$W/nl"; printf '\n' >> "$W/nl/household-system.txt"
g=$(gate "$REAL" --assets "$W/nl")
same "$?:$g" "1:build $B1: its system-prompt $SYS is not in $W/nl
build $B2: its system-prompt $SYS is not in $W/nl" "an editor's newline added to the system prompt: the gate fails, naming both builds"
cp -R "$A" "$W/crlf"; printf '\r\n' >> "$W/crlf/household-system.txt"
g=$(gate "$REAL" --assets "$W/crlf"); same "$?" 1 "a CR LF added instead: the gate fails"
done_
