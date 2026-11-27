# T3, the changelog's half (D3.2): an answer over 1 MiB served with exit 0 (the stub curl told to deliver past
# --max-filesize, as a server that sends no length can) is dropped: the check fails, `offer` and `notes.md`
# are as they were, and no temporary file is left. An answer of exactly 1,048,576 bytes is taken; one byte
# more, which curl refuses itself (exit 63), is dropped too. The registry's half is U3's.
# Mutant: tests/mutants/T3a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env

sized() { # BYTES OUT -> a changelog naming v0.2.0, exactly BYTES long
  { printf '# Changelog\n\n## v0.2.0 (2026-12-01)\n\nTwo.\n\n'; head -c "$1" /dev/zero | tr '\0' 'x'; } | head -c "$1" > "$2"
}
sized 1048576 "$W/cap.md"; sized 1048577 "$W/over.md"
same "$(stat -f %z "$W/cap.md"):$(stat -f %z "$W/over.md")" "1048576:1048577" "the fixtures are 1 MiB and 1 MiB plus one byte"

before() { fresh; stamp release v0.1.0; offer v0.1.0; echo "old notes" > "$U/notes.md"; o=$(sum "$U/offer"); n=$(sum "$U/notes.md"); }
unchanged() { # LABEL
  same "$(sum "$U/offer"):$(sum "$U/notes.md"):$(leftovers)" "$o:$n:0" "$1: offer and notes.md as they were, nothing left over"
}

before; answer 200 "$W/over.md" "X-Stub-Ignore-Max-Filesize: 1"
same "$(upd --refresh | cut -f1,3,5)" "current${TAB}v0.1.0${TAB}failed" "1 MiB plus one byte, served with exit 0: failed, the offer unchanged"
same "$(asks)" 1 "  ...after one request"
unchanged "  ...and"
before; answer 200 "$W/over.md"
same "$(upd --refresh | cut -f5)" failed "1 MiB plus one byte that curl refuses (exit 63): failed"
unchanged "  ...and"
before; answer 200 "$W/cap.md"
same "$(upd --refresh | cut -f1,3,5)" "ready${TAB}v0.2.0${TAB}fetched" "exactly 1,048,576 bytes: taken"
same "$(cmp -s "$U/notes.md" "$W/cap.md" && echo same)" same "  ...as notes.md, whole"
done_
