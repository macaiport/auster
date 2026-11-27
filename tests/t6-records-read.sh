# T6 (D3.1, Reading): for every record of D3.1, each of its readers -- common/auster's (the driver's and bin/auster's),
# the engine job's and the check job's own, the rule file's (updates.sh) and section C's (capability-lib.js) -- treats
# as absent a link, a folder, a file beyond its bound, a line more where the record has its lines (a second line
# where it is one line; a 65th build id in `hold`), a field more, and `a[$(touch f)]` in any field; and `f` is never
# made. A `hold` that cannot be read passes its recipe over (unreadable) and is never taken as no holds; a `stopped`
# that cannot be read means stopped, the reason unknown. Each record's good form reads first, so that a case fails
# for what it holds. An entry of kept/ or failed/ not named by its date and build is absent too, and a build line
# with a field this version does not know still reads (A5). The records are made by hand (tests/records-helpers.sh).
# Mutants: tests/mutants/T6a to T6d, and T6g (the rule file's own hold reader, U3: an unreadable hold as no holds).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/records-helpers.sh"
records_env

for rec in $RECORDS; do
  p=$(path_of "$rec")
  case "$rec" in hold) want=unreadable ;; stopped) want=unknown ;; *) want=absent ;; esac
  for r in $(readers_of "$rec"); do
    good "$rec" "$p"
    same "$(read_with "$r" "$p")" ok "$rec, $r: its good form reads"
  done
  for c in $(cases_of "$rec"); do
    make_case "$rec" "$c" "$p"
    q=$p; [ "$c" != name ] || q="${p%/*}/$IB1"
    for r in $(readers_of "$rec"); do
      got=$(read_with "$r" "$q")
      if [ "$got" = "$want" ]; then ok "$rec, $c, $r: $want"; else bad "$rec, $c, $r: got [$got], expected [$want]"; fi
    done
    rm -rf "$q"
    [ -e "$RUN/f" ] && { bad "$rec, $c: f was made"; rm -f "$RUN/f"; }
  done
  good "$rec" "$p"
done
[ -e "$RUN/f" ] && bad "f exists" || ok "f was never made"

# The two exceptions, and absence itself: no hold is no holds; no stopped is not stopped
rm -f "$(path_of hold)"; same "$(read_with auster.hold -)" absent "no hold at all: absent, which is no holds"
rm -f "$(path_of stopped)"; same "$(read_with auster.stopped -)" absent "no stopped at all: not stopped"
good hold "$(path_of hold)"; good stopped "$(path_of stopped)"

# A field this version does not know, after the last of the build, engine and model lines, is kept and not read (A5)
p=$(path_of serving)
good serving "$W/s"; awk -v t="$(printf '\t')" 'NR >= 2 && NR <= 4 { $0 = $0 t "later" } { print }' "$W/s" > "$p"
for r in $(readers_of serving); do same "$(read_with "$r" "$p")" ok "serving with a field more on its build, engine and model lines, $r: reads"; done
good serving "$p"
done_
