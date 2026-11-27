# T63: the commit is fixed (B3 step 2). GitHub's API (asked for the bare sha of heads/release) says commit X;
# the tree is fetched by X's own address; an archive whose pax header records another commit is refused
# though its folder is named for X; one that records X is used, and the stamp names X.
# Mutants: tests/mutants/T63a and T63b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
before=$(snapshot "$H")
mv "$FX/tree-$COMMIT.tar.gz" "$FX/tree-good.tar.gz"
install_tree "$FX/registry.tsv" "$COMMIT" "$COMMIT2" "auster-$COMMIT"   # records another commit
cp "$FX/tree-$COMMIT.tar.gz" "$FX/tree-other.tar.gz"
gzip -dc "$FX/tree-other.tar.gz" | head -c 564 | tail -c 52 > "$W/rec"
same "$(cat "$W/rec")" "52 comment=$COMMIT2" "the fixture: its pax header records the other commit"
same "$(gzip -dc "$FX/tree-other.tar.gz" | tar -tf - | head -n 1)" "auster-$COMMIT/" "the fixture: its folder is named for X"

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 1 "an archive recording another commit: exit 1"
says "does not record commit $COMMIT, the one its API named" "it says the archive is not the commit the API named"
same "$(requests | tr '\n' '|')" "GET $API/heads/release|GET $CODELOAD/$COMMIT|" "it asked the API, then fetched the tree by X's address, and nothing else"
same "$(snapshot "$H")" "$before" "it wrote nothing in the home folder"
first=$(ls -d "$STUB_CURL_DIR"/requests/* | head -n 1)
grep -qx 'Accept: application/vnd.github.sha' "$first/headers" && ok "the API was asked for the bare sha" || bad "the API request's headers: $(cat "$first/headers")"
grep -qi '^user-agent: curl/' "$first/headers" && ok "the API request names curl, and nothing of Auster's" || bad "user agent: $(cat "$first/headers")"

cp "$FX/tree-good.tar.gz" "$FX/tree-$COMMIT.tar.gz"   # the route's body: now an archive that records X
rm -rf "$STUB_CURL_DIR/requests"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "an archive recording X: installed"
same "$(requests | head -n 2 | tr '\n' '|')" "GET $API/heads/release|GET $CODELOAD/$COMMIT|" "the API first, then the tree by X's address"
says "Auster v0.1.0, commit $COMMIT." "it names the commit it fixed"
same "$(cut -f2,4 "$DATA/_update/scripts")" "release	$COMMIT" "the stamp names release and X"
done_
