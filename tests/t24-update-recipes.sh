# T24 (U5; D3.6 steps 1 to 5, BD14): several recipes, each failing its own way, do not stop the others. An install refuses a
# second recipe (BD14), but the records stay per recipe, so the Mac is given three more directly, each with a build of its
# own waiting, ahead of the household recipe in the order the update takes them (by id): recipe A's new model is cut off
# by its CDN, recipe B's arrives with the wrong content, and recipe C's candidate fails the recipe's test. v0.1's engine job
# serves one recipe, so launchd's job is played here by a stand-in that serves every recipe's serving on its own port and
# waits on builds/paused as the engine job does. Answered yes four times: exit 3; A, B and C each still serve their old
# build, which answers a household key on its own port, with C's candidate in its failed/; the household recipe, after
# them, is updated to order 1, which serves.
# Mutant: tests/mutants/T24a (stop at the first failure).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
RECA=r7ampfywdpugo OA=bymjenjppbhyb NA=bbmjlavvcy7wk   # recipe A: its build served, its build waiting (minted for this test)
RECB=rcjdnoy57z6ln OB=b3pgh3f6n2ahz NB=bzo352raveweo   # recipe B
RECC=rh6tatp6pdaip OC=bepxe2bfqz4co NC=bmjvbljqfmjoj   # recipe C
IMC=mtn7vtuosc4q3 IMD=mlaaludxcujoo                  # A's and B's new models
REPO_C=example-org/model-c COMMIT_C=3c5e7a9b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c
REPO_D=example-org/model-d COMMIT_D=4d6f8a0c2e4a6c8e0a2c4e6a8c0e2a4c6e8a0c2e
URL_C=https://huggingface.co/$REPO_C/resolve/$COMMIT_C/standin-c.gguf
URL_D=https://huggingface.co/$REPO_D/resolve/$COMMIT_D/standin-d.gguf
update_install
waiting_b1   # the household recipe serves order 2 for four at 32,768, order 1 waiting

# models C and D, and D's wrong copy (its last byte changed)
for i in $(seq 20); do printf 'Auster model stand-in C, line %03d\n' "$i"; done > "$FX/models/standin-c.gguf"
for i in $(seq 25); do printf 'Auster model stand-in D, line %03d\n' "$i"; done > "$FX/models/standin-d.gguf"
{ head -c $(( $(stat -f %z "$FX/models/standin-d.gguf") - 1 )) "$FX/models/standin-d.gguf"; printf 'X'; } > "$FX/models/standin-d-wrong.gguf"
SC=$(shasum -a 256 < "$FX/models/standin-c.gguf" | cut -c1-64) ZC=$(stat -f %z "$FX/models/standin-c.gguf")
SD=$(shasum -a 256 < "$FX/models/standin-d.gguf" | cut -c1-64) ZD=$(stat -f %z "$FX/models/standin-d.gguf")
curl_route HEAD "$URL_C" 302 - "Location: https://cdn.example.test/c" "x-linked-size: $ZC" "x-linked-etag: \"$SC\""
curl_route GET "$URL_C" 302 - "Location: https://cdn.example.test/c"
curl_route GET https://cdn.example.test/c exit:56:100 "$FX/models/standin-c.gguf"
curl_route HEAD "$URL_D" 302 - "Location: https://cdn.example.test/d" "x-linked-size: $ZD" "x-linked-etag: \"$SD\""
curl_route GET "$URL_D" 302 - "Location: https://cdn.example.test/d"
curl_route GET https://cdn.example.test/d 200 "$FX/models/standin-d-wrong.gguf"

# release v0.2.0: the household's registry, and the three recipes, each a small build served and one waiting
R="$FX/registry-v0.2.0.tsv"
install_registry "$R" v0.2.0
t1=$(awk -F'\t' -v b="$IB1" '$1 == "build" && $2 == b { print $5 "\t" $6 "\t" $7 }' "$R")
{ printf 'model\t%s\t%s\t%s\tstandin-c.gguf\t%s\t%s\tapache-2.0\tpublisher\t131072\n' "$IMC" "$REPO_C" "$COMMIT_C" "$ZC" "$SC"
  printf 'model\t%s\t%s\t%s\tstandin-d.gguf\t%s\t%s\tapache-2.0\tpublisher\t131072\n' "$IMD" "$REPO_D" "$COMMIT_D" "$ZD" "$SD"
  for x in "$RECA $OA $IMB $NA $IMC recipe-a" "$RECB $OB $IMB $NB $IMD recipe-b" "$RECC $OC $IMB $NC $IMA recipe-c"; do
    set -- $x
    printf 'build\t%s\t%s\t%s\t%s\t2000\t100\t100\t1000\t0.7\t0.95\tdev-mac-64gb\n' "$2" "$IE" "$3" "$t1"
    printf 'build\t%s\t%s\t%s\t%s\t2000\t100\t100\t1000\t0.7\t0.95\tdev-mac-64gb\n' "$4" "$IE" "$5" "$t1"
    printf 'recipe\t%s\t%s\tpublisher,endorsed\t1\t8192\t8192\n' "$1" "$6"
    printf 'order\t%s\t%s\t%s\n' "$1" "$4" "$2"
  done; } >> "$R"
