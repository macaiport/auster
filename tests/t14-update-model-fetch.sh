# T14, the model fetch (U5; D3.6 steps 1 and 3, D3.10): a model fetch carries no login. On a Mac serving order 2 with
# order 1 waiting, an update answered yes asks Hugging Face about the model (HEAD) and fetches it, from the address that
# names its commit and then its CDN: every one of those requests carries only the headers curl sends of itself (Host,
# User-Agent curl/<version>, Accept), and no body, and every curl that sends them is run with -q first, so that the
# person's own curl settings, a saved login among them, are ignored.
# Mutants: tests/mutants/T14c (the person's curl settings read for the download), T14d (a login sent with the download).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/
n=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "an update answered yes: exit 3, where U5's last part will test the build"
asked= extra=
for d in "$STUB_CURL_DIR"/requests/*; do
  case "$(cat "$d/url")" in *huggingface.co/*|*cdn.example.test/*) ;; *) continue ;; esac
  asked+="$(cat "$d/method") "
  h=$(cut -d: -f1 "$d/headers" | sort | tr '\n' ' ')
  [ "$h" = "Accept Host User-Agent " ] && [ ! -e "$d/body" ] || extra+=" $(cat "$d/url"): $h"
done
same "$asked" "HEAD HEAD GET GET " "the model's host was asked twice (HEAD) and the model fetched from it and its CDN"
same "$extra" "" "  ...each request with only Host, User-Agent and Accept, and no body: no login"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep '^curl .*huggingface\.co/' | grep -vc '^curl -q ')" 0 \
  "  ...each curl that asked Hugging Face run with -q first: the person's curl settings ignored"
done_
