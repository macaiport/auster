# T96: installing an earlier version by its tag (B2: the line with refs/tags/v0.1.0, whose install.sh knows
# its version) reads the `withdraw` lines of the registry release holds now (v0.2.0 here), and refuses a
# build withdrawn since: with order 1 withdrawn it offers order 2, and with order 1 its only build it
# installs nothing. The stamp then says `tag`, which makes the Mac manual (D3.2), so that it is not told of
# later withdrawals (D3.8, the check's half: U1's here, U8's later). Mutant: tests/mutants/T96a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
same "$(sed -n 's/^AUSTER_SELF_VERSION=//p' "$ROOT/install.sh")" v0.1.0 "this install.sh is version v0.1.0's"
install_registry "$FX/registry-release.tsv" v0.2.0
printf 'withdraw\t%s\tsecurity\n' "$IB1" >> "$FX/registry-release.tsv"
install_tree "$FX/registry-release.tsv" "$COMMIT2"           # release: v0.2.0, order 1 withdrawn since
route_drop "$API/heads/release"
commit_route heads/release "$COMMIT2"
commit_route tags/v0.1.0 "$COMMIT"                            # the tag: v0.1.0's tree, which withdraws nothing
grep -q '^withdraw' "$FX/registry.tsv" && bad "the fixture: the tag's registry withdraws" || ok "the fixture: the tag's own registry withdraws nothing"

run_install $'no\nno\n' "$IR"
same "$RC" 1 "order 1 withdrawn since: exit 1 at the no"
says "This installs Auster v0.1.0, a named version: it is never offered updates." "it says the version is a named one, never offered updates"
says "Auster v0.1.0, commit $COMMIT." "it installs the tag's commit"
says "  Download    standin-b.gguf from Hugging Face ($REPO_B)" "it offers order 2: order 1 was withdrawn since"
same "$(requests | grep "$API" | cut -d' ' -f2 | tr '\n' ' ')" "$API/heads/release $API/tags/v0.1.0 " "it asked which commit release names, then the tag's"

install_registry "$FX/registry.tsv" v0.1.0 "$IB1"            # the tag's recipe: order 1 its only build
install_tree "$FX/registry.tsv" "$COMMIT"
before=$(snapshot "$H")
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 1 "its only build withdrawn since: exit 1"
says "None of the builds of recipe $IR can be installed" "it says no build can be installed"
same "$(snapshot "$H")" "$before" "and nothing was written"

install_registry "$FX/registry.tsv"
install_tree "$FX/registry.tsv" "$COMMIT"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "with order 2 left: installed"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB2" "serving names order 2"
same "$(cut -f1-4 "$DATA/_update/scripts")" "auster-record 1	tag	v0.1.0	$COMMIT" "the stamp says tag, the version and the tag's commit"
n=$(requests raw.githubusercontent.com | wc -l | tr -d ' ')
same "$(/bin/bash "$DATA/_update/updates.sh" --refresh --now | cut -f1,4,5)" "manual	tag	skipped" \
  "the deployed rule file: manual, the detail tag, and nothing fetched, with --now too (U1's half)"
same "$(requests raw.githubusercontent.com | wc -l | tr -d ' ')" "$n" "  ...no request to release's changelog"
done_
