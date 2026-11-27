# T5, the rule file's half (D3.2, D3.10): with `off` present (a file, a folder, a link to nothing) or the stamp
# on `checkout` (or `tag`, an install by a named version), --refresh and --refresh --now send no request and
# write nothing (the folder is as it was, by snapshot), and the word is `off` or `manual` with the line as the
# detail. With no stamp at all (`none`) the same. `auster status`'s half is t5-status-checks.sh (U2); `auster
# update`'s is U4's. Mutant: tests/mutants/T5a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0

quiet() { # WORD DETAIL LABEL: no request, nothing written, with and without --now
  local before
  answer 200 "$W/cl"
  before=$(snapshot "$U")
  same "$(upd --refresh | cut -f1,4,5):$(upd --refresh --now | cut -f1,4,5)" "$1$TAB$2${TAB}skipped:$1$TAB$2${TAB}skipped" "$3: $1, skipped, with --now too"
  same "$(asks)" 0 "  ...no request"
  same "$(snapshot "$U")" "$before" "  ...nothing written"
}
fresh; stamp release v0.1.0; offer v0.1.0; : > "$U/off"; quiet off - "off, a file, on a release stamp"
fresh; stamp release v0.1.0; mkdir "$U/off"; quiet off - "off, a folder"
fresh; stamp release v0.1.0; ln -s "$W/nowhere" "$U/off"; quiet off - "off, a link to nothing"
fresh; stamp checkout v0.1.0 -; offer v0.1.0; quiet manual checkout "a stamp on checkout"
fresh; stamp tag v0.1.0; quiet manual tag "a stamp for a named version"
fresh; quiet none - "no stamp"
fresh; stamp release v0.1.0; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,5):$(asks)" "ready${TAB}fetched:1" "the same folder with the stamp on release and no off: one request"
done_
