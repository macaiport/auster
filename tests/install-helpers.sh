# Sourced by the installer's tests (V5: T26, T61 to T64, T66 to T69, T92, T96, T97, T101) after lib.sh and
# helpers.sh. It makes at run time what the bootstrap (install.sh) and the driver (common/driver.sh) fetch,
# and the stub curl's routes to it:
#   - the tree of a commit as codeload.github.com serves it: install.sh, common/ and tools/ from $ROOT (the
#     mutant's copy under --mutants), with an assets/ folder and a registry.tsv made here, in one folder
#     of a gzipped tar whose first header is a pax global header recording the commit (tree_archive);
#   - an engine archive holding the stub engine (tests/helpers.sh engine_program) as llama-stub/llama-server,
#     beside a library file and a link to it;
#   - the model stand-ins of tests/helpers.sh, at Hugging Face addresses that name their commits;
#   - a registry of the household recipe's form naming them, with A6's figures (install_registry);
#   - release's CHANGELOG.md answering 404, as it does while there is no release branch, for the deployed
#     updates.sh that the check job runs (U1); a test that wants an answer drops the route (route_drop).
# The ids below are fixed here and never minted again.

IR=rylaqjysaozx5     # the recipe (household, A6's form)
IR2=rsb5yknee42is    # a second recipe (T101)
IE=ekh5dlv2pitgi     # the engine: build b12359's names, the stub engine inside
IMA=mcpi7jzfupkvf    # model A: stand-in A, endorsed (A6's Mistral Small 4)
IMB=mckwbcvvqyyoz    # model B: stand-in B, publisher (A6's Magistral Small)
IB1=bl6w3otlblgri    # order 1: model A with A6's order-1 figures
IB2=b4sufrdvajcgm    # order 2: model B with A6's order-2 figures
IB3=byr7wfkewza3o    # the second recipe's build
COMMIT=ba9862dbf058e4d3219a17b9f9e21780999d7a7a
COMMIT2=0c1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
API=https://api.github.com/repos/macaiport/auster/commits
CODELOAD=https://codeload.github.com/macaiport/auster/tar.gz
CHANGELOG=https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/CHANGELOG.md   # updates.sh's fetch
ENGINE_URL=https://github.com/ggml-org/llama.cpp/releases/download/b12359/llama-b12359-bin-macos-arm64.tar.gz
ENGINE_CDN=https://objects.example.test/llama-engine
REPO_A=unsloth/Mistral-Small-4-119B-2603-GGUF COMMIT_A=bd93c721735aa32c035c0f19e738cb3371fd56ff
REPO_B=mistralai/Magistral-Small-2509-GGUF COMMIT_B=429b90d8a8f0037241db6fab46a20b0f90859b03
URL_A=https://huggingface.co/$REPO_A/resolve/$COMMIT_A/standin-a.gguf
URL_B=https://huggingface.co/$REPO_B/resolve/$COMMIT_B/standin-b.gguf
SA=ab0f65eb5bf514fb809bbd19bffccfb65766c77e480d1651b6f35cc3c17135d7   # stand-in A (tests/helpers.sh)
SB=e5cb32f318ff6f9b2ff9ae5762be574abe6c3bccfedfe76a15d51ecdfac86590   # stand-in B
DATA_REL="Library/Application Support/Auster"

install_env() { # -> W, a work folder; H, a home from make_home (a space, an apostrophe and &); FX, the
  # fixtures, with routes to them; the stub engine set to list b12359's devices and pass the recipe's test;
  # launchd simulated for the engine job (launchd_hook); the disk figures by their test variables
  stub_env
  trap install_cleanup EXIT
  W=$(mktemp -d "${TMPDIR%/}/install.XXXXXX")
  H=$(make_home "$W" "$@")
  DATA="$H/$DATA_REL"
  FX="$W/fx"
  mkdir -p "$FX/assets" "$FX/engine-src"
  model_standins "$FX/models" > /dev/null || return 1
  engine_program "$FX/engine-src/llama-stub"
  printf 'a library the engine loads\n' > "$FX/engine-src/llama-stub/libstub.0.dylib"
  ln -s libstub.0.dylib "$FX/engine-src/llama-stub/libstub.dylib"
  (cd "$FX/engine-src" && tar -czf "$FX/engine.tar.gz" llama-stub)
  printf 'You are the household assistant for a family. Answer briefly and plainly.\n' > "$FX/assets/household-system.txt"
  printf '{%%- for m in messages %%}{{ m.content }}{%%- endfor %%}\n' > "$FX/assets/order-1.jinja"
  printf '{%%- for m in messages %%}[{{ m.role }}] {{ m.content }}{%%- endfor %%}\n' > "$FX/assets/order-2.jinja"
  cp "$TESTS/fixtures/recipe-test/household-test.json" "$FX/assets/household-test.json"
  install_registry "$FX/registry.tsv"
  install_tree "$FX/registry.tsv"
  commit_route heads/release "$COMMIT"
  curl_route GET "$CHANGELOG" 404 -   # as GitHub answers while there is no release branch (D3.9)
  curl_route GET "$ENGINE_URL" 302 - "Location: $ENGINE_CDN"
  curl_route GET "$ENGINE_CDN" 200 "$FX/engine.tar.gz"
  curl_route HEAD "$URL_A" 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$SA\""
  curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
  curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a.gguf"
  curl_route HEAD "$URL_B" 302 - "Location: https://cdn.example.test/b" "x-linked-size: 2040" "x-linked-etag: \"$SB\""
  curl_route GET "$URL_B" 302 - "Location: https://cdn.example.test/b"
  curl_route GET https://cdn.example.test/b 200 "$FX/models/standin-b.gguf"
  awk -F'\t' '{ print $2 "\t" $3 "\t36.9\t0" }' "$TESTS/fixtures/recipe-test/answers.tsv" > "$FX/answers-good"
  printf 'Count from 1 to\t1\\n2\\n3\t36.9\t0\n' >> "$FX/answers-good"
  awk -F'\t' '{ print $2 "\t" $4 "\t36.9\t0" }' "$TESTS/fixtures/recipe-test/answers.tsv" > "$FX/answers-bad"
  printf 'Count from 1 to\t1\\n2\\n3\t36.9\t0\n' >> "$FX/answers-bad"
  engine_set '*' behaviour ok
  engine_set '*' list-devices b12359
  engine_set '*' answers "$FX/answers-good"
  launchd_hook
  export STUB_OPENSSL_RAND_COUNTER="$W/rand"
  export AU_SCREEN="$W/screen"   # V7: the terminal the QR code is drawn on (common/auster), never the test's own
  export AU_DISK_FREE_BYTES=500000000000 AU_DISK_TOTAL_BYTES=1000000000000
}

