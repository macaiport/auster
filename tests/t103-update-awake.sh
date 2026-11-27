# T103, the update's download (U5; BD10, D3.6 step 3, B3 step 7): an update's download keeps the Mac awake as a first
# install's does. On a Mac serving order 2 with order 1 waiting: with the household's no in builds/mac, the model's
# download after the yes runs no caffeinate; with yes, it does, with -w naming the curl that downloads (and the engine job
# then serving the new build keeps the Mac awake too, its own half of T103). Mutants:
# tests/mutants/T103a (always keep awake during the download) and T103b (only the engine job keeps the Mac awake), the
# same lines a first install's download runs.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/
dl() { # -> the process of the curl that sent this run's GET of the model's address
  local d
  for d in "$STUB_CURL_DIR"/requests/*; do
    [ "$(cat "$d/url")" = "$URL_A" ] && [ "$(cat "$d/method")" = GET ] && cat "$d/pid"
  done
}

same "$(sed -n 's/^keep-awake	//p' "$DATA/builds/mac")" no "the install recorded the household's no"
n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "an update's download, keep-awake no: exit 0"
[ -n "$(dl)" ] && ok "  ...the model was downloaded" || bad "  ...no download of the model"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep -c '^caffeinate')" 0 "  ...and no caffeinate ran"

waiting_b1   # order 2 served again, model A out of store/
awk -F'\t' -v OFS='\t' '$1 == "keep-awake" { $2 = "yes" } { print }' "$DATA/builds/mac" > "$W/mac" && cat "$W/mac" > "$DATA/builds/mac"
n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 0 "keep-awake yes: exit 0"
p=$(dl)
[ -n "$p" ] && ok "  ...the model was downloaded, by curl $p" || bad "  ...no download of the model"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep '^caffeinate' | sort)" "$(printf 'caffeinate -i -w %s\n' "$p" "$(engine_pid)" | sort)" \
  "  ...caffeinate -i -w names the curl that downloads, and otherwise only the engine job serving the new build"
same "$(sed -n 's/^keep-awake	//p' "$DATA/builds/mac")" yes "  ...and builds/mac, written after the yes, keeps the household's yes"
done_
