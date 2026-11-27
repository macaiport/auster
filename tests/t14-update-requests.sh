# T14 (D3.3, D3.10): each check makes exactly two requests, GET of release's CHANGELOG.md and then GET of
# release's registry.tsv (U3), both at raw.githubusercontent.com, each carrying exactly the headers curl sends of
# itself (Host, User-Agent curl/<version>, Accept) and no body, whether or not anything is waiting: the same two
# when the state is unknown, current and ready, and when ready because a recipe has a build waiting with no newer
# version. curl is run with exactly these options, -q first (the person's curl settings ignored), HTTPS only,
# 10 s and 1 MiB, the body to a file of its own (D3.2). A model fetch, and its login, are U5's.
# Mutants: tests/mutants/T14a (the installed version added to the address) and T14b (the registry fetched only
# when a newer version shows).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0
changelog "$W/cl1" v0.1.0

for st in unknown current ready waiting; do
  fresh
  case "$st" in
    unknown) stamp release v0.1.0; answer 200 "$W/cl" ;;
    current) stamp release v0.2.0; offer v0.2.0; answer 200 "$W/cl" ;;
    ready) stamp release v0.1.0; offer v0.2.0; answer 200 "$W/cl" ;;
    waiting) known v0.1.0; mac_put 53084 $GB64; served $HH $B2 4 32768; answer 200 "$W/cl1" ;;   # order 1 waits
  esac
  : > "$STUB_LOG"
  w=$st x=; [ "$st" != waiting ] || { w=ready x=", a build waiting and no newer version"; }
  same "$(upd | cut -f1)" "$w" "the state before the check: $w$x"
  [ "$st" != waiting ] || same "$(upd | cut -f2,3)" "v0.1.0${TAB}v0.1.0" "  ...the scripts and the offer of one version"
  same "$(upd --refresh --now | cut -f5):$(asks)" "fetched:2" "$st: two requests"
  for n in 1 2; do
    d="$STUB_CURL_DIR/requests/000$n"
    if [ "$n" = 1 ]; then u=$CHANGELOG; else u=$REGISTRY; fi
    same "$(cat "$d/method") $(cat "$d/url")" "GET $u" "$st: request $n, GET of release's ${u##*/}"
    same "$(cat "$d/headers")" "Host: raw.githubusercontent.com
User-Agent: curl/8.7.1
Accept: */*" "$st: request $n, exactly curl's own headers"
    [ -e "$d/body" ] && bad "$st: request $n carried a body" || ok "$st: request $n, no body"
    grep -qxE "curl -q --proto =https --tlsv1\.2 -sS --max-time 10 --max-filesize 1048576 -o $U/\.fetch\.[A-Za-z0-9]{6} -w %\{http_code\} $u" "$STUB_LOG" &&
      ok "$st: request $n with exactly these options, -q first" || bad "$st: curl was run as: $(grep '^curl ' "$STUB_LOG")"
    cat "$d/method" "$d/url" "$d/headers" > "$W/request-$n-$st"
  done
  same "$(grep -c '^curl ' "$STUB_LOG")" 2 "$st: curl run twice"
done
for n in 1 2; do
  same "$(cat "$W"/request-$n-* | sort | uniq -c | awk '{ print $1 }' | sort -u)" 4 \
    "request $n is the same in the four states, whatever is waiting"
done
done_
