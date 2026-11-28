# T39 (U9; D3.9): the release gate, tools/release-gate, on a scratch git repo made here with an origin of its own (a
# bare repo in the test's folder), whose commits hold this tree's tools/, common/ and install.sh and a registry,
# assets and changelog made here. It fails, naming each question on a line of its own and nothing else, for: an
# untagged commit (and a tag naming another commit), a tag that is not the changelog's first heading (or a heading of
# another form, out of order, or a section whose changes do not open with a bold sentence), a version that is not
# newer than another v tag, a tag named `release` (here, on origin, or asked for), a registry version line that is
# not the tag, a released line changed, no origin/release without --first-release (and --first-release with one), a
# model whose publisher reports another size or hash or none, an engine archive whose bytes are not the registry's,
# install.sh's AUSTER_SELF_VERSION not the tag, an asset the commit does not hold though the working tree does, a
# new engine after the first release, origin that cannot be fetched, and a tag here that origin holds otherwise. It
# passes the good commit before it is tagged but for the tag alone, and after; it reads the commit, not the working
# tree. The publishers are the stub curl's routes: no request leaves the Mac.
# git: the bare PATH of tests/run.sh holds none (T98), so that nothing the household's Mac runs can call it. The gate
# is the development Mac's, so this file alone puts /usr/bin/git back, for the gate and for itself, with no system
# or global git settings.
# Mutants, one for each question: tests/mutants/T39a (the tag names the commit), T39b (no tag `release`), T39c (other
# v tags older), T39d (the first heading is the tag), T39e (every heading's form and order), T39f (the bold sentence),
# T39g (AUSTER_SELF_VERSION), T39h (the registry's version line, --tag), T39i (released lines, --release), T39j (no
# origin/release without --first-release), T39k (a model's hash), T39l (an engine's bytes), T39m (a new engine).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
stub_env
W=$(mktemp -d "${TMPDIR%/}/t39.XXXXXX")
mkdir "$W/git-bin" && ln -s /usr/bin/git "$W/git-bin/git"
PATH="$W/git-bin:$PATH"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid \
  GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
S="$W/repo" O="$W/origin.git" FX="$W/fx"
g() { git -C "$S" "$@"; }
gate() { "$S/tools/release-gate" "$@" > "$W/g" 2>&1; RC=$?; G=$(cat "$W/g"); }
gives() { same "$RC:$G" "$1" "$2"; }   # EXIT:OUTPUT LABEL
PASS="release-gate: every question passes: the tag"

# --- what the commits hold: this tree's programs, and a registry of the household's form (install_registry)
mkdir -p "$FX/assets"
printf 'You are the household assistant for a family. Answer briefly and plainly.\n' > "$FX/assets/household-system.txt"
printf '{%%- for m in messages %%}{{ m.content }}{%%- endfor %%}\n' > "$FX/assets/order-1.jinja"
printf '{%%- for m in messages %%}[{{ m.role }}] {{ m.content }}{%%- endfor %%}\n' > "$FX/assets/order-2.jinja"
cp "$TESTS/fixtures/recipe-test/household-test.json" "$FX/assets/household-test.json"
seq 1 2000 | sed 's/^/the engine archive, line /' | gzip -n > "$FX/engine.tar.gz"
cp "$FX/engine.tar.gz" "$FX/engine-other.tar.gz"; printf X | dd of="$FX/engine-other.tar.gz" bs=1 seek=100 conv=notrunc 2> /dev/null
seq 1 1000 | sed 's/^/a newer engine, line /' | gzip -n > "$FX/engine2.tar.gz"
T1=$(shasum -a 256 < "$FX/assets/order-1.jinja" | cut -c1-64)
T2=$(shasum -a 256 < "$FX/assets/order-2.jinja" | cut -c1-64)
ES=$(shasum -a 256 < "$FX/engine.tar.gz" | cut -c1-64)
EZ=$(stat -f %z "$FX/engine.tar.gz")
changelog() { # VERSION... -> CHANGELOG.md with a section for each version, newest first, each of one bold change
  local v
  { printf '# Changelog\n\nOne section per release, newest first.\n'
    for v in "$@"; do printf '\n## %s (2026-12-01)\n\n**What %s brings.** A household notices it.\n' "$v" "$v"; done
  } > "$S/CHANGELOG.md"
}
selfv() { sed -i '' "s/^AUSTER_SELF_VERSION=.*/AUSTER_SELF_VERSION=$1/" "$S/install.sh"; }
version() { # V -> the commit's registry, changelog and install.sh all at version V (the registry's lines kept)
  sed -i '' "1s/.*/auster-registry	1	$1/" "$S/registry.tsv"; changelog "$1" v0.1.0; selfv "$1"
}
routes() { # the publishers as the registry names them
  route_drop "$URL_A"; route_drop "$URL_B"; route_drop "$ENGINE_URL"; route_drop "$ENGINE_CDN"
  curl_route HEAD "$URL_A" 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$SA\""
  curl_route HEAD "$URL_B" 302 - "Location: https://cdn.example.test/b" "x-linked-size: 2040" "x-linked-etag: \"$SB\""
  curl_route GET "$ENGINE_URL" 302 - "Location: $ENGINE_CDN"
  curl_route GET "$ENGINE_CDN" 200 "$FX/engine.tar.gz"
}
routes