install_tree "$R" "$COMMIT2"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"

# their records: each serving its old build for one person at 8,192 on a port of its own
list=$(sed -n 5p "$W/pristine/builds/$IR/serving" | cut -f5)
port=8484
for x in "$RECA $OA" "$RECB $OB" "$RECC $OC"; do
  set -- $x
  port=$((port + 1))
  mkdir -m 700 "$DATA/builds/$1" "$DATA/builds/$1/kept"
  { printf 'auster-descriptor 1\n'; grep "^build	$2	" "$R"; grep "^engine	$IE	" "$R"; grep "^model	$IMB	" "$R"
    printf 'launch\t1\t8192\t%s\t%s\t40.1\n' "$port" "$list"; } > "$DATA/builds/$1/serving"
  chmod 600 "$DATA/builds/$1/serving"
done

# launchd's engine job, played by a stand-in that serves every recipe, each on its serving's port, once builds/paused
# names no live process
cat > "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine" <<'EOF'
#!/bin/bash
S=$STUB_LAUNCHCTL_DIR L=local.auster.engine
stop() {
  local p
  p=$(cat "$S/pids/$L" 2>/dev/null); [ -z "$p" ] || kill "$p" 2>/dev/null
  for p in $(cat "$S/pids-all" 2>/dev/null); do kill "$p" 2>/dev/null; done
  for p in $(cat "$S/pids-all" 2>/dev/null); do while kill -0 "$p" 2>/dev/null; do /bin/sleep 0.05; done; done
  rm -f "$S/pids-all" "$S/pids/$L"
}
start() {
  local plist prog data
  plist=$(cat "$S/loaded/$L"); prog=$(/usr/bin/plutil -extract ProgramArguments.1 raw -o - "$plist"); data=${prog%/jobs/auster-engine}
  ( while [ -f "$data/builds/paused" ] && kill -0 "$(cut -f2 "$data/builds/paused")" 2>/dev/null; do /bin/sleep 0.1; done
    for s in "$data"/builds/r*/serving; do
      r=${s%/serving}
      printf 'auster-record 1\ncode\tstarting\naddress\t10.0.0.5\nboot\t%s\ntime\t%s\n' "$(sysctl -n kern.bootsessionuuid)" "$(/bin/date +%s)" > "$r/start"
      ( cd "$data/store" && exec "$data/engines/$(sed -n 3p "$s" | cut -f7)/root/llama-stub/llama-server" -m "$(sed -n 4p "$s" | cut -f7)" \
          --alias "$(sed -n 2p "$s" | cut -f2)" --host 127.0.0.1,10.0.0.5 --port "$(sed -n 5p "$s" | cut -f4)" \
          --api-key-file ../keys/engine.keys ) >> "$data/logs/engine.log" 2>&1 < /dev/null &
      echo $! >> "$S/pids-all"
    done
    wait ) > /dev/null 2>&1 < /dev/null &
  echo $! > "$S/pids/$L"
}
case "$1" in bootstrap) start ;; kickstart) stop; start ;; bootout|disable) stop ;; esac
exit 0
EOF
chmod 755 "$STUB_LAUNCHCTL_DIR/hooks/local.auster.engine"
trap 'launchctl bootout "gui/$UIDN/local.auster.engine" 2> /dev/null; install_cleanup' EXIT
engine_set "alias=$NC" answers "$FX/answers-bad"   # recipe C's candidate
for x in "$RECA $OA" "$RECB $OB" "$RECC $OC"; do set -- $x; eval "s0_$1=\$(cat \"\$DATA/builds/\$1/serving\")"; done

update_run $'yes\nyes\nyes\nyes\n'
same "$RC" 3 "three recipes failing, each its own way, and the household recipe after them: exit 3"
says "The model's download stopped (curl exit 56, answer 200) at 100 bytes" "  ...recipe A: its download cut off"
says "The model that arrived is not the file the registry names (its sha256 differs), so it was deleted." "  ...recipe B: the wrong content"
says "Build $NC did not pass the recipe's test on this Mac. The recipe recipe-c stays on build $OC." "  ...recipe C: its candidate failed the test"
p=8484
for x in "$RECA $OA recipe-a" "$RECB $OB recipe-b" "$RECC $OC recipe-c"; do
  set -- $x
  p=$((p + 1))
  same "$(cat "$DATA/builds/$1/serving")" "$(eval "printf '%s' \"\$s0_$1\"")" "$3: serving as it was"
  same "$(arg_of "$(start_on $p)" --alias) $(ask_engine "$(key_of ipad)" 10.0.0.5 "$p")" "$2 200" "$3: its old build serves, and answers a household key on port $p"
done
same "$(ls "$DATA/builds/$RECC/failed" | sed 's/.*Z-//')" "$NC" "recipe C: its candidate in failed/"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2) $(sed -n 5p "$DATA/builds/$IR/serving" | cut -f6)" "$IB1 36.9" \
  "the household recipe, after them: updated to order 1, checked"
same "$(arg_of "$(start_on 8484)" --alias) $(ask_engine "$(key_of ipad)")" "$IB1 200" "  ...which serves, and answers a household key"
done_
