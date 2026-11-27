# T1, its version half (D3.2): with no build waiting, a newer version on offer gives `ready` and the same or an
# older one `current`. The fixture holds v0.10.0 and v0.9.0, which versions compared as text get wrong. The
# half with a build waiting is U3's. With it, the cases of 1launcher's test of the rule file that still apply
# here: a file's version, `newer`, each word of the state line in D3.2's order, and the records the state
# reads, `scripts` and `offer`, counting as absent when they are a link, a folder, two lines, a field too many
# or too few, an empty field (runs of tabs), over 4,096 bytes, CRLF, a format field that is not
# `auster-record 1`, or a value that fails its pattern, `a[$(touch f)]` among them (and f is never made); a
# newer format's stamp gives `none` with the detail `newer`. And the file can be sourced twice under set -eu.
# Mutant: tests/mutants/T1a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env

# --- T1
fresh; stamp release v0.9.0; offer v0.10.0
same "$(upd)" "ready${TAB}v0.9.0${TAB}v0.10.0$TAB-" "v0.10.0 on offer, v0.9.0 installed: ready"
fresh; stamp release v0.10.0; offer v0.9.0
same "$(upd)" "current${TAB}v0.10.0${TAB}v0.9.0$TAB-" "v0.9.0 on offer, v0.10.0 installed: current"
fresh; stamp release v0.10.0; offer v0.10.0
same "$(upd)" "current${TAB}v0.10.0${TAB}v0.10.0$TAB-" "the same version on offer: current"
fresh; stamp release v0.9.0; changelog "$W/cl" v0.10.0 v0.9.0; answer 200 "$W/cl"
same "$(upd --refresh)" "ready${TAB}v0.9.0${TAB}v0.10.0$TAB-${TAB}fetched" "a check that finds v0.10.0 on release, v0.9.0 installed: ready"
fresh; stamp release v0.10.0; changelog "$W/cl" v0.9.0 v0.8.0; answer 200 "$W/cl"
same "$(upd --refresh)" "current${TAB}v0.10.0${TAB}v0.9.0$TAB-${TAB}fetched" "a check that finds v0.9.0, v0.10.0 installed: current"

# --- a file's version
changelog "$W/body.md" v0.3.0 v0.2.0
same "$(fn auu_version_of "$W/body.md")" v0.3.0 "a file's version: the first version heading, under Unreleased"
printf '%s\n' '# Changelog' '## Unreleased' 'words' > "$W/none.md"
same "$(fn auu_version_of "$W/none.md"; echo ":$?")" ":1" "no version heading: nothing, and 1"
same "$(fn auu_version_of "$W/nope.md"; echo ":$?")" ":1" "a file that is not there: 1"
for b in '## v0.03.0 (2026-01-01)' '## v1.2.3.4 (2026-01-01)' '## v1.2.3' '### v1.2.3 (2026-01-01)' \
  '## v1.2.1234567890 (2026-01-01)' ' ## v1.2.3 (2026-01-01)' '## 1.2.3 (2026-01-01)'; do
  printf '%s\n' "$b" > "$W/bad.md"
  same "$(fn auu_version_of "$W/bad.md"; echo ":$?")" ":1" "not a version heading: $b"
  printf '%s\n' "$b" '## v0.1.0 (2026-01-01)' > "$W/bad.md"
  same "$(fn auu_version_of "$W/bad.md")" v0.1.0 "  ...and the next real one is taken"
done
printf '## v123456789.0.1 (2026-01-01)\n' > "$W/wide.md"
same "$(fn auu_version_of "$W/wide.md")" v123456789.0.1 "nine digits in a number are a version"
{ head -c 1048576 /dev/zero | tr '\0' 'x'; printf '\n## v9.9.9 (2026-01-01)\n'; } > "$W/far.md"
same "$(fn auu_version_of "$W/far.md"; echo ":$?")" ":1" "a heading after the first 1 MiB is not read"
printf '## v0.4.0 (2026-01-01)' > "$W/nonl.md"
same "$(fn auu_version_of "$W/nonl.md")" v0.4.0 "a heading on a last line with no newline is read"
printf '## v0.4.0 (2026-01-01)\r\n' > "$W/crlf.md"
same "$(fn auu_version_of "$W/crlf.md")" v0.4.0 "a heading with a CRLF ending is read"

