# T23 (D3.3): a Mac uses a registry only when its version line equals the newest version in the changelog just
# fetched, since each file can be up to five minutes stale on its own (D1.3). A registry whose version line is
# older or newer than the changelog's, or has none, is not used: offer, notes.md and registry are none of them
# written, the try counts as failed (the day used up), and nothing is said (the state line's word is what it
# was). With the two of one version all three are written, and a later registry left by a run cut short
# between the three writes is not used by a recipe's line until an offer of its version is written beside it.
# Mutant: tests/mutants/T23a (the registry used whatever its version line).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0
reg_as v0.1.0 "$W/reg1.tsv"; reg_as v0.3.0 "$W/reg3.tsv"; reg_as v0.2.0 "$W/reg2.tsv"
{ printf 'auster-registry\t1\n'; tail -n +2 "$REGF/good-v0.1.0.tsv"; } > "$W/regnov.tsv"
awk -F'\t' -v OFS='\t' 'NR == 1 { $3 = "v0.02.0" } { print }' "$REGF/good-v0.1.0.tsv" > "$W/regbad.tsv"

before() { fresh; stamp release v0.1.0; offer v0.1.0; echo "old notes" > "$U/notes.md"; cp "$W/reg1.tsv" "$U/registry"
  o=$(sum "$U/offer"); n=$(sum "$U/notes.md"); g=$(sum "$U/registry"); }
mismatch() { # LABEL REGISTRY
  before; answer_reg 200 "$2"; answer 200 "$W/cl"
  same "$(upd --refresh | cut -f1,3,5):$(asks)" "current${TAB}v0.1.0${TAB}failed:2" "$1: failed, after two requests; the word as it was"
  same "$(sum "$U/offer"):$(sum "$U/notes.md"):$(sum "$U/registry"):$(leftovers)" "$o:$n:$g:0" "  ...offer, notes.md and registry as they were"
  same "$(cat "$U/tried")" "auster-record 1$TAB$NOW" "  ...and the day's try used up"
}
mismatch "a registry of v0.1.0 beside a changelog of v0.2.0" "$W/reg1.tsv"
mismatch "a registry of v0.3.0 beside a changelog of v0.2.0" "$W/reg3.tsv"
mismatch "a registry whose first line has no version" "$W/regnov.tsv"
mismatch "a registry whose version is not one (v0.02.0)" "$W/regbad.tsv"

before; answer_reg 200 "$W/reg2.tsv"; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,3,5)" "ready${TAB}v0.2.0${TAB}fetched" "a registry of v0.2.0 beside a changelog of v0.2.0: taken"
same "$(cmp -s "$U/registry" "$W/reg2.tsv" && echo same):$(cmp -s "$U/notes.md" "$W/cl" && echo same):$(cut -f2 "$U/offer")" "same:same:v0.2.0" \
  "  ...registry, notes.md and offer, all three of v0.2.0"

# A registry left alone by a run cut short (written before the offer): no recipe's line uses it
fresh; known v0.1.0; mac_put 53084 $GB64; served $HH $B1 4 32768
same "$(rfield $HH 3)" same "the three of v0.1.0, serving order 1: same"
reg_as v0.2.0 "$U/registry" "$REGF/good-v0.2.0.tsv"   # v0.2.0 orders a new build first; the offer still says v0.1.0
same "$(upd | cut -f1):$(rfield $HH 3)" "current:unknown" "a registry of v0.2.0 beside an offer of v0.1.0: not judged, nothing waiting"
offer v0.2.0
same "$(upd | cut -f1):$(rfield $HH 3)" "ready:waiting" "  ...with an offer of v0.2.0 beside it: judged, the new build waiting"
stamp release v0.3.0
same "$(upd | cut -f1):$(rfield $HH 3)" "current:unknown" "  ...and with scripts of v0.3.0, newer than the registry: not judged"
done_
