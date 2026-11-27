# T42 (D3.4): a try with no route to GitHub, curl's exit 6 (the name does not resolve) or 7 (nothing answers)
# on the first request, does not use up the day: `tried` is put back as it was, absent or byte for byte, and
# the next firing, minutes later, tries again and fetches. Every other failure uses the day up (T4).
# Mutant: tests/mutants/T42a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0

for ec in 6 7; do
  fresh; stamp release v0.1.0; answer "exit:$ec,200" "$W/cl"
  same "$(upd --refresh | cut -f1,5):$([ -e "$U/tried" ] && echo tried || echo none):$(leftovers)" "unknown${TAB}failed:none:0" \
    "curl's exit $ec with no tried before: failed, and still no tried"
  same "$(AT=$((NOW + 300)) upd --refresh | cut -f1,5):$(asks):$(cat "$U/tried")" "ready${TAB}fetched:2:auster-record 1$TAB$((NOW + 300))" \
    "  ...the next firing, five minutes later, tries again and fetches"

  fresh; stamp release v0.1.0; answer "exit:$ec,200" "$W/cl"
  printf 'auster-record 1\t%s' $((NOW - 90000)) > "$U/tried"; touch -t 202611200800 "$U/tried"; was=$(sum "$U/tried")
  same "$(upd --refresh | cut -f5):$(sum "$U/tried"):$(stat -f %Sm -t %Y%m%d%H%M "$U/tried"):$(leftovers)" "failed:$was:202611200800:0" \
    "curl's exit $ec with an older tried (no final newline): put back byte for byte, with its time"
  same "$(AT=$((NOW + 300)) upd --refresh | cut -f5):$(asks)" "fetched:2" "  ...the next firing tries again and fetches"
done

fresh; stamp release v0.1.0; answer "exit:28,200" "$W/cl"
same "$(upd --refresh | cut -f5):$(cat "$U/tried")" "failed:auster-record 1$TAB$NOW" "curl's exit 28 (it reached no answer in time): the day is used up"
same "$(AT=$((NOW + 300)) upd --refresh | cut -f5):$(asks)" "skipped:1" "  ...and the next firing fetches nothing"
done_
