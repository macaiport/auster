# T42 (D3.4): a try with no route to GitHub, curl's exit 6 (the name does not resolve) or 7 (nothing answers)
# on the first request, does not use up the day: `tried` is put back as it was, absent or byte for byte, the
# second request is not made, and the next firing, minutes later, tries again and fetches. Every other failure
# uses the day up (T4). Once there are two requests (U3), `tried` is put back only on the first one's no route:
# exit 6 or 7 on the second, the registry, uses up the day like any other failure, and nothing is written.
# Mutants: tests/mutants/T42a (tried not put back) and T42b (put back on the second request's no route too).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0

for ec in 6 7; do
  fresh; stamp release v0.1.0; answer "exit:$ec,200" "$W/cl"
  same "$(upd --refresh | cut -f1,5):$([ -e "$U/tried" ] && echo tried || echo none):$(leftovers):$(asks)" "unknown${TAB}failed:none:0:1" \
    "curl's exit $ec with no tried before: failed, still no tried, and no second request"
  same "$(AT=$((NOW + 300)) upd --refresh | cut -f1,5):$(asks):$(cat "$U/tried")" "ready${TAB}fetched:3:auster-record 1$TAB$((NOW + 300))" \
    "  ...the next firing, five minutes later, tries again and fetches, with both requests"

  fresh; stamp release v0.1.0; answer "exit:$ec,200" "$W/cl"
  printf 'auster-record 1\t%s' $((NOW - 90000)) > "$U/tried"; touch -t 202611200800 "$U/tried"; was=$(sum "$U/tried")
  same "$(upd --refresh | cut -f5):$(sum "$U/tried"):$(stat -f %Sm -t %Y%m%d%H%M "$U/tried"):$(leftovers)" "failed:$was:202611200800:0" \
    "curl's exit $ec with an older tried (no final newline): put back byte for byte, with its time"
  same "$(AT=$((NOW + 300)) upd --refresh | cut -f5):$(asks)" "fetched:3" "  ...the next firing tries again and fetches"

  # the second request's no route (U3)
  fresh; stamp release v0.1.0; offer v0.1.0; reg_as v0.2.0 "$W/reg-v0.2.0.tsv"; answer_reg "exit:$ec,200" "$W/reg-v0.2.0.tsv"; answer 200 "$W/cl"
  same "$(upd --refresh | cut -f1,3,5):$(cat "$U/tried" 2>/dev/null):$(leftovers):$([ -e "$U/registry" ] && echo registry || echo none)" \
    "current${TAB}v0.1.0${TAB}failed:auster-record 1$TAB$NOW:0:none" \
    "the registry's exit $ec after a changelog that answered: failed, the day used up, nothing written"
  same "$(AT=$((NOW + 300)) upd --refresh | cut -f5):$(asks)" "skipped:2" "  ...and the next firing fetches nothing"
done

fresh; stamp release v0.1.0; answer "exit:28,200" "$W/cl"
same "$(upd --refresh | cut -f5):$(cat "$U/tried")" "failed:auster-record 1$TAB$NOW" "curl's exit 28 (it reached no answer in time): the day is used up"
same "$(AT=$((NOW + 300)) upd --refresh | cut -f5):$(asks)" "skipped:2" "  ...and the next firing fetches nothing"
done_
