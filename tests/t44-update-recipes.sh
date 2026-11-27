# T44, the recipe half (U3; D3.3, D3.7): each recipe's line through the rule file (--recipes), from _update/registry
# and the records in builds/. A registry listing builds 1 to 3 for the household recipe, on the 64 GB Mac: serving
# the first gives `same`, and the word `current` when the scripts are current; serving the second with the first
# held (builds/<recipe>/hold) gives `same`; serving the second with the first free gives `waiting`, for the first,
# and `ready`; serving a withdrawn first gives the second as `waiting`, the withdrawal said; serving the third with
# the first two held, `same`. A build in failed/ is not offered, and an entry there that cannot be read counts as
# absent (D3.1). A `hold` that cannot be read (a folder, a link, a 65th build id, a newer format's) passes the recipe
# over and is never taken as no holds; with the build served withdrawn and everything held, `withdrawn`. A serving
# that cannot be read passes the recipe over. And the records of three recipes on one Mac (tests/fixtures/records/
# three, named by tests/fixtures/registry/records.tsv): one line each, in the order of their ids: A same (its first
# build failed here and held), B withdrawn, C waiting with nothing to download, since store/ holds its files.
# Mutant: tests/mutants/T44b (call any appropriate build that differs `waiting`; T44a is the registry's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
B3=bhoe4j755eetl   # the build in no order line of judgements.tsv, ordered third here
{ cat "$REGF/good-v0.1.0.tsv"; sed -n 9p "$REGF/judgements.tsv"; printf 'order\t%s\t%s\t%s\t%s\n' $HH $B1 $B2 $B3; } > "$W/three.tsv"
{ cat "$W/three.tsv"; printf 'withdraw\t%s\tsecurity\n' $B1; } > "$W/withdrawn.tsv"

on() { # REGISTRY BUILD-SERVED -> the three of v0.1.0 with that registry, the 64 GB Mac, that build served
  fresh; known v0.1.0 "$1"; mac_put 53084 $GB64; served $HH "$2" 4 32768 "$1"
}
says() { # WORD-AND-FIELDS LABEL -> the state line's word, then the recipe's word, reasons, withdrawal, build waiting
  local o
  o=$(upd --recipes)
  same "$(printf '%s\n' "$o" | head -n 1 | cut -f1):$(line_of $HH "$o" | cut -f3,4,6,7 | tr '\t' ' ')" "$1" "$2"
  same "$(upd | cut -f1)" "${1%%:*}" "  ...the state line of the call with no option says the same"
}

on "$W/three.tsv" $B1; says "current:same - - -" "serving the first: same, and current"
on "$W/three.tsv" $B2; hold_put $HH $B1; says "current:same - - -" "serving the second with the first held: same"
on "$W/three.tsv" $B2; says "ready:waiting - - $B1" "serving the second with the first free: waiting, for the first; ready"
on "$W/withdrawn.tsv" $B1; says "ready:waiting - security $B2" "serving a withdrawn first: the second waiting, the withdrawal said"
on "$W/three.tsv" $B3; hold_put $HH $B1 $B2; says "current:same - - -" "serving the third with the first two held: same"
on "$W/three.tsv" $B3; says "ready:waiting - - $B1" "serving the third with the first two free: the first waiting"

# failed/
on "$W/three.tsv" $B2; entry $HH failed $B1 2026-11-21T10:00:00Z "$W/three.tsv"
says "current:same - - -" "serving the second, the first in failed/: same"
on "$W/three.tsv" $B2; entry $HH failed $B1 2026-11-21T10:00:00Z "$W/three.tsv"
mv "$W/builds/$HH/failed/2026-11-21T10:00:00Z-$B1" "$W/builds/$HH/failed/2026-11-21T10:00:00Z-$B3"
says "ready:waiting - - $B1" "  ...an entry of failed/ whose name is not its build's cannot be read: absent, the first waiting"

# hold that cannot be read
for c in folder link line newer; do
  on "$W/three.tsv" $B2
  case "$c" in
    folder) mkdir "$W/builds/$HH/hold" ;;
    link) hold_put $HH $B3; mv "$W/builds/$HH/hold" "$W/hold-elsewhere"; ln -s "$W/hold-elsewhere" "$W/builds/$HH/hold" ;;
    line) hold_put $HH $B3; for i in $(seq 64); do echo $B3 >> "$W/builds/$HH/hold"; done ;;
    newer) printf 'auster-record 2\n%s\n' $B3 > "$W/builds/$HH/hold" ;;
  esac
  says "current:passed-over held - -" "a hold that cannot be read ($c): passed over, held, never taken as no holds"
done
on "$W/withdrawn.tsv" $B1; mkdir "$W/builds/$HH/hold"
says "current:withdrawn withdrawn,held security -" "serving a withdrawn first, the hold unread: withdrawn, saying why"
on "$W/three.tsv" $B2; printf 'auster-descriptor 1\n' > "$W/builds/$HH/serving"
says "current:passed-over serving - -" "a serving that cannot be read: passed over"
o=$(upd --recipes)
same "$(line_of $HH "$o" | cut -f5,13)" "-${TAB}household" "  ...no build served is named; the label still read"

# Three recipes on one Mac
fresh; known v0.1.0 "$REGF/records.tsv"; records_fixture three "$W/r3"; cp -R "$W/r3/builds" "$W/r3/store" "$W/r3/engines" "$W/"
o=$(upd --recipes)
same "$(printf '%s\n' "$o" | head -n 1 | cut -f1)" ready "three recipes, one with a build waiting: ready"
same "$(printf '%s\n' "$o" | tail -n +2 | cut -f2 | tr '\n' ' ')" "r6xnosrsvgruc rapdsanqlj2eu rkfbt7hbg4kzw " "  ...one line each, in the order of their ids"
same "$(line_of rapdsanqlj2eu "$o" | cut -f3-7,13 | tr '\t' ' ')" "same - bm4smkutoesko - - recipe-a" "  ...A: same (its first build failed here and held)"
same "$(line_of rkfbt7hbg4kzw "$o" | cut -f3-7,13 | tr '\t' ' ')" "withdrawn withdrawn bjhl5vv2hfgyg quality - recipe-b" "  ...B: withdrawn (quality), nothing else offered"
same "$(line_of r6xnosrsvgruc "$o" | cut -f3-14 | tr '\t' ' ')" "waiting - bx33a5rua3kky - bxiegclg6uhkw 0 1 8192 15247 15679 recipe-c model-b.gguf" \
  "  ...C: waiting for its new build, nothing to download (store/ holds its files), 1 person at 8,192"
rm "$W/store/f542df1e9a28af488f88f109f1d7cf0b972864dd07cec58dc1d5871e9216a8c8"
same "$(rfield r6xnosrsvgruc 8)" 17 "  ...with model B gone from store/: its 17 bytes to download"
done_