git init -q --bare "$O"
git init -q -b main "$S"
g remote add origin "$O"
cp -R "$ROOT/tools" "$ROOT/common" "$S/"; cp "$ROOT/install.sh" "$S/"; cp -R "$FX/assets" "$S/assets"
install_registry "$S/registry.tsv" v0.1.0
changelog v0.1.0; selfv v0.1.0
g add -A && g commit -qm "v0.1.0" && g push -q origin main
BASE=$(g rev-parse HEAD)

# --- the first release: before the tag, the tag is the one failure; after it, the gate passes
rm -rf "$STUB_CURL_DIR/requests"
gate v0.1.0 --first-release
gives "1:there is no tag v0.1.0 here: when every other question passes, make it with git tag -a v0.1.0 -m v0.1.0 $BASE and run the gate again" \
  "the good commit, not yet tagged: the tag is the one failure"
same "$(requests huggingface.co)" "HEAD $URL_A
HEAD $URL_B" "  ...it asked Hugging Face once for each model, with a HEAD"
same "$(requests | grep -v huggingface.co)" "GET $ENGINE_URL
GET $ENGINE_CDN" "  ...and fetched the engine's archive from its publisher, through the redirect"
g tag -a v0.1.0 -m v0.1.0
gate v0.1.0 --first-release; gives "0:$PASS v0.1.0 names $BASE, and release may move to it." "tagged: the gate passes, and says so"
gate v0.1.0
gives "1:origin has no release branch, so no released line can be compared: if this is the first release, say so with --first-release" \
  "no origin/release and no --first-release: fails"

# --- an untagged commit, and the commit read rather than the working tree
printf 'more\n' > "$S/NOTES.md"; g add -A; g commit -qm later; LATER=$(g rev-parse HEAD)
gate v0.1.0 --first-release; gives "1:the tag v0.1.0 names commit $BASE, not $LATER" "HEAD past the tag: the tag names another commit"
printf '# Changelog\n\n## v9.9.9 (soon)\n\nnot bold\n' > "$S/CHANGELOG.md"; selfv v9.9.9
gate v0.1.0 --first-release --commit v0.1.0
gives "0:$PASS v0.1.0 names $BASE, and release may move to it." "--commit v0.1.0, with a broken changelog and install.sh in the working tree only: passes"
g reset -q --hard "$BASE"

# --- the tag's name
g tag release
gate v0.1.0 --first-release; gives "1:a tag is named release, here or on origin, and no tag ever is (D3.9): git would read release two ways" "a tag named release here: fails"
g tag -d release > /dev/null
git -C "$O" tag release main
gate v0.1.0 --first-release; gives "1:a tag is named release, here or on origin, and no tag ever is (D3.9): git would read release two ways" "a tag named release on origin only: fails"
git -C "$O" tag -d release > /dev/null; g tag -d release > /dev/null
gate release --first-release; gives "1:the tag is named release, and no tag ever is (D3.9)" "asked to gate a tag named release: fails"
gate v1.2 --first-release; gives "1:the tag v1.2 is not of the form v<a>.<b>.<c>" "a tag not of the form v<a>.<b>.<c>: fails"
gate; same "$RC" 2 "no tag: usage, exit 2"

