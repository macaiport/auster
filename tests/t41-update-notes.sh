# T41 (D3.2): a Mac that skipped three versions is shown the changelog sections of all three, newest first,
# after a check that fetched them, and not its own version's or an older one's. With the notes cleaner: the
# cases of 1launcher's test (Unreleased and the installed version left out; paragraphs joined; list items;
# fences; ** and backticks; control characters; cut before 200 lines and before 12,000 bytes, with the
# pointer to the changelog; no notes) and what Auster's adds: empty lines never doubled nor last, headings
# below a version's lose their marks, tabs become spaces, CRLF endings, and the two-byte control characters
# U+0080 to U+009F are removed while U+00A0 is kept. Mutant: tests/mutants/T41a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
MORE='More: https://github.com/macaiport/auster/blob/release/CHANGELOG.md'

# --- T41
fresh; stamp release v0.1.0; changelog "$W/cl" v0.4.0 v0.3.0 v0.2.0 v0.1.0 v0.0.9; answer 200 "$W/cl"
same "$(upd --refresh | cut -f1,3,5)" "ready${TAB}v0.4.0${TAB}fetched" "three versions behind: ready, v0.4.0 offered"
same "$(upd --notes | grep '^v[0-9]' | tr '\n' '|')" "v0.4.0 (2026-12-01)|v0.3.0 (2026-12-01)|v0.2.0 (2026-12-01)|" \
  "  ...--notes shows the sections of all three, newest first"
same "$(upd --notes | tr '\n' '|')" "v0.4.0 (2026-12-01)||The change in v0.4.0. What it does.||v0.3.0 (2026-12-01)||The change in v0.3.0. What it does.||v0.2.0 (2026-12-01)||The change in v0.2.0. What it does.|" \
  "  ...and each section's text, cleaned"

# --- the cleaner
fresh; stamp release v0.2.0
changelog "$U/notes.md" v0.3.0 v0.2.0
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-12-01)||The change in v0.3.0. What it does.|" "only the sections newer than the stamp, the heading without its marks"
printf '%s\n' '## Unreleased' 'not shown' '## v0.5.0 (2026-01-03)' 'five' '## v0.4.0 (2026-01-02)' 'four' '## v0.3.0 (2026-01-01)' 'three' > "$U/notes.md"; stamp release v0.3.0
same "$(upd --notes | tr '\n' '|')" "v0.5.0 (2026-01-03)|five||v0.4.0 (2026-01-02)|four|" "  ...newest first, Unreleased and the installed version left out"
stamp release v0.2.0
printf '%s\n' '## v0.3.0 (2026-01-01)' 'one line' 'and its second' '' 'a new paragraph' '- an item' '  that goes on' '- a second item' '1. a numbered one' 'still that one' > "$U/notes.md"
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|one line and its second||a new paragraph|- an item that goes on|- a second item|1. a numbered one still that one|" \
  "  ...a paragraph's lines joined, ending at an empty line, an item or a number; an item's lines join it"
printf '%s\n' '## v0.3.0 (2026-01-01)' '' '' 'one' '' '' '' 'two' '' '' > "$U/notes.md"
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)||one||two|" "  ...empty lines never doubled, nor last"
printf '%s\n' '## v0.3.0 (2026-01-01)' 'before' '```bash' 'sec() { a;' '  b; }' '```' 'after' > "$U/notes.md"
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|before|sec() { a;|  b; }|after|" "  ...the fence lines dropped, the lines between them as they are"
printf '%s\n' '## v0.3.0 (2026-01-01)' '**Bold** and `code` and a * alone' > "$U/notes.md"
same "$(upd --notes | tail -n 1)" "Bold and code and a * alone" "  ...** and backticks removed"
printf '%s\n' '## v0.3.0 (2026-01-01)' '### Fixed' '- a fix' '# Loud' 'text' '#hashtag stays' > "$U/notes.md"
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|Fixed|- a fix|Loud|text #hashtag stays|" "  ...headings below a version's lose their marks"
printf '## v0.3.0 (2026-01-01)\nred \033[31mtext\007 and a\ttab\r\nnext\r\n' > "$U/notes.md"
same "$(upd --notes | tr '\n' '|')" "v0.3.0 (2026-01-01)|red [31mtext and a tab next|" "  ...control characters removed, the tab made a space, CRLF read as a line end"
printf '## v0.3.0 (2026-01-01)\ncsi \302\23331m here, nel \302\205 there, \302\200 and \302\237 too, nbsp \302\240 kept\n' > "$U/notes.md"
same "$(upd --notes | tail -n 1)" "$(printf 'csi 31m here, nel  there,  and  too, nbsp \302\240 kept')" "  ...the two-byte control characters U+0080 to U+009F removed, U+00A0 kept"
{ echo '## v0.3.0 (2026-01-01)'; i=0; while [ $i -lt 300 ]; do echo "- item $i"; i=$((i + 1)); done; } > "$U/notes.md"
same "$(upd --notes | wc -l | tr -d ' '):$(upd --notes | sed -n 200p):$(upd --notes | tail -n 1)" "201:- item 198:$MORE" "  ...cut before the 201st line, with the pointer to the changelog"
{ echo '## v0.3.0 (2026-01-01)'; i=0; while [ $i -lt 150 ]; do printf -- '- %0100d\n' "$i"; i=$((i + 1)); done; } > "$U/notes.md"
same "$(upd --notes | sed '$d' | wc -c | tr -d ' '):$(upd --notes | tail -n 1)" "11968:$MORE" "  ...cut before the line that would pass 12,000 bytes"
mv "$U/notes.md" "$W/real-notes"; ln -s "$W/real-notes" "$U/notes.md"
same "$(upd --notes; echo "rc=$?")" "rc=0" "  ...notes.md a link: nothing, exit 0"
rm "$U/notes.md"
same "$(upd --notes; echo "rc=$?")" "rc=0" "  ...no notes: nothing, exit 0"
done_
