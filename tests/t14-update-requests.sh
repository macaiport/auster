# T14, the changelog's half (D3.3, D3.10): each check makes exactly one request here, GET of release's
# CHANGELOG.md at raw.githubusercontent.com, carrying exactly the headers curl sends of itself (Host,
# User-Agent curl/<version>, Accept) and no body, whether or not anything is waiting: the same request when
# the state is unknown, current and ready. curl is run with exactly these options, -q first (the person's
# curl settings ignored), HTTPS only, 10 s and 1 MiB, the body to a file of its own (D3.2). The registry's
# request is U3's. Mutant: tests/mutants/T14a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0

for st in unknown current ready; do
  fresh
  case "$st" in
    unknown) stamp release v0.1.0 ;;
    current) stamp release v0.2.0; offer v0.2.0 ;;
    ready) stamp release v0.1.0; offer v0.2.0 ;;
  esac
  answer 200 "$W/cl"; : > "$STUB_LOG"
  same "$(upd | cut -f1)" "$st" "the state before the check: $st"
  same "$(upd --refresh --now | cut -f5):$(asks)" "fetched:1" "$st: one request"
  d="$STUB_CURL_DIR/requests/0001"
  same "$(cat "$d/method") $(cat "$d/url")" "GET $CHANGELOG" "$st: GET of release's CHANGELOG.md"
  same "$(cat "$d/headers")" "Host: raw.githubusercontent.com
User-Agent: curl/8.7.1
Accept: */*" "$st: exactly curl's own headers"
  [ -e "$d/body" ] && bad "$st: the request carried a body" || ok "$st: no body"
  same "$(grep -c '^curl ' "$STUB_LOG")" 1 "$st: curl run once"
  grep -qxE "curl -q --proto =https --tlsv1\.2 -sS --max-time 10 --max-filesize 1048576 -o $U/\.fetch\.[A-Za-z0-9]{6} -w %\{http_code\} $CHANGELOG" "$STUB_LOG" &&
    ok "$st: with exactly these options, -q first" || bad "$st: curl was run as: $(grep '^curl ' "$STUB_LOG")"
  cp "$d/method" "$W/method-$st"; cp "$d/url" "$W/url-$st"; cp "$d/headers" "$W/headers-$st"
done
same "$(cat "$W"/method-* "$W"/url-* "$W"/headers-* | sort | uniq -c | awk '{ print $1 }' | sort -u)" 3 \
  "the three requests are the same, whatever is waiting"
done_