# --- newer
nw() { fn auu_newer "$1" "$2"; echo $?; }
same "$(nw v0.10.0 v0.9.9)" 0 "v0.10.0 is newer than v0.9.9"
same "$(nw v0.9.9 v0.10.0)" 1 "v0.9.9 is not newer than v0.10.0"
same "$(nw v1.0.0 v0.99.99)" 0 "v1.0.0 is newer than v0.99.99"
same "$(nw v0.0.10 v0.0.9)" 0 "v0.0.10 is newer than v0.0.9"
same "$(nw v0.3.0 v0.3.0)" 1 "equal is not newer"
same "$(nw v0.0.1 -)" 0 "a version is newer than -"
same "$(nw - v0.0.1):$(nw - -)" "1:1" "- is not newer than a version, nor than -"
same "$(nw v1.0.1234567890 v1.0.0)" 1 "a ten-digit number is not a version"
same "$(nw 'v1.0.a[$(touch '"$W"'/ran1)]' v1.0.0):$(nw v1.0.0 'a[$(touch '"$W"'/ran1)]'):$([ -e "$W/ran1" ] && echo ran || echo none)" \
  "1:1:none" "a value that would run a command in an arithmetic place is not a version, and runs nothing"

# --- the state line, each word in D3.2's order
fresh; offer v0.3.0
same "$(upd)" "none$TAB-${TAB}v0.3.0$TAB-" "no stamp, with an offer: none"
fresh; stamp checkout v0.3.0 -
same "$(upd)" "manual${TAB}v0.3.0$TAB-${TAB}checkout" "a checkout stamp and no offer: manual (not unknown), the detail checkout"
fresh; stamp tag v0.2.0; offer v0.4.0
same "$(upd)" "manual${TAB}v0.2.0${TAB}v0.4.0${TAB}tag" "a stamp for a named version, with a newer offer: manual, the detail tag"
fresh; stamp release v0.3.0
same "$(upd)" "unknown${TAB}v0.3.0$TAB-$TAB-" "a release stamp and no offer: unknown"
fresh; stamp release v0.3.0; offer v0.2.0
same "$(upd)" "current${TAB}v0.3.0${TAB}v0.2.0$TAB-" "an offer older than the stamp: current"
fresh; stamp release -; offer v0.0.1
same "$(upd)" "ready$TAB-${TAB}v0.0.1$TAB-" "a stamp with no version is lower than every version: ready"
fresh; stamp release v0.2.0; offer v0.3.0; : > "$U/off"
same "$(upd)" "off${TAB}v0.2.0${TAB}v0.3.0$TAB-" "the file off: off, whatever else is there"
fresh; stamp checkout v0.2.0; mkdir "$U/off"
same "$(upd | cut -f1)" off "off as a folder: off, before manual"
fresh; ln -s "$W/nowhere" "$U/off"
same "$(upd | cut -f1)" off "off as a link to nothing: off, before none"