install_cleanup() { # the test's EXIT trap: stops the engine job launchd_hook started, then every stub engine
  local f
  for f in "${STUB_LAUNCHCTL_DIR:-/nonexistent}"/pids/*; do [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null; done
  stub_cleanup
}

install_registry() { # OUT [VERSION [ORDER...]] -> a registry in format 1 of the household recipe's form,
  # naming the engine archive, the stand-ins and the assets made by install_env. ORDER, the builds of its
  # order line, defaults to order 1 then order 2
  local out=$1 version=${2:-v0.1.0} es ez t1 t2 ss st order
  shift; [ $# -eq 0 ] || shift
  if [ $# -gt 0 ]; then order=$(IFS=$'\t'; printf '%s' "$*"); else order="$IB1	$IB2"; fi
  es=$(shasum -a 256 < "$FX/engine.tar.gz" | cut -c1-64); ez=$(stat -f %z "$FX/engine.tar.gz")
  t1=$(shasum -a 256 < "$FX/assets/order-1.jinja" | cut -c1-64)
  t2=$(shasum -a 256 < "$FX/assets/order-2.jinja" | cut -c1-64)
  ss=$(shasum -a 256 < "$FX/assets/household-system.txt" | cut -c1-64)
  st=$(shasum -a 256 < "$FX/assets/household-test.json" | cut -c1-64)
  {
    printf 'auster-registry\t1\t%s\n' "$version"
    printf 'engine\t%s\tmacos-arm64\tb12359\tllama-b12359-bin-macos-arm64.tar.gz\t%s\t%s\t14\n' "$IE" "$ez" "$es"
    printf 'model\t%s\t%s\t%s\tstandin-a.gguf\t3400\t%s\tapache-2.0\tendorsed\t262144\n' "$IMA" "$REPO_A" "$COMMIT_A" "$SA"
    printf 'model\t%s\t%s\t%s\tstandin-b.gguf\t2040\t%s\tapache-2.0\tpublisher\t131072\n' "$IMB" "$REPO_B" "$COMMIT_B" "$SB"
    printf 'build\t%s\t%s\t%s\t%s\t%s\t%s\t41923\t333\t484\t23040\t0\t0.95\tdev-mac-64gb\n' "$IB1" "$IE" "$IMA" "$t1" "$ss" "$st"
    printf 'build\t%s\t%s\t%s\t%s\t%s\t%s\t13302\t665\t432\t163840\t0.7\t0.95\tdev-mac-64gb\n' "$IB2" "$IE" "$IMB" "$t2" "$ss" "$st"
    printf 'recipe\t%s\thousehold\tpublisher,endorsed\t4\t8192\t32768\n' "$IR"
    printf 'order\t%s\t%s\n' "$IR" "$order"
  } > "$out"
}

install_tree() { # REGISTRY [COMMIT [PAX-COMMIT [FOLDER]]] -> the tree of COMMIT (default $COMMIT), with that
  # registry, at its codeload address; its pax header records PAX-COMMIT, its folder is FOLDER
  # (auster-<commit> by default, as codeload names it)
  local reg=$1 c=${2:-$COMMIT}
  local pax=${3:-$c} folder=${4:-auster-$c} src="$FX/tree-src-$c"
  rm -rf "$src"; mkdir -p "$src"
  cp "$ROOT/install.sh" "$src/"
  cp -R "$ROOT/common" "$ROOT/tools" "$FX/assets" "$src/"
  cp "$reg" "$src/registry.tsv"
  tree_archive "$src" "$folder" "$pax" "$FX/tree-$c.tar.gz"
  curl_route GET "$CODELOAD/$c" 200 "$FX/tree-$c.tar.gz"
}

route_drop() { # URL -> the stub curl's routes for that address removed, so that a test can route it anew
  awk -F'\t' -v u="$1" '$2 != u' "$STUB_CURL_DIR/routes" > "$STUB_CURL_DIR/routes.new" && mv "$STUB_CURL_DIR/routes.new" "$STUB_CURL_DIR/routes"
}

commit_route() { # REF COMMIT -> GitHub's API names COMMIT for REF (heads/release, tags/v<a>.<b>.<c>), as the bare sha
  printf '%s' "$2" > "$FX/sha-$2"
  curl_route GET "$API/$1" 200 "$FX/sha-$2"
}

tar_field() { printf '%s' "$1"; head -c $(($2 - ${#1})) /dev/zero; }   # TEXT WIDTH -> TEXT, NUL-padded

pax_header() { # CHECKSUM -> the 512-byte ustar header of a pax global header (type g) whose data is 52
  # bytes; CHECKSUM is eight spaces while the sum is taken, then six octal digits
  tar_field pax_global_header 100; tar_field 0000666 8; tar_field 0000000 8; tar_field 0000000 8
  tar_field 00000000064 12; tar_field 00000000000 12
  if [ "$1" = '        ' ]; then printf '        '; else printf '%s' "$1"; printf '\0 '; fi
  printf g; head -c 100 /dev/zero; tar_field ustar 6; printf 00; head -c 247 /dev/zero
}

tree_archive() { # DIR FOLDER PAX-COMMIT OUT -> a gzipped tar as codeload serves it: a pax global header
  # whose record is "52 comment=<PAX-COMMIT>" (as git archive writes it), then DIR's files under FOLDER/
  local src=$1 folder=$2 pax=$3 out=$4 w sum
  w=$(mktemp -d "${TMPDIR%/}/tree.XXXXXX")
  mkdir "$w/s"; cp -R "$src" "$w/s/$folder"
  (cd "$w/s" && tar --format ustar -cf "$w/body.tar" "$folder")
  pax_header '        ' > "$w/h0"
  sum=$(od -An -tu1 -v "$w/h0" | awk '{ for (i = 1; i <= NF; i++) s += $i } END { print s }')
  pax_header "$(printf '%06o' "$sum")" > "$w/h"
  { cat "$w/h"; printf '52 comment=%s\n' "$pax"; head -c 460 /dev/zero; cat "$w/body.tar"; } | gzip -c > "$out"
  rm -rf "$w"
}

launchd_hook() { # -> the stub launchctl starts the engine job's program when the job is bootstrapped or
  # kickstarted, and stops it when it is booted out or disabled, as launchd would; it runs with the
  # test's PATH (the stubs), not the job file's
  mkdir -p "$STUB_LAUNCHCTL_DIR/hooks" "$STUB_LAUNCHCTL_DIR/pids"
  cat > "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine" <<'EOF'
#!/bin/bash
S=$STUB_LAUNCHCTL_DIR L=local.auster.engine
stop() { local p; p=$(cat "$S/pids/$L" 2>/dev/null); [ -z "$p" ] || kill "$p" 2>/dev/null; rm -f "$S/pids/$L"; }
start() {
  local plist prog log
  plist=$(cat "$S/loaded/$L")
  prog=$(/usr/bin/plutil -extract ProgramArguments.1 raw -o - "$plist")
  log=$(/usr/bin/plutil -extract StandardErrorPath raw -o - "$plist")
  /bin/bash "$prog" >> "$log" 2>&1 < /dev/null &
  echo $! > "$S/pids/$L"
}
case "$1" in bootstrap) start ;; kickstart) stop; start ;; bootout|disable) stop ;; esac
exit 0
EOF
  chmod 755 "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine"
}

run_install() { # ANSWERS ARG... -> the pasted line, `bash -c "$(install.sh)" auster-install ARG...`, run
  # with HOME=$H and the questions answered from ANSWERS (one a line); output in $W/out, exit code in RC
  printf '%s' "$1" > "$W/answers"; shift
  HOME="$H" AU_TTY="$W/answers" /bin/bash -c "$(cat "$ROOT/install.sh")" auster-install "$@" > "$W/out" 2>&1
  RC=$?
}

requests() { # [HOST] -> the requests the stub curl has sent, `METHOD URL` a line, only to HOST if given
  local d
  for d in "$STUB_CURL_DIR"/requests/*; do
    [ -d "$d" ] || continue
    printf '%s %s\n' "$(cat "$d/method")" "$(cat "$d/url")"
  done | if [ -n "${1:-}" ]; then grep -F "://$1/" || true; else cat; fi
}

says() { # TEXT LABEL -> ok when the run's output holds TEXT
  if grep -qF -- "$1" "$W/out"; then ok "$2"; else bad "$2: [$1] not in: $(head -c 3000 "$W/out")"; fi
}
