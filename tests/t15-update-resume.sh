# T15 (U5; D3.6 step 3, B3 step 7): an update interrupted mid-download resumes from where it stopped, asks the commit
# address again, and the finished file still has to match its sha256. On a Mac serving order 2 with order 1 waiting, the
# CDN cuts the model off after 1,000 of its 3,400 bytes: exit 3, the part kept as store/<sha256>.part, and the build
# still waiting. The part counts among the disk holdings (the row "partial downloads" the V steps left to U5): the rule
# file's line and the next question both say 2,400 bytes are left to fetch. The next update's yes asks the address that
# names the commit again (never the CDN's), for the bytes from 1,000 on, and the file it finishes is model A in store/,
# with no part left. Cut off again, and finished from a CDN now serving another file of the same size: the file it
# finishes does not match its sha256 and is deleted, with exit 3.
# Mutants: tests/mutants/T15a (skip the sha256 for a resumed file), T15b (restart from zero), T15c (resume from the CDN's
# address), T15d (count no partial download among the disk holdings).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/
CDN=https://cdn.example.test/a P="$DATA/store/$SA.part"
cdn() { route_drop "$CDN"; curl_route GET "$CDN" "$@"; }   # STATUS BODY -> the CDN's answer, anew
first_get() { # -> the first GET of this run to Hugging Face or its CDN, and the Range it asked for
  local d
  for d in "$STUB_CURL_DIR"/requests/*; do
    [ "$(cat "$d/method")" = GET ] || continue
    case "$(cat "$d/url")" in *huggingface*|*cdn.example*) printf '%s %s' "$(cat "$d/url")" "$(sed -n 's/^Range: //p' "$d/headers")"; return ;; esac
  done
}
line() { AU_UPDATE_DIR="$DATA/_update" /bin/bash "$DATA/_update/updates.sh" --recipes | awk -F'\t' '$1 == "recipe" { print $3, $7, $8 }'; }

cdn exit:18:1000 "$FX/models/standin-a.gguf"
update_run $'yes\n'
same "$RC" 3 "the CDN cuts the download off at 1,000 bytes: exit 3"
says "The model's download stopped (curl exit 18, answer 200) at 1,000 bytes of 3,400 bytes." "  ...it says where it stopped"
same "$(stat -f %z "$P" 2>/dev/null)" 1000 "  ...the part kept in store/ for a resume"
[ -e "$DATA/store/$SA" ] && bad "  ...model A in store/ whole" || ok "  ...and no model A in store/"
same "$(line)" "waiting $IB1 2400" "  ...the rule file: order 1 still waiting, with 2,400 bytes left to fetch"

cdn 200 "$FX/models/standin-a.gguf"
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "the next update, answered yes: exit 0, its download finished, then tested and switched to"
says "  Download    2,400 bytes: standin-a.gguf from Hugging Face" "  ...its question: 2,400 bytes left to fetch"
same "$(first_get)" "$URL_A bytes=1000-" "  ...it resumed from 1,000, asking the address that names the commit again"
same "$(shasum -a 256 < "$DATA/store/$SA" 2>/dev/null | cut -c1-64)" "$SA" "  ...the finished file is model A, in store/"
[ -e "$P" ] && bad "  ...the part is left" || ok "  ...and no part is left"

waiting_b1   # order 2 served again, model A out of store/
cdn exit:18:1000 "$FX/models/standin-a.gguf"
update_run $'yes\n'
same "$RC:$(stat -f %z "$P" 2>/dev/null)" "3:1000" "cut off again at 1,000 bytes: exit 3, the part kept"
cdn 200 "$FX/models/standin-a-wrong.gguf"
update_run $'yes\n'
same "$RC" 3 "finished from a CDN that now serves another file of that size: exit 3"
says "The model that arrived is not the file the registry names (its sha256 differs), so it was deleted." "  ...the resumed file did not match its sha256"
[ -e "$DATA/store/$SA" ] || [ -e "$P" ] && bad "  ...a file for model A is left: $(ls "$DATA/store")" || ok "  ...and it was deleted, with no part left"
done_
