# T69: a home folder whose path holds a space, an apostrophe and &: the install passes, both job files pass
# `plutil -lint`, and the stub engine receives every path whole (B3, B4). It is also this suite's one whole
# first install, so it checks what that leaves: serving with the speed the server check measured, the
# stamp, both jobs loaded, the keys, and no lock. Mutants: tests/mutants/T69a and T69b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
case "$H" in *" "*"'"*"&"*) ok "the home folder's path holds a space, an apostrophe and &" ;; *) bad "home: $H" ;; esac

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "the install passes"
says "Auster is installed. On a device on the home network, open http://test-mac.local:8484/" "it says where to open the chat page"
for l in local.auster.engine local.auster.check; do
  f="$H/Library/LaunchAgents/$l.plist"
  if plutil -lint "$f" > /dev/null 2>&1; then ok "$l.plist passes plutil -lint"; else bad "$l.plist: $(plutil -lint "$f" 2>&1)"; fi
done
same "$(plutil -extract ProgramArguments.1 raw -o - "$H/Library/LaunchAgents/local.auster.engine.plist")" \
  "$DATA/jobs/auster-engine" "the engine's job file names its program by its whole path"
same "$(plutil -extract StandardOutPath raw -o - "$H/Library/LaunchAgents/local.auster.check.plist")" \
  "$DATA/logs/check.log" "the check's job file names its log by its whole path"

# The engines it ran: --list-devices to measure the Mac (step 4), the candidate (step 10), then the engine
# job's (B4 step 8). A path is compared once each side is resolved (pwd -P).
real() { printf '%s/%s' "$(cd "$(dirname "$1")" && pwd -P)" "${1##*/}"; }
E=$STUB_ENGINE_DIR
same "$(ls "$E/starts" | wc -l | tr -d ' ')" 3 "three runs of the engine: to measure, to test, to serve"
same "$(cat "$E/starts/0001/args")" "--list-devices" "the first only lists the devices"
ed=$(cd "$DATA"/engines/[0-9a-f]* && pwd -P)
store=$(cd "$DATA/store" && pwd -P)
for n in 0002 0003; do
  s="$E/starts/$n"
  same "$(real "$(cat "$s/program")")" "$ed/root/llama-stub/llama-server" "start $n: the program, by its whole path"
  same "$(cat "$s/cwd")" "$store" "start $n: its working folder is store/, whole"
done
s1="$E/starts/0002" s2="$E/starts/0003"
case "$(cat "$s1/keyfile")" in *"/auster-run."*/test-key/key) ok "the test's engine reads a key made for the test, outside the data root" ;; *) bad "test key file: $(cat "$s1/keyfile")" ;; esac
same "$(cat "$s2/keyfile")" "$(cd "$DATA/keys" && pwd -P)/engine.keys" "the server's engine reads keys/engine.keys, whole"
same "$(sed -n '/^--host$/{n;p;}' "$s1/args")" 127.0.0.1 "the test's engine listens on 127.0.0.1 only"
same "$(sed -n '/^--host$/{n;p;}' "$s2/args")" 127.0.0.1,10.0.0.5 "the server listens on 127.0.0.1 and the home address"
same "$(sed -n '/^-c$/{n;p;}' "$s1/args") $(sed -n '/^-np$/{n;p;}' "$s1/args")" "131072 4" "the test runs at the household's setting: 4 people at 32,768"
same "$(sed -n '/^--ui-config-file$/{n;p;}' "$s2/args")" "../builds/$IR/ui-config.json" "the server's UI config, by a relative path"
same "$(cat "$s2/env")" "PATH=/usr/bin:/bin:/usr/sbin:/sbin" "the server's environment holds only PATH"

# What the install leaves
sv="$DATA/builds/$IR/serving"
same "$(head -n 1 "$sv")" "auster-descriptor 1" "serving is a descriptor"
same "$(sed -n 2p "$sv")" "$(grep "^build	$IB1	" "$FX/registry.tsv")" "serving names order 1, its build line byte for byte"
same "$(sed -n 5p "$sv" | cut -f1-4,6)" "launch	4	32768	8484	36.9" "the launch line: 4 people at 32,768 on port 8484, and the speed the server check measured"
same "$(sed -n 5p "$sv" | cut -f5)" "$(shasum -a 256 < "$ed/files" | cut -c1-64)" "the launch line holds the sha256 of the engine's file list"
same "$(cut -f1-4 "$DATA/_update/scripts")" "auster-record 1	release	v0.1.0	$COMMIT" "the stamp: release, the version and the commit"
same "$(ls "$STUB_LAUNCHCTL_DIR/loaded" | sort | tr '\n' ' ')" "local.auster.check local.auster.engine " "both jobs are loaded"
same "$(cat "$STUB_LAUNCHCTL_DIR/overrides/local.auster.engine")" enabled "the engine's label was enabled before it was loaded"
[ -e "$DATA/builds/updating" ] && bad "the lock is left" || ok "the lock is released"
same "$(stat -f %Lp "$DATA")" 700 "the data root has mode 0700"
same "$(stat -f %Lp "$DATA/keys/engine.keys")" 600 "the engine's key file has mode 0600"
same "$(wc -l < "$DATA/keys/engine.keys" | tr -d ' ')" 2 "the key file holds the device's key and Auster's own"
same "$(cat "$DATA"/keys/k*.name)" ipad "the device is named as the household said"
same "$(grep -c '^  Q[0-9][0-9] PASS' "$W/out")" 12 "the recipe's test ran, and each of its questions passed"
same "$(cat "$DATA/bin/auster" | shasum -a 256)" "$(shasum -a 256 < "$ROOT/common/auster")" "bin/auster is the tree's common/auster"
done_
