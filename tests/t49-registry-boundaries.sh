# T49: for every pattern of A3, one value just inside and one just outside: only the outside value's line
# is passed over, and its recipe shows `passed over (cannot be read)`. Numbers with a leading zero, and
# 08, are outside. A bounded range is tested at both ends where it has two. The recipe line's two rules
# (A3, settled at V2) too: 1 person inside, 0 outside; a minimum context equal to the maximum inside, one
# over it outside. The files and what each tests: tests/fixtures/registry/boundary/MANIFEST, which names
# the lines that fail a pattern or a rule themselves; the lines that name what they define are passed
# over after them (A3). The first line's own fields (format, version) are here too. Mutants:
# tests/mutants/T49a to T49c (the plan's), T49d to T49h (ranges widened at the end T49a does not test).
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t49.XXXXXX")
B=$REG/boundary
R=r2z7a2z7a2z7a      # the boundary files' recipe
files=$(tail -n +2 "$B/MANIFEST" | cut -f1)
paths=$(for f in $files; do printf "%s " "$B/$f"; done)
out=$(each "$R" $paths)        # the recipe's view
whole=$(each - $paths)         # every line passed over, whatever it belongs to

tail -n +2 "$B/MANIFEST" | while IFS=$'\t' read -r f with lines what; do
  s=$(section "$out" "$B/$f")
  [ "$lines" = - ] && lines=
  same "$(own_passed "$(section "$whole" "$B/$f")")" "$lines" "$f: passed over for its own value: ${lines:-nothing} ($what)"
  st=$(state "$s")
  case "$f" in
    in-upper.tsv|in-lower.tsv|out-reason-*) same "$st $(taken "$s")" "ok b7a2z7a2z7a2z" "$f: the recipe is read and takes its build" ;;
    in-withdraw.tsv) same "$st $(kind "$s" build | cut -f3,4 | tr '\t' ' ')" "none withdrawn other" \
      "$f: the build is withdrawn, its reason not one A3 lists" ;;
    out-recipe-id-*) same "$st" absent "$f: no line names the recipe by a good id: it cannot be read" ;;
    *) same "$st" unreadable "$f: the recipe cannot be read" ;;
  esac
done > "$W/files.out"
cat "$W/files.out"
FAILS=$((FAILS + $(grep -c '^FAIL' "$W/files.out")))
same "$(grep -c . "$W/files.out")" "$(( 2 * $(echo "$files" | wc -l) ))" "every file in MANIFEST was checked"

# Every value of in-upper.tsv at its largest, read in base 10
s=$(section "$out" "$B/in-upper.tsv")
same "$(kind "$s" build | cut -f11-16,22-24,33 | tr '\t' ' ')" \
  "1048576 1048576 1048576 4194304 1.000 0.999 999999999999999 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef 99 1048576" \
  "in-upper: the largest numbers, read in base 10"
same "$(kind "$s" recipe | cut -f5-9 | tr '\t' ' ')" "abcdefghijklmnopqrstuvwxyz0123456789-zzzz publisher,endorsed,third-party 64 1048576 1048576" \
  "in-upper: the recipe's label, tiers, people and contexts"
s=$(section "$out" "$B/in-lower.tsv")
same "$(kind "$s" build | cut -f11-14,20,22,24,29,33 | tr '\t' ' ')" "0 0 0 0 b0000 0 0 0 0" "in-lower: the smallest numbers"

# The gate fails each outside file, naming the lines MANIFEST names, and passes the inside ones
tail -n +2 "$B/MANIFEST" | while IFS=$'\t' read -r f with lines what; do
  g=$(gate "$B/$f"); rc=$?
  case "$f" in
    in-*) same "$rc:$g" 0: "gate: $f passes" ;;
    *) same "$rc:$(printf '%s\n' "$g" | sed -n 's/^line \([0-9]*\): [^n].*/\1/p' | sort -n | paste -sd, -)" "1:$lines" "gate: $f fails, naming line $lines" ;;
  esac
done > "$W/gate.out"
cat "$W/gate.out"
FAILS=$((FAILS + $(grep -c '^FAIL' "$W/gate.out")))

# The first line: auster-registry, format 1, a version vA.B.C in base 10
head1() { { printf '%s\n' "$1"; tail -n +2 "$REG/good-v0.1.0.tsv"; } > "$W/$2.tsv"; }
head1 "auster-registry${T}1${T}v0.0.0" v000
head1 "auster-registry${T}1${T}v999999999.999999999.999999999" vmax
head1 "auster-registry${T}2${T}v0.1.0" f2
head1 "auster-registry${T}01${T}v0.1.0" f01
head1 "auster-registry${T}${T}v0.1.0" fempty
head1 "auster-registry${T}1${T}v0.01.0" v01
head1 "auster-registry${T}1${T}v0.1" vshort
head1 "auster-registry${T}1${T}V0.1.0" vupper
head1 "auster-registry${T}1${T}v1000000000.0.0" vlong
head1 "Auster-registry${T}1${T}v0.1.0" name
head1 "auster-registry${T}1" two
head1 "auster-registry${T}1${T}v0.1.0${T}later" extra
o=$(each "$HH" "$W"/v000.tsv "$W"/vmax.tsv "$W"/f2.tsv "$W"/f01.tsv "$W"/fempty.tsv "$W"/v01.tsv "$W"/vshort.tsv \
  "$W"/vupper.tsv "$W"/vlong.tsv "$W"/name.tsv "$W"/two.tsv "$W"/extra.tsv)
while read -r n want; do
  same "$(section "$o" "$W/$n.tsv" | cut -f1,2 | head -1 | tr '\t' ' ') $(section "$o" "$W/$n.tsv" | grep '^recipe' | cut -f3)" "$want" "first line $n: $want"
done <<EOF
v000 registry 1 ok
vmax registry 1 ok
f2 unread format unreadable
f01 unread format unreadable
fempty unread format unreadable
v01 unread version unreadable
vshort unread version unreadable
vupper unread version unreadable
vlong unread version unreadable
name unread not-a-registry unreadable
two unread not-a-registry unreadable
extra registry 1 ok
EOF
g=$(gate "$W/extra.tsv"); same "$?:$g" "1:line 1: 4 fields, the first line has 3" "a first line with a field after the version: a Mac reads it, the gate fails it"
done_