# --- a version that is not newer than another v tag
g tag v0.2.0 "$BASE"
gate v0.1.0 --first-release; gives "1:the tag v0.2.0 is not older than v0.1.0" "another tag, v0.2.0: fails"
g tag -d v0.2.0 > /dev/null; g tag v0.0.9 "$BASE"
gate v0.1.0 --first-release; gives "0:$PASS v0.1.0 names $BASE, and release may move to it." "another tag, v0.0.9, older: passes"
g tag -d v0.0.9 > /dev/null

# --- the changelog, each case a commit of its own with the tag moved to it
variant() { # COMMAND... -> a commit on BASE that COMMAND changed, with v0.1.0 moved to it; V its sha
  g reset -q --hard "$BASE"; "$@"; g add -A; g commit -qm variant; V=$(g rev-parse HEAD); g tag -f -a v0.1.0 -m v0.1.0 > /dev/null
}
cl() { printf '%b' "$1" > "$S/CHANGELOG.md"; }
H='# Changelog\n\n'
variant cl "$H## Unreleased\n\n**Next.** Soon.\n\n## v0.1.0 (2026-12-01)\n\n**First.** It installs.\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 3: the first heading is not `## v0.1.0 (YYYY-MM-DD)`' "an Unreleased heading above the tag's: fails"
variant cl "$H## v0.1.0 (2026-12-1)\n\n**First.** It installs.\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 3: the first heading is not `## v0.1.0 (YYYY-MM-DD)`' "a date of another form: fails"
variant cl "$H## v0.1.0\n\n**First.** It installs.\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 3: the first heading is not `## v0.1.0 (YYYY-MM-DD)`
CHANGELOG.md: an installed Mac reads no version from it (common/updates.sh --version-of), not the tag v0.1.0' \
  "a heading with no date: fails, and a Mac would read no version"
variant cl "$H## v0.0.9 (2026-12-01)\n\n**First.** It installs.\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 3: the first heading names v0.0.9, not the tag v0.1.0
CHANGELOG.md: an installed Mac reads v0.0.9 from it (common/updates.sh --version-of), not the tag v0.1.0' \
  "the first heading is another version: fails, and a Mac would read that one"
variant cl "$H## v0.1.0 (2026-12-01)\n\n**First.** It installs.\n\n## v0.2.0 (2026-11-01)\n\n**Old.** Gone.\n\n## Old notes\n\n## v0.0.1 (2026-10-01)\n\n**Older.** Gone.\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 7: v0.2.0 is not older than v0.1.0, the heading above it
CHANGELOG.md line 11: a heading not of the form `## v<a>.<b>.<c> (YYYY-MM-DD)`' "a lower heading out of order, and one of another form: fails, naming each"
variant cl "$H## v0.1.0 (2026-12-01)\n\n**First.** It installs,\nand this line goes on.\n\nThe second change.\n\n### Fixed\n\n- **A fix!** It works.\n  an indented line\n- a fix with no bold\n1. **A numbered one?** Yes.\n* **Bold with no full stop**\n\n\`\`\`\nnot bold, in a fence\n\`\`\`\n\n## v0.0.1 (2026-11-01)\n\nnot bold, in an older section\n"
gate v0.1.0 --first-release; gives '1:CHANGELOG.md line 8: a change in the section of v0.1.0 that does not open with one bold sentence (**...**)
CHANGELOG.md line 14: a change in the section of v0.1.0 that does not open with one bold sentence (**...**)
CHANGELOG.md line 16: a change in the section of v0.1.0 that does not open with one bold sentence (**...**)' \
  "changes that do not open with a bold sentence: fails, naming each and only those"
