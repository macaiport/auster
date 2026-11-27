# T54, the installer's half (V5, U2; the gate's half is t54-registry-assets.sh): the template, system prompt and
# test a build names are found in the tree's assets/ by sha256 (A4, B3 step 8). One missing, or differing
# (U2: each of the three by exactly one byte, its length the same), stops the install at step 8 with exit 5,
# before any job or serving exists; every file renamed changes nothing. On an update, U4's. Mutants:
# tests/mutants/T54c and T54d.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
cp -R "$FX/assets" "$W/assets-good"

stopped8() { # LABEL [ASSET] -> after the run: exit 5 at step 8 for ASSET (template by default), no job and no serving
  same "$RC" 5 "$1: exit 5"
  says "This version of Auster holds no ${2:-template} with the sha256 the build names, so nothing more was installed." "$1: it stops at step 8"
  grep -q 'Testing the build' "$W/out" && bad "$1: it went on to the test" || ok "$1: nothing after step 8 ran"
  same "$(ls -A "$H/Library/LaunchAgents")" "" "$1: no job file"
  same "$(grep -c '^launchctl' "$STUB_LOG")" 0 "$1: no job loaded"
  [ -e "$DATA/builds/$IR/serving" ] && bad "$1: serving written" || ok "$1: no serving"
}

rm "$FX/assets/order-1.jinja"
install_tree "$FX/registry.tsv"
run_install $'no\nyes\nipad\n' "$IR"
stopped8 "the template missing from assets/"

rm -rf "$FX/assets"; cp -R "$W/assets-good" "$FX/assets"
printf '{#  #}' >> "$FX/assets/order-1.jinja"                    # the same name, other bytes
install_tree "$FX/registry.tsv"
run_install $'no\nyes\nipad\n' "$IR"
stopped8 "the template differing by its last bytes"

one_byte() { # FILE -> its last byte made another, so that it differs by one byte and keeps its length
  local n c
  n=$(stat -f %z "$1"); c=$(tail -c 1 "$1")
  { head -c $((n - 1)) "$1"; if [ "$c" = X ]; then printf Y; else printf X; fi; } > "$1.new" && mv "$1.new" "$1"
}
for a in order-1.jinja:template household-system.txt:system-prompt household-test.json:test; do
  rm -rf "$FX/assets" "$DATA"; cp -R "$W/assets-good" "$FX/assets"
  one_byte "$FX/assets/${a%%:*}"
  same "$(stat -f %z "$FX/assets/${a%%:*}"):$(cmp "$FX/assets/${a%%:*}" "$W/assets-good/${a%%:*}" 2>&1 | grep -c differ)" \
    "$(stat -f %z "$W/assets-good/${a%%:*}"):1" "the ${a#*:}: one byte changed, its length the same"
  install_tree "$FX/registry.tsv"
  run_install $'no\nyes\nipad\n' "$IR"
  stopped8 "the ${a#*:} differing by one byte" "${a#*:}"
done

rm -rf "$FX/assets" "$DATA"; mkdir "$FX/assets"; i=0
for f in "$W"/assets-good/*; do i=$((i + 1)); cp "$f" "$FX/assets/renamed-$i"; done
install_tree "$FX/registry.tsv"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "every file in assets/ renamed: installed all the same"
st=$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f5-7)
for sha in $st; do [ -f "$DATA/store/$sha" ] && ok "store/ holds ${sha:0:12}... by its sha256" || bad "store/ lacks $sha"; done
done_