# --- records that count as absent
bad_stamp() { # LABEL: the stamp written by the caller counts as absent: none, nothing run
  same "$(upd):$([ -e "$W/ran2" ] && echo ran || echo none)" "none$TAB-${TAB}v0.3.0$TAB-:none" "a stamp that is $1: absent"
}
fresh; offer v0.3.0
stamp release v0.2.0; mv "$U/scripts" "$W/real-stamp"; ln -s "$W/real-stamp" "$U/scripts"; bad_stamp "a link"
rm "$U/scripts"; mkdir "$U/scripts"; bad_stamp "a folder"; rmdir "$U/scripts"
r="auster-record 1${TAB}release${TAB}v0.2.0$TAB$HEX${TAB}2026-11-27T10:00:00Z"
printf '%s\n%s\n' "$r" "$r" > "$U/scripts"; bad_stamp "two lines"
printf '%s\n\n' "$r" > "$U/scripts"; bad_stamp "a line and an empty second line"
printf '%s\textra\n' "$r" > "$U/scripts"; bad_stamp "a field too many"
printf 'auster-record 1\trelease\tv0.2.0\t%s\n' "$HEX" > "$U/scripts"; bad_stamp "a field too few"
printf 'auster-record 1\trelease\t\tv0.2.0\t2026-11-27T10:00:00Z\n' > "$U/scripts"; bad_stamp "four fields after a run of two tabs (an empty field)"
printf '%s\r\n' "$r" > "$U/scripts"; bad_stamp "CRLF"
{ printf '%s\n' "$r"; head -c 5000 /dev/zero | tr '\0' ' '; } > "$U/scripts"; bad_stamp "over 4,096 bytes"
printf 'release\tv0.2.0\t%s\t2026-11-27T10:00:00Z\n' "$HEX" > "$U/scripts"; bad_stamp "without its format field (1launcher's form)"
printf 'auster-record 01\trelease\tv0.2.0\t%s\t2026-11-27T10:00:00Z\n' "$HEX" > "$U/scripts"; bad_stamp "auster-record 01"
printf 'Auster-record 1\trelease\tv0.2.0\t%s\t2026-11-27T10:00:00Z\n' "$HEX" > "$U/scripts"; bad_stamp "Auster-record 1"
printf 'auster-record 1\trelease\tv0.2.0\tnot-a-commit\t2026-11-27T10:00:00Z\n' > "$U/scripts"; bad_stamp "a commit that is not 40 hex digits"
printf 'auster-record 1\trelease\tv0.2.0\t%s\t1800000000\n' "$HEX" > "$U/scripts"; bad_stamp "a time that is not UTC in its form"
printf 'auster-record 1\tRelease\tv0.2.0\t%s\t2026-11-27T10:00:00Z\n' "$HEX" > "$U/scripts"; bad_stamp "a line in capitals"
for v in 'a[$(touch '"$W"'/ran2)]' v0.08.1 v1.2.3x 0.2.0; do
  printf 'auster-record 1\trelease\t%s\t%s\t2026-11-27T10:00:00Z\n' "$v" "$HEX" > "$U/scripts"; bad_stamp "of the version $v"
done
printf 'auster-record 1\trelease\tv0.2.0\t%s\ta[$(touch %s/ran2)]\n' "$HEX" "$W" > "$U/scripts"; bad_stamp "a time that would run a command"
printf '%s' "$r" > "$U/scripts"
same "$(upd)" "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-" "a stamp with no final newline counts"
printf 'auster-record 2\trelease\tv0.2.0\t%s\t2026-11-27T10:00:00Z\tmore\n' "$HEX" > "$U/scripts"; was=$(sum "$U/scripts")
same "$(upd):$(upd --refresh | cut -f5):$(asks)" "none$TAB-${TAB}v0.3.0${TAB}newer:skipped:0" "a stamp of a newer format: none, the detail newer, and nothing fetched"
same "$(sum "$U/scripts")" "$was" "  ...and it is left as it is"

for v in 'a[$(touch '"$W"'/ran3)]' v0.08.1 v1.2.3x 123456789012345678901234567890; do
  fresh; stamp release v0.2.0; printf 'auster-record 1\t%s\t1700000000\n' "$v" > "$U/offer"
  same "$(upd):$([ -e "$W/ran3" ] && echo ran || echo none)" "unknown${TAB}v0.2.0$TAB-$TAB-:none" "an offer of the version $v: absent, nothing run"
done
fresh; stamp release v0.2.0; printf 'auster-record 1\tv0.3.0\ta[$(touch %s/ran3)]\n' "$W" > "$U/offer"
same "$(upd | cut -f1,3):$([ -e "$W/ran3" ] && echo ran || echo none)" "unknown$TAB-:none" "an offer whose time would run a command: absent, nothing run"
fresh; stamp release v0.2.0; offer v0.3.0; mv "$U/offer" "$W/real-offer"; ln -s "$W/real-offer" "$U/offer"
same "$(upd | cut -f1,3)" "unknown$TAB-" "an offer that is a link: absent"
fresh; stamp release v0.2.0; printf 'auster-record 2\tv0.3.0\t1700000000\n' > "$U/offer"
same "$(upd | cut -f1,3)" "unknown$TAB-" "an offer of a newer format: not read"

# --- sourced, as a caller under set -eu does, twice
fresh; stamp release v0.2.0; offer v0.3.0
same "$( (set -eu; AU_UPDATE_DIR=$U; . "$S"; . "$S"; auu_state; auu_newer v0.1.0 v0.2.0 || echo older) 2>&1)" \
  "ready${TAB}v0.2.0${TAB}v0.3.0$TAB-
older" "sourced twice under set -eu: the state line, and a function that returns 1 does not end the caller"
done_