variant cl "$H## v0.1.0 (2026-12-01)\n\n## v0.0.1 (2026-11-01)\n\n**Older.** Gone.\n"
gate v0.1.0 --first-release; gives "1:CHANGELOG.md: the section of v0.1.0 holds no change" "an empty section: fails"

# --- install.sh, the registry and the assets
variant selfv v0.0.9
gate v0.1.0 --first-release; gives "1:install.sh: AUSTER_SELF_VERSION is v0.0.9, not the tag v0.1.0" "AUSTER_SELF_VERSION not the tag: fails"
variant eval 'printf "AUSTER_SELF_VERSION=v0.1.0\n" >> "$S/install.sh"'
gate v0.1.0 --first-release; gives "1:install.sh: AUSTER_SELF_VERSION is set on 2 lines, not one" "AUSTER_SELF_VERSION set twice: fails"
variant sed -i '' '1s/.*/auster-registry	1	v0.1.1/' "$S/registry.tsv"
gate v0.1.0 --first-release; gives "1:registry.tsv: line 1: the version v0.1.1 is not the tag v0.1.0" "a registry version line that is not the tag: fails"
g reset -q --hard "$BASE"; g rm -q --cached assets/order-2.jinja; g commit -qm "no template for order 2"
g tag -f -a v0.1.0 -m v0.1.0 > /dev/null
[ -f "$S/assets/order-2.jinja" ] && ok "  (order 2's template is still in the working tree)" || bad "  (order 2's template went from the working tree)"
gate v0.1.0 --first-release; gives "1:registry.tsv: build $IB2: its template $T2 is not in assets" "an asset in the working tree but not in the commit: fails"
g reset -q --hard "$BASE"; g tag -f -a v0.1.0 -m v0.1.0 > /dev/null

# --- the publishers
route_drop "$URL_A"; curl_route HEAD "$URL_A" 302 - "x-linked-size: 3400" "x-linked-etag: \"$T1\""
gate v0.1.0 --first-release; gives "1:model $IMA (standin-a.gguf): Hugging Face reports the sha256 $T1, not the registry's $SA" "a model whose publisher reports another sha256: fails"
route_drop "$URL_A"; curl_route HEAD "$URL_A" 302 - "x-linked-size: 3401" "x-linked-etag: \"$SA\""
gate v0.1.0 --first-release; gives "1:model $IMA (standin-a.gguf): Hugging Face reports the size 3401, not the registry's 3400" "another size: fails"
routes; route_drop "$URL_B"; curl_route HEAD "$URL_B" 302 -
gate v0.1.0 --first-release; gives "1:model $IMB (standin-b.gguf): Hugging Face's answer carries no size (x-linked-size)
model $IMB (standin-b.gguf): Hugging Face's answer carries no sha256 (x-linked-etag)" "a model whose publisher reports neither: fails here, though a Mac lets it pass"
route_drop "$URL_B"; curl_route HEAD "$URL_B" 404 -
gate v0.1.0 --first-release; gives "1:model $IMB (standin-b.gguf): Hugging Face no longer offers it (404)" "a model gone from its publisher: fails"
routes; route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 200 "$FX/engine-other.tar.gz"
same "$(stat -f %z "$FX/engine-other.tar.gz")" "$EZ" "  (the other archive is the same size)"
gate v0.1.0 --first-release
gives "1:engine $IE (llama-b12359-bin-macos-arm64.tar.gz): the publisher's archive has the sha256 $(shasum -a 256 < "$FX/engine-other.tar.gz" | cut -c1-64), not the registry's $ES" \
  "an engine archive of the same size and other bytes: fails"
route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 200 "$FX/engine2.tar.gz"
gate v0.1.0 --first-release
gives "1:engine $IE (llama-b12359-bin-macos-arm64.tar.gz): the publisher's archive is $(stat -f %z "$FX/engine2.tar.gz") bytes, not the registry's $EZ" "a shorter archive: fails"
route_drop "$ENGINE_CDN"; curl_route GET "$ENGINE_CDN" 404 -
gate v0.1.0 --first-release
gives "1:engine $IE (llama-b12359-bin-macos-arm64.tar.gz): its archive could not be fetched from its publisher (curl exit 0, answer 404)" "an archive gone: fails"
routes
g remote set-url origin "$W/nowhere.git"
gate v0.1.0 --first-release; gives "1:origin could not be fetched, so what it holds is not known" "origin that cannot be fetched: fails"
g remote set-url origin "$O"

