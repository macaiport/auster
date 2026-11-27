# T29 (U5; D3.6 step 1, B3 step 7): the publisher is asked about a file store/ does not hold, with a HEAD at the address
# that names its commit, before the question. On a Mac serving order 2 with order 1 waiting (model A not in store/), a
# publisher that reports a sha256 other than the registry's (its CDN then serving another file), one that reports another
# size, and one that answers 404 each pass the recipe over before the question, in one sentence, and download nothing:
# exit 3, no GET to Hugging Face or its CDN, no file in store/ for it, serving as it was. A publisher that reports neither
# a size nor a hash is not a failure: the question is asked, and a yes fetches the model.
# Mutant: tests/mutants/T29a (skip the request before the download).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/
OTHER=07081b3b4c85550947564d52caeb8561eadba7105e9c10192b731580e69674a3   # the wrong stand-in's sha256
s0=$(cat "$DATA/builds/$IR/serving")
head_route() { # HEADER... -> the publisher's HEAD for model A answers with these headers, its CDN with the wrong stand-in
  route_drop "$URL_A"; route_drop https://cdn.example.test/a
  curl_route HEAD "$URL_A" "$@"
  curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
  curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a-wrong.gguf"
}
nothing() { # LABEL
  same "$(requests | grep -E 'huggingface|cdn\.example' | tr '\n' ' ')" "HEAD $URL_A " "  ...only the HEAD was sent: nothing downloaded"
  [ -e "$DATA/store/$SA" ] || [ -e "$DATA/store/$SA.part" ] && bad "  ...a file for model A in store/" || ok "  ...no file for model A in store/"
  says_not "an update is waiting" "  ...no question asked"
  same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"
}

head_route 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$OTHER\""
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "the publisher reports another sha256: exit 3"
says "The publisher reports a sha256 for standin-a.gguf other than the registry's, so nothing was fetched. The recipe household is not updated: it keeps serving build $IB2." \
  "  ...it says so in one sentence"
nothing

head_route 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3401" "x-linked-etag: \"$SA\""
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "the publisher reports another size: exit 3"
says "The publisher reports a size for standin-a.gguf other than the registry's, so nothing was fetched." "  ...it says so"
nothing

head_route 404 -
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "the publisher answers 404: exit 3"
says "The publisher no longer offers standin-a.gguf, so nothing was fetched." "  ...it says the publisher no longer offers the file"
nothing

head_route 302 - "Location: https://cdn.example.test/a"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a.gguf"
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "a publisher that reports no size or hash: the update goes on, and ends where U5's last part will test the build (exit 3)"
says "The recipe household: an update is waiting." "  ...the question was asked"
same "$(shasum -a 256 < "$DATA/store/$SA" 2>/dev/null | cut -c1-64)" "$SA" "  ...and the yes fetched the model"
done_
