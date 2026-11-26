# T54, the gate's half: a template, system prompt or test that a build names by sha256, missing from
# assets/ or differing by one byte: the gate fails. Renaming those files changes nothing (A4, D3.9). That
# a Mac's install stops at step 8 before any job exists is V5's and U2's half. Mutants: tests/mutants/T54a
# and T54b.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t54.XXXXXX")
A=$W/assets
mkdir -p "$A"
printf '{{ messages }} for order 1\n' > "$A/order-1.jinja"
printf '{{ messages }} for order 2\n' > "$A/order-2.jinja"
printf 'You are the household assistant for a family. Answer briefly and plainly.\n' > "$A/household-system.txt"
printf '{"questions": []}\n' > "$A/household-test.json"
sha() { shasum -a 256 < "$1" | cut -c1-64; }
t1=$(sha "$A/order-1.jinja") t2=$(sha "$A/order-2.jinja") sp=$(sha "$A/household-system.txt") ts=$(sha "$A/household-test.json")
sed -e "s/d54dd73b805021458132f1abadff68e79dde941432f6940c32cdecdeb1190767/$t1/" \
    -e "s/39f03c383413f531fd302c06c7e982ad98c83f0657a8339ae25478ccb81fdcda/$t2/" \
    -e "s/c44bab6bddc7d9f48e834d2120bffeda2aa087b0bb4a2f1c74d17ab103d02e49/$sp/g" \
    -e "s/41bb822fb2b3768364f4676059d99b4d9115cc958eafe7dac3e6a5e02747faf9/$ts/g" "$REG/good-v0.1.0.tsv" > "$W/reg.tsv"

g=$(gate "$W/reg.tsv" --assets "$A"); same "$?:$g" 0: "every asset present: the gate passes"
g=$(gate "$REG/good-v0.1.0.tsv"); same "$?:$g" 0: "without --assets, assets are not asked about"
mkdir "$W/renamed"
i=0; for f in "$A"/*; do i=$((i + 1)); cp "$f" "$W/renamed/file-$i"; done
g=$(gate "$W/reg.tsv" --assets "$W/renamed"); same "$?:$g" 0: "every asset renamed: the gate still passes"

cp -R "$A" "$W/missing"; rm "$W/missing/order-2.jinja"
g=$(gate "$W/reg.tsv" --assets "$W/missing")
same "$?:$g" "1:build $B2: its template $t2 is not in $W/missing" "order 2's template missing: the gate fails, naming it"
cp -R "$A" "$W/notest"; rm "$W/notest/household-test.json"
g=$(gate "$W/reg.tsv" --assets "$W/notest")
same "$?:$g" "1:build $B1: its test $ts is not in $W/notest
build $B2: its test $ts is not in $W/notest" "the test missing: the gate fails, naming both builds"
cp -R "$A" "$W/byte"; printf '\n' >> "$W/byte/household-system.txt"
g=$(gate "$W/reg.tsv" --assets "$W/byte")
same "$?:$g" "1:build $B1: its system-prompt $sp is not in $W/byte
build $B2: its system-prompt $sp is not in $W/byte" "the system prompt one byte longer: the gate fails"
cp -R "$A" "$W/flip"; printf '{{ messages }} for order 3\n' > "$W/flip/order-1.jinja"
g=$(gate "$W/reg.tsv" --assets "$W/flip")
same "$?:$g" "1:build $B1: its template $t1 is not in $W/flip" "order 1's template one byte different, same size: the gate fails"
mkdir "$W/linked"; for f in "$A"/*; do ln -s "$f" "$W/linked/${f##*/}"; done
g=$(gate "$W/reg.tsv" --assets "$W/linked"); same "$?" 1 "assets that are links are not taken"
gate "$W/reg.tsv" --assets "$W/nothing-here" > /dev/null 2>&1; same $? 2 "an assets folder that does not exist: usage"
done_
