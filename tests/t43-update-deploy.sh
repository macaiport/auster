# T43 (D3.1, D3.2): after an install, _update/updates.sh equals the tree's common/updates.sh byte for byte, mode
# 0644 as the jobs' programs, written with the stamp (B3 step 15). The check job runs that copy, which takes
# _update as its folder: with release's changelog naming a newer version, the check writes `tried` and `offer`
# there. And a caller that uses only an earlier version's options and output fields still works: the caller
# below is written against the contract as U1 leaves it (common/updates.sh's header), runs the deployed copy as
# the check job does (no AU_UPDATE_DIR), and reads only the fields U1 prints, by position.
# Mutants: tests/mutants/T43a (deploy nothing) and T43b (rename an option).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
D="$DATA/_update/updates.sh"
cmp -s "$ROOT/common/updates.sh" "$D" && ok "_update/updates.sh is the tree's common/updates.sh, byte for byte" || bad "_update/updates.sh: $(ls -l "$D" 2>&1)"
same "$(stat -f %Lp "$D" 2>/dev/null)" 644 "  ...mode 0644, as the jobs' programs"
same "$(cut -f1,2 "$DATA/_update/scripts")" "auster-record 1	release" "  ...beside the stamp"
same "$(ls -A "$DATA/_update" | grep '^\.')" "" "  ...and nothing temporary left beside them"

# --- the check job runs the deployed copy, in _update
route_drop "$CHANGELOG"
printf '# Changelog\n\n## Unreleased\n\n## v0.2.0 (2026-12-01)\n\n**Two.** Second.\n\n## v0.1.0 (2026-11-27)\n\nFirst.\n' > "$FX/changelog.md"
curl_route GET "$CHANGELOG" 200 "$FX/changelog.md"
AU_CHECK_LIMIT=5 check_job
grep -q 'the update check ran' "$W/check.out" && ok "the check job ran the update check" || bad "check.out: $(tail -n 5 "$W/check.out")"
same "$(cut -f1,2 "$DATA/_update/offer" 2>/dev/null)" "auster-record 1	v0.2.0" "  ...which wrote offer in _update"
same "$(cut -f1 "$DATA/_update/tried" 2>/dev/null)" "auster-record 1" "  ...and tried"
same "$(requests raw.githubusercontent.com)" "GET $CHANGELOG" "  ...after one request, to release's changelog"

# --- an earlier version's caller: U1's options, and only the fields U1 prints, by position
WORDS=' off none manual unknown ready current '
VER='^(v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})|-)$'
early() { # ARG... -> the deployed copy run as an earlier caller runs it: LINE its first line, RC its exit code
  local out
  out=$(env -u AU_UPDATE_DIR /bin/bash "$D" "$@" 2>&1); RC=$?
  LINE=$(printf '%s\n' "$out" | head -n 1)
}
field() { printf '%s\n' "$LINE" | cut -f"$1"; }
state_fields() { # LABEL -> fields 1 to 4 are the four U1 prints
  local w
  w=$(field 1)
  case "$WORDS" in *" $w "*) ok "$1: field 1 is a word of the six ($w)" ;; *) bad "$1: field 1 is [$w]" ;; esac
  if [[ $(field 2) =~ $VER ]] && [[ $(field 3) =~ $VER ]] && [ -n "$(field 4)" ]; then ok "$1: fields 2 to 4: a version or -, a version or -, the detail"
  else bad "$1: [$LINE]"; fi
}
early; same "$RC" 0 "no option: exit 0"; state_fields "no option"
same "$(field 1):$(field 2):$(field 3)" "ready:v0.1.0:v0.2.0" "  ...ready, v0.1.0 installed, v0.2.0 on offer"
early --refresh; same "$RC" 0 "--refresh: exit 0"; state_fields "--refresh"
same "$(field 5)" skipped "  ...field 5: skipped, since the check job tried today"
early --refresh --now; same "$RC:$(field 5)" "0:fetched" "--refresh --now: exit 0, field 5 fetched"
early --notes; same "$RC:$LINE" "0:v0.2.0 (2026-12-01)" "--notes: exit 0, the newer version's section first"
early --noted; same "$RC:$LINE" "0:v0.2.0" "--noted: exit 0, the offered version"
early --open; same "$RC:$(field 1)" "0:failed" "--open: exit 0, failed (U1 opens nothing)"
[ -n "$(field 2)" ] && ok "  ...with a sentence" || bad "--open: [$LINE]"
early --version-of "$FX/changelog.md"; same "$RC:$LINE" "0:v0.2.0" "--version-of: exit 0, the file's version"
early --no-such-option; same "$RC" 2 "an option no version has: exit 2"
done_
