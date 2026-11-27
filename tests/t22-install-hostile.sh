# T22, the installer's half (V5; the reader's half is t22-registry-hostile.sh), which makes its last clause
# real: the install run against hostile values builds no request and makes no file from them. Once with
# hostile.tsv's five hostile lines (a repository ../mistralai, a file -rf.gguf, a file $(touch f).gguf, a
# sha256 holding z, a size 17e6) beside the recipe's own, which nothing names: they are passed over and the
# install goes through on order 1. Once with order 1's own model line naming ../mistralai: that line is
# passed over, and with it the build and the order line that name it (A3), so the recipe cannot be read
# and nothing is installed. Mutant: tests/mutants/T22a (the reader's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir "$W/cwd" "$W/tmp"
cd "$W/cwd" || exit 1
hostile_requests() { requests | grep -E '\.\./|-rf|touch|zz594d|17e6|b1240[01]'; }

cp "$FX/registry.tsv" "$W/hostile.tsv"
tail -n +9 "$TESTS/fixtures/registry/hostile.tsv" >> "$W/hostile.tsv"
install_tree "$W/hostile.tsv"
TMPDIR="$W/tmp/" run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "hostile lines nothing names: installed, from the lines that were read"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB1" "order 1 serves"
same "$(hostile_requests)" "" "no request was built from a hostile value"
same "$(find "$W/cwd" "$W/tmp" "$H" -name f -print)" "" "no file f, where it ran, in TMPDIR or in the home folder"

install_cleanup; rm -rf "$DATA" "$H/Library/LaunchAgents"/* "$STUB_LAUNCHCTL_DIR"/loaded/* "$STUB_CURL_DIR/requests"
before=$(snapshot "$H")
sed "s|	$REPO_A	|	../mistralai	|" "$FX/registry.tsv" > "$W/hostile.tsv"
same "$(grep -c '\.\./mistralai' "$W/hostile.tsv")" 1 "the fixture: order 1's model line names ../mistralai"
install_tree "$W/hostile.tsv"
TMPDIR="$W/tmp/" run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 1 "order 1's model hostile: exit 1"
says "Recipe $IR cannot be read from this version's registry, so nothing was installed." "it says the recipe cannot be read"
same "$(hostile_requests)" "" "no request was built from the hostile value"
same "$(find "$W/cwd" "$W/tmp" "$H" -name f -print)" "" "no file f"
same "$(snapshot "$H")" "$before" "nothing written"
done_
