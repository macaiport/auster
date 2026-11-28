# T138 (the conventions' audit, 2026-11-28; docs/conventions.md section 2, "Plain words" and "Fixed sentences"): what a
# fetch came to is said in plain words, never as curl's exit code, and the HTTP code only once it is matched as one. Each
# fetch of a first install is made to fail, the stub curl giving a code where it can (503, 404) and, through its
# X-Stub-Code directive, a code that is no number ("2OO"), as no real curl gives: the installer's ask for release's
# commit (503, a code that is no number, no answer in time); the engine fetched at step 4 (404, a code that is no
# number); the publisher's HEAD before the model (503, a code that is no number); the model's download (cut short after
# 200, a code that is no number). Each says its fixed sentence, with the code where it is one; none says "curl exit", and
# none prints the code that is no number.
# Mutants: tests/mutants/T138a (install.sh takes any code), T138b (au_fetch_said takes any code), T138c (the publisher's
# code taken unmatched).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
jargon() { # LABEL -> neither curl's exit code nor the code that is no number in what the run printed
  grep -q 'curl exit' "$W/out" && bad "$1: it says curl exit: $(cat "$W/out")" || ok "$1: no curl exit"
  grep -q '2OO' "$W/out" && bad "$1: it prints the code that is no number" || ok "$1: the code that is no number not printed"
}

# --- install.sh: release's commit, from GitHub's API
route_drop "$API/heads/release"; curl_route GET "$API/heads/release" 503 -
run_install '' "$IR"
same "$RC" 1 "the API answers 503: exit 1"
says "GitHub answered 503 for the release of Auster, so nothing was installed. Try again in a few minutes." "  ...it gives the code"
jargon "the API answers 503"
route_drop "$API/heads/release"; curl_route GET "$API/heads/release" 200 "$FX/sha-$COMMIT" "X-Stub-Code: 2OO"
run_install '' "$IR"
same "$RC" 1 "the API's code is no number: exit 1"
says "GitHub gave no answer Auster can read for the release of Auster, so nothing was installed." "  ...it says it could not read one"
jargon "the API's code is no number"
route_drop "$API/heads/release"; curl_route GET "$API/heads/release" exit:28 -
run_install '' "$IR"
same "$RC" 1 "the API gives no answer in time: exit 1"
says "GitHub did not give the release of Auster in time, so nothing was installed." "  ...it says so"
jargon "no answer in time"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT"

# --- the driver: the engine fetched at step 4, to measure the Mac
route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 404 -
run_install $'no\nno\n' "$IR"
same "$RC" 1 "the engine's address answers 404: exit 1"
says "The engine could not be fetched from GitHub (it answered 404). Check the network, then paste the line again." "  ...it gives the code"
jargon "the engine: 404"
route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 200 "$FX/engine.tar.gz" "X-Stub-Code: 2OO"
run_install $'no\nno\n' "$IR"
same "$RC" 1 "the engine's code is no number: exit 1"
says "The engine could not be fetched from GitHub (it gave no answer Auster can read)." "  ...it says it could not read one"
jargon "the engine's code is no number"
route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 200 "$FX/engine.tar.gz"

# --- step 7: the publisher asked first, then the model fetched (after the yes, so each stops with exit 5)
route_drop "$URL_A"
curl_route HEAD "$URL_A" 503 -
curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "the publisher answers its HEAD with 503: exit 5"
says "Hugging Face answered 503 when asked about standin-a.gguf, so it was not fetched." "  ...it gives the code"
jargon "the HEAD: 503"
rm -rf "$DATA"
route_drop "$URL_A"
curl_route HEAD "$URL_A" 302 - "Location: https://cdn.example.test/a" "X-Stub-Code: 2OO"
curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "the HEAD's code is no number: exit 5"
says "Hugging Face gave no answer Auster can read when asked about standin-a.gguf, so it was not fetched." "  ...it says it could not read one"
jargon "the HEAD's code is no number"
rm -rf "$DATA"
route_drop "$URL_A"
curl_route HEAD "$URL_A" 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$SA\""
curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a.gguf" "X-Stub-Code: 2OO"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "the model's code is no number: exit 5"
says "The model's download stopped (it gave no answer Auster can read) at 3,400 bytes of 3,400 bytes." "  ...it says it could not read one"
jargon "the model's code is no number"
rm -rf "$DATA"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a exit:56:1000 "$FX/models/standin-a.gguf"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 5 "the model's download cut short: exit 5"
says "The model's download stopped (it answered 200, then the connection was cut) at 1,000 bytes of 3,400 bytes." "  ...it says where, and why, in plain words"
jargon "the model cut short"
done_
