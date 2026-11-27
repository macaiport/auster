# T103, the download's half (V5; the engine job's half, and its tests, are V6's): with the household's no
# in builds/mac, the model's download runs no caffeinate; with yes it does, with -w naming the curl that
# downloads (BD10, B3 step 7). Mutants: tests/mutants/T103a and T103b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the household's no: installed"
same "$(sed -n 's/^keep-awake	//p' "$DATA/builds/mac")" no "builds/mac records the no"
same "$(grep -c '^caffeinate' "$STUB_LOG")" 0 "no caffeinate ran"

install_cleanup; rm -rf "$H/Library/LaunchAgents"/* "$DATA" "$STUB_LAUNCHCTL_DIR"/loaded/* "$STUB_CURL_DIR/requests"
: > "$STUB_LOG"
run_install $'yes\nyes\nipad\n' "$IR"
same "$RC" 0 "the household's yes: installed"
same "$(sed -n 's/^keep-awake	//p' "$DATA/builds/mac")" yes "builds/mac records the yes"
dl=
for d in "$STUB_CURL_DIR"/requests/*; do
  [ "$(cat "$d/url")" = "$URL_A" ] && [ "$(cat "$d/method")" = GET ] && dl=$(cat "$d/pid")
done
[ -n "$dl" ] && ok "the model's download was sent, by curl $dl" || bad "no download of the model"
grep -qx "caffeinate -i -w $dl" "$STUB_LOG" && ok "caffeinate -i -w names the curl that downloads" || bad "caffeinate: $(grep '^caffeinate' "$STUB_LOG")"
done_