# --- the first release published; the next one is compared with it
g push -q origin main v0.1.0 && g push -q origin "v0.1.0^{commit}:refs/heads/release"
g tag -f -a v0.1.0 -m moved "$LATER" > /dev/null
gate v0.1.0; gives "1:origin's tags could not be fetched: a tag here may name another commit than origin's tag of that name" "a tag here that origin holds otherwise: fails"
g tag -d v0.1.0 > /dev/null; g fetch -q origin 'refs/tags/*:refs/tags/*'
same "$(g rev-parse 'v0.1.0^{commit}')" "$BASE" "  (origin's tag fetched back)"
next() { # [COMMAND...] -> a commit on BASE at v0.1.1 that COMMAND also changed, tagged v0.1.1; N its sha
  g reset -q --hard "$BASE"; version v0.1.1; [ $# -eq 0 ] || "$@"; g add -A; g commit -qm v0.1.1; N=$(g rev-parse HEAD)
  g tag -f -a v0.1.1 -m v0.1.1 > /dev/null
}
next
gate v0.1.1; gives "0:$PASS v0.1.1 names $N, and release may move to it." "v0.1.1 after v0.1.0, every released line kept: passes"
gate v0.1.1 --first-release; gives "1:--first-release was given, but origin has a release branch" "--first-release with an origin/release: fails"
next sed -i '' "s/^recipe	$IR	household	/recipe	$IR	household-renamed	/" "$S/registry.tsv"
gate v0.1.1; gives "1:registry.tsv: line 7 of the release (recipe $IR) is missing, changed or moved" "a released line changed in place: fails"
newengine() {
  local es ez b1
  es=$(shasum -a 256 < "$FX/engine2.tar.gz" | cut -c1-64); ez=$(stat -f %z "$FX/engine2.tar.gz")
  b1=$(grep "^build	$IB1	" "$S/registry.tsv")
  printf 'engine\te3umyg6om6bfo\tmacos-arm64\tb12400\tllama-b12400-bin-macos-arm64.tar.gz\t%s\t%s\t14\n' "$ez" "$es" >> "$S/registry.tsv"
  printf '%s\n' "$b1" | sed "s/^build	$IB1	$IE	/build	bv4tbuqiaa3al	e3umyg6om6bfo	/" >> "$S/registry.tsv"
  printf 'order\t%s\tbv4tbuqiaa3al\t%s\t%s\n' "$IR" "$IB1" "$IB2" >> "$S/registry.tsv"
}
E2URL=https://github.com/ggml-org/llama.cpp/releases/download/b12400/llama-b12400-bin-macos-arm64.tar.gz
curl_route GET "$E2URL" 200 "$FX/engine2.tar.gz"
next newengine
gate v0.1.1
gives "1:engine e3umyg6om6bfo (llama.cpp b12400): no released build used it, so its --help must be compared with the last released engine's and each new or changed option recorded in the recipe's findings file before the tag (D3.9); this gate cannot yet see that it was, so it fails" \
  "a build on an engine no released build used: fails, until the owner decides how the --help comparison is shown"
same "$(requests github.com | grep -c b12400)" 1 "  ...after its archive was asked for and matched"
g tag -d v0.1.1 > /dev/null
g reset -q --hard "$BASE"; version v0.0.9; g add -A; g commit -qm v0.0.9; g tag -a v0.0.9 -m v0.0.9
gate v0.0.9; gives '1:the tag v0.1.0 is not older than v0.0.9
CHANGELOG.md line 9: v0.1.0 is not older than v0.0.9, the heading above it
registry.tsv: line 1: the version v0.0.9 is not newer than the release'"'"'s v0.1.0' "v0.0.9 after v0.1.0: fails, by the tags, the changelog and the registry"
done_
