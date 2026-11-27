# T3 (D3.2, D3.3): an answer over 1 MiB served with exit 0 (the stub curl told to deliver past --max-filesize, as a
# server that sends no length can) is dropped: the check fails, `offer`, `notes.md` and `registry` are as they were,
# and no temporary file is left. An answer of exactly 1,048,576 bytes is taken; one byte more, which curl refuses
# itself (exit 63), is dropped too. The same for the registry, the second request (U3): its own size is measured
# again, and one over 1 MiB drops the pair, though the changelog was good. Mutants: tests/mutants/T3a (the
# changelog's size check removed) and T3b (the registry's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env

sized() { # BYTES OUT -> a changelog naming v0.2.0, exactly BYTES long
  { printf '# Changelog\n\n## v0.2.0 (2026-12-01)\n\nTwo.\n\n'; head -c "$1" /dev/zero | tr '\0' 'x'; } | head -c "$1" > "$2"
}
sized 1048576 "$W/cap.md"; sized 1048577 "$W/over.md"
same "$(stat -f %z "$W/cap.md"):$(stat -f %z "$W/over.md")" "1048576:1048577" "the fixtures are 1 MiB and 1 MiB plus one byte"
reg_as v0.2.0 "$W/reg2.tsv"
registry_sized "$W/reg2.tsv" 1048576 "$W/regcap.tsv"; registry_sized "$W/reg2.tsv" 1048577 "$W/regover.tsv"
same "$(stat -f %z "$W/regcap.tsv"):$(stat -f %z "$W/regover.tsv")" "1048576:1048577" "the registries are 1 MiB and 1 MiB plus one byte, of v0.2.0"
changelog "$W/cl" v0.2.0 v0.1.0

before() {
  fresh; stamp release v0.1.0; offer v0.1.0; echo "old notes" > "$U/notes.md"; reg_as v0.1.0 "$U/registry"
  o=$(sum "$U/offer"); n=$(sum "$U/notes.md"); g=$(sum "$U/registry")
}
unchanged() { # LABEL
  same "$(sum "$U/offer"):$(sum "$U/notes.md"):$(sum "$U/registry"):$(leftovers)" "$o:$n:$g:0" "$1: offer, notes.md and registry as they were, nothing left over"
}

before; answer 200 "$W/over.md" "X-Stub-Ignore-Max-Filesize: 1"
same "$(upd --refresh | cut -f1,3,5)" "current${TAB}v0.1.0${TAB}failed" "1 MiB plus one byte, served with exit 0: failed, the offer unchanged"
same "$(asks)" 2 "  ...after its two requests"
unchanged "  ...and"
before; answer 200 "$W/over.md"
same "$(upd --refresh | cut -f5)" failed "1 MiB plus one byte that curl refuses (exit 63): failed"
unchanged "  ...and"
before; answer 200 "$W/cap.md"
same "$(upd --refresh | cut -f1,3,5)" "ready${TAB}v0.2.0${TAB}fetched" "exactly 1,048,576 bytes: taken"
same "$(cmp -s "$U/notes.md" "$W/cap.md" && echo same)" same "  ...as notes.md, whole"

# --- the registry's half (U3)
before; answer_reg 200 "$W/regover.tsv" "X-Stub-Ignore-Max-Filesize: 1"; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,3,5)" "current${TAB}v0.1.0${TAB}failed" "a registry of 1 MiB plus one byte, served with exit 0: failed, the offer unchanged"
same "$(asks)" 2 "  ...after its two requests"
unchanged "  ...and"
before; answer_reg 200 "$W/regover.tsv"; answer 200 "$W/cl"
same "$(upd --refresh | cut -f5)" failed "a registry of 1 MiB plus one byte that curl refuses (exit 63): failed"
unchanged "  ...and"
before; answer_reg 200 "$W/regcap.tsv"; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,3,5)" "ready${TAB}v0.2.0${TAB}fetched" "a registry of exactly 1,048,576 bytes: taken with the changelog"
same "$(cmp -s "$U/registry" "$W/regcap.tsv" && echo same):$(cmp -s "$U/notes.md" "$W/cl" && echo same)" "same:same" "  ...as registry and notes.md, whole"
done_
