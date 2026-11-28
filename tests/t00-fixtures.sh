# T0: the fixtures and stubs of D6 behave as their headers say, so that a later test that fails is failing
# on Auster and not on its stand-ins. Mutants: tests/mutants/T0a to T0c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
stub_env
W=$(mktemp -d "${TMPDIR%/}/t00.XXXXXX")
C=$STUB_CURL_DIR

# --- the stub curl
printf 'hello, stub world\n' > "$C/hello"          # 18 bytes
curl_route GET https://example.test/hello 200 hello "Content-Type: text/plain"
curl -s -o "$W/out" https://example.test/hello; same $? 0 "curl -o: exit 0"
same "$(cat "$W/out")" "hello, stub world" "curl -o: the body lands in the file"
same "$(curl -s -o /dev/null -w '%{http_code} %{size_download} %{url_effective}\n' https://example.test/hello)" \
  "200 18 https://example.test/hello" "curl -w: code, size and address"
same "$(curl -s -o /dev/null -w '%{content_type}|%header{content-type}' https://example.test/hello)" \
  "text/plain|text/plain" "curl -w: a response header"
h=$(curl -sI https://example.test/hello | tr -d '\r')
same "$(printf '%s\n' "$h" | head -1)" "HTTP/2 200" "curl -I: the status line"
case "$h" in *"content-length: 18"*) ok "curl -I: the length, from the GET route" ;; *) bad "curl -I: $h" ;; esac
same "$(curl -s -X HEAD -o /dev/null -w '%{size_download}' https://example.test/hello)" 0 "curl -X HEAD: no body"
same "$(curl -s -r 7-10 https://example.test/hello)" "stub" "curl -r: the range"
same "$(curl -s -r 7-10 -o /dev/null -w '%{http_code}' https://example.test/hello)" 206 "curl -r: 206"

head -c 7 "$C/hello" > "$W/part"
curl -s -C - -o "$W/part" https://example.test/hello; same $? 0 "curl -C -: exit 0"
same "$(cat "$W/part")" "hello, stub world" "curl -C -: resumed from the file's size"
last=$(ls -d "$C"/requests/* | tail -1)
grep -qx 'Range: bytes=7-' "$last/headers" && ok "curl -C -: asked from byte 7" || bad "curl -C -: $(cat "$last/headers")"
same "$(curl -s -C - -o "$W/part" -w '%{http_code}' https://example.test/hello; echo " $?")" "416 0" \
  "curl -C - on a whole file: 416 and exit 0, as curl does"
same "$(cat "$W/part")" "hello, stub world" "curl -C - on a whole file: the file unchanged"

curl_route GET https://example.test/cut 'exit:18:5,200' hello
curl -s -o "$W/cut" https://example.test/cut; same $? 18 "curl, cut short: exit 18"
same "$(stat -f %z "$W/cut")" 5 "curl, cut short: 5 bytes arrived"
curl -s -C - -o "$W/cut" https://example.test/cut; same $? 0 "curl, the second call: resumed"
same "$(cat "$W/cut")" "hello, stub world" "curl, cut then resumed: the whole file"
curl_route GET https://example.test/norange 200 hello "X-Stub-No-Ranges: 1"
head -c 3 "$C/hello" > "$W/nr"
curl -s -C - -o "$W/nr" https://example.test/norange; same $? 33 "curl -C - when the server ignores ranges: exit 33"
curl_route GET https://example.test/badcode 200 hello "X-Stub-Code: 2OO"
same "$(curl -s -o /dev/null -w '%{http_code}' https://example.test/badcode; echo " $?")" "2OO 0" "curl -w with X-Stub-Code: its text for the code, exit 0"

curl_route GET https://example.test/moved 302 - "Location: https://cdn.example.test/hello"
curl_route GET https://cdn.example.test/hello 200 hello
same "$(curl -sL -w ' %{url_effective} %{num_redirects}' https://example.test/moved)" \
  "hello, stub world
 https://cdn.example.test/hello 1" "curl -L: follows the Location header"
same "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' https://example.test/moved)" \
  "302 https://cdn.example.test/hello" "curl without -L: the 302 itself"
curl_route GET https://example.test/down 302 - "Location: http://cdn.example.test/hello"
curl -s --proto =https --proto-redir =https -L -o /dev/null https://example.test/down; same $? 1 "curl --proto-redir =https: an http redirect refused"
curl -s --proto =https -o /dev/null http://example.test/hello; same $? 1 "curl --proto =https: an http address refused"

curl_route GET https://example.test/missing 404 hello
rm -f "$W/f"
curl -fs -o "$W/f" https://example.test/missing; same $? 22 "curl -f on 404: exit 22"
[ -e "$W/f" ] && bad "curl -f on 404: wrote the file" || ok "curl -f on 404: no file"
curl -s -o "$W/f" https://example.test/missing; same $? 0 "curl on 404 without -f: exit 0"
same "$(curl -fsS https://example.test/missing 2>&1 >/dev/null)" "curl: (22) The requested URL returned error: 404" "curl -fsS: curl's message"
same "$(curl -fs -o /dev/null -w '%{http_code}' https://example.test/missing)" 404 "curl -f: -w still written"

for e in 6 7 18 28 35 56; do
  curl_route GET "https://example.test/fail$e" "exit:$e" hello
  msg=$(curl -sS -o /dev/null "https://example.test/fail$e" 2>&1); rc=$?
  same "$rc" "$e" "curl exit $e"
  case "$msg" in "curl: ($e) "*) ok "curl exit $e: curl's message with -S" ;; *) bad "curl exit $e: [$msg]" ;; esac
  same "$(curl -s -o /dev/null "https://example.test/fail$e" 2>&1)" "" "curl exit $e: quiet with -s alone"
done
same "$(curl -s -o /dev/null -w '%{http_code}' https://example.test/fail7)" 000 "curl, no answer: http_code 000"
curl_route GET https://example.test/slow sleep:5 hello
t0=$(/bin/date +%s); curl -s --max-time 1 -o /dev/null https://example.test/slow; rc=$?; t1=$(/bin/date +%s)
same "$rc" 28 "curl --max-time over a slow server: exit 28"
[ $((t1 - t0)) -le 3 ] && ok "curl --max-time: ended in time" || bad "curl --max-time took $((t1 - t0)) s"
curl -s https://nowhere.example.test/ 2>/dev/null; same $? 99 "curl with no route: fails loudly"
grep -qx 'GET https://nowhere.example.test/' "$C/unrouted" && ok "curl with no route: recorded" || bad "curl with no route: not recorded"
curl -s http://127.0.0.1:9/ 2>/dev/null; same $? 7 "curl to a local port with nothing there: refused"
curl -s --frobnicate https://example.test/hello 2>/dev/null; same $? 99 "curl with an option it does not know: fails loudly"

printf 'Authorization: Bearer 0123abcd\n' > "$W/hdr"
printf '{"a":1}' > "$W/body"
curl_route POST https://example.test/post 200 hello
curl -s -o /dev/null -H @"$W/hdr" -H 'Content-Type: application/json' --data-binary @"$W/body" https://example.test/post
last=$(ls -d "$C"/requests/* | tail -1)
same "$(cat "$last/method")" POST "curl -d: a POST"
same "$(cat "$last/body")" '{"a":1}' "curl --data-binary @file: the body sent"
grep -qx 'Authorization: Bearer 0123abcd' "$last/headers" && ok "curl -H @file: the header sent" || bad "curl -H @file"
grep -qx 'User-Agent: curl/8.7.1' "$last/headers" && ok "curl: names curl and its version" || bad "curl: user agent"
grep -q 0123abcd "$STUB_LOG" && bad "curl -H @file: the key reached the log" || ok "curl -H @file: the key is not in the log"
grep -q "^curl -s -o /dev/null -H @$W/hdr " "$STUB_LOG" && ok "curl: the call is logged" || bad "curl: the call is not logged"

# --- the stub engine
E=$STUB_ENGINE_DIR
printf '0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f\n' > "$W/engine.keys"
engine_set '*' behaviour ok
engine_set '*' rate 36.9
engine_set 'model=bad.gguf' behaviour http500
engine_set '*' list-devices b12359
engine_program "$W/engine bin"
mkdir -p "$W/store"
( cd "$W/store" && env -i PATH=/usr/bin:/bin "$W/engine bin/llama-server" -m 0123.gguf --alias b7adwcqnfap56 -c 65536 -np 2 \
    --host 127.0.0.1,10.0.0.5 --port 18484 --api-key-file ../engine.keys --offline --jinja --fit off -ngl all \
    >> "$E/output" 2>&1 & )
for i in $(seq 100); do [ -f "$E/ports/18484" ] && break; sleep 0.05; done
[ -f "$E/ports/18484" ] && ok "engine: registered its port" || bad "engine: did not register"
S=$(ls -d "$E"/starts/* | head -1)
same "$(cat "$S/args")" "-m
0123.gguf
--alias
b7adwcqnfap56
-c
65536
-np
2
--host
127.0.0.1,10.0.0.5
--port
18484
--api-key-file
../engine.keys
--offline
--jinja
--fit
off
-ngl
all" "engine: the start record holds the arguments, the wrapper's own taken off"
same "$(cat "$S/env")" "PATH=/usr/bin:/bin" "engine: the start record holds the environment it was given"
same "$(cat "$S/cwd")" "$(cd "$W/store" && pwd -P)" "engine: the start record holds its working folder"
same "$(cat "$S/keyfile")" "$(cd "$W" && pwd -P)/engine.keys" "engine: the key file it read, made absolute"
same "$(cat "$S/program")" "$W/engine bin/llama-server" "engine: the program that was run"
grep -q '^llama-server -m 0123.gguf' "$STUB_LOG" && ok "engine: logged, through the wrapper" || bad "engine: not logged"

U=http://127.0.0.1:18484
same "$(curl -s $U/health)" '{"status":"ok"}' "engine /health: 200 with no key"
q='{"messages":[{"role":"user","content":"Count from 1 to 300, one number per line."}],"temperature":0,"max_tokens":128}'
printf '%s' "$q" > "$W/q.json"
same "$(curl -s -o /dev/null -w '%{http_code}' -d @"$W/q.json" $U/v1/chat/completions)" 401 "engine: no key, 401"
printf 'Authorization: Bearer 1f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f\n' > "$W/wrong"
same "$(curl -s -o /dev/null -w '%{http_code}' -H @"$W/wrong" -d @"$W/q.json" $U/v1/chat/completions)" 401 "engine: a wrong key, 401"
printf 'Authorization: Bearer 0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f\n' > "$W/right"
a=$(curl -s -H @"$W/right" -H 'Content-Type: application/json' --data-binary @"$W/q.json" $U/v1/chat/completions)
case "$a" in *'"predicted_per_second":36.9'*) ok "engine: the writing rate it was given" ;; *) bad "engine: rate in $a" ;; esac
case "$a" in *'"predicted_n":128'*'"finish_reason":"length"'*|*'"finish_reason":"length"'*'"predicted_n":128'*) ok "engine: stops at max_tokens" ;; *) bad "engine: max_tokens in $a" ;; esac
case "$a" in *'"content":"1\n2\n3\n'*) ok "engine: answers the speed question" ;; *) bad "engine: content in $a" ;; esac
same "$(curl -s -o /dev/null -w '%{http_code}' http://10.0.0.5:18484/health)" 200 "engine: listens on the home address it was given"
curl -s -o /dev/null http://192.168.1.20:18484/health; same $? 7 "engine: refuses an address it was not given"
nc -z 127.0.0.1 18484; same $? 0 "nc: the engine's port answers"
nc -z 127.0.0.1 18485; same $? 1 "nc: another port does not"
mp=$(curl -s -H @"$W/right" $U/props)
case "$mp" in *'"model_path":"0123.gguf"'*) ok "engine /props: -m as given" ;; *) bad "engine /props: $mp" ;; esac

engine_start -m 0123.gguf --port 18484 --api-key-file "$W/engine.keys" > /dev/null
grep -q "couldn't bind" "$E/output" && ok "engine: a second engine on a taken port fails" || bad "engine: two on one port"

printf 'Count from\tone two three\t12.5\n*\tI do not know\n' > "$W/answers"
engine_set 'port=18486' answers "$W/answers"
p500=$(engine_start -m /x/bad.gguf --port 18485 --api-key-file "$W/engine.keys")
pans=$(engine_start -m good.gguf --port 18486 --api-key-file "$W/engine.keys")
same "$(curl -s -H @"$W/right" -d @"$W/q.json" -o /dev/null -w '%{http_code}' http://127.0.0.1:18485/v1/chat/completions)" 500 "engine http500 for one model: chat 500"
case "$(curl -s -H @"$W/right" -d @"$W/q.json" http://127.0.0.1:18485/v1/chat/completions)" in *'"Compute error."'*) ok "engine http500: Compute error." ;; *) bad "engine http500: message" ;; esac
same "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18485/health)" 200 "engine http500: /health still 200"
a=$(curl -s -H @"$W/right" -d @"$W/q.json" http://127.0.0.1:18486/v1/chat/completions)
case "$a" in *'"content":"one two three"'*'"predicted_per_second":12.5'*) ok "engine answers file: reply and rate by question" ;; *) bad "engine answers: $a" ;; esac
engine_live 18486 behaviour http500
same "$(curl -s -H @"$W/right" -d @"$W/q.json" -o /dev/null -w '%{http_code}' http://127.0.0.1:18486/v1/chat/completions)" 500 "engine_live: a running engine turns to 500"

engine_set 'port=18487' behaviour open
popen=$(engine_start -m good.gguf --port 18487 --api-key-file "$W/engine.keys")
same "$(curl -s -o /dev/null -w '%{http_code}' -d @"$W/q.json" http://127.0.0.1:18487/v1/chat/completions)" 200 "engine open: answers with no key"
printf '# only a comment\n\n' > "$W/comment.keys"
pcom=$(engine_start -m good.gguf --port 18488 --api-key-file "$W/comment.keys")
same "$(curl -s -o /dev/null -w '%{http_code}' -d @"$W/q.json" http://127.0.0.1:18488/v1/chat/completions)" 200 "engine: a key file of comments leaves it open, as the real one"

engine_set 'port=18489' behaviour nolisten
pnl=$(engine_start -m good.gguf --port 18489)
kill -0 "$pnl" 2>/dev/null && ok "engine nolisten: alive" || bad "engine nolisten: not running"
curl -s http://127.0.0.1:18489/health; same $? 7 "engine nolisten: refused"

kill "$p500"; for i in $(seq 100); do [ -f "$E/ports/18485" ] || break; sleep 0.05; done
[ -f "$E/ports/18485" ] && bad "engine stop: still registered" || ok "engine stop: unregistered"
sd=$(grep -l "^$p500\$" "$E"/starts/*/pid | head -1); sd=${sd%/pid}
case "$(cat "$sd/stopped" 2>/dev/null)" in *' TERM') ok "engine stop: recorded" ;; *) bad "engine stop: not recorded" ;; esac
curl -s http://127.0.0.1:18485/health; same $? 7 "engine stopped: refused"

same "$("$TESTS/stubs/llama-server" --list-devices)" "$(cat "$TESTS/fixtures/list-devices/b12359.txt")" "engine --list-devices: the fixture chosen"
mv "$E/config" "$E/config.1"; engine_set '*' list-devices no-mtl0
same "$("$TESTS/stubs/llama-server" --list-devices)" "$(cat "$TESTS/fixtures/list-devices/no-mtl0.txt")" "engine --list-devices: another copy by the setting"
: > "$E/config"
"$TESTS/stubs/llama-server" --port 18490 2>/dev/null; same $? 99 "engine with no behaviour: fails loudly"
mv "$E/config.1" "$E/config"

# --- the --list-devices fixtures
form='^  MTL0: .* \(([0-9]+) MiB, ([0-9]+) MiB free\)$'
mtl() { local l n=0 v=; while IFS= read -r l; do [[ "$l" =~ $form ]] && { n=$((n + 1)); v=${BASH_REMATCH[1]}; }; done < "$1"; echo "$n $v"; }
same "$(mtl "$TESTS/fixtures/list-devices/b12359.txt")" "1 53084" "list-devices b12359: one MTL0 line in the expected form, 53084 MiB"
same "$(mtl "$TESTS/fixtures/list-devices/columns-swapped.txt")" "0 " "list-devices columns-swapped: no line in that form"
same "$(grep -c MTL0 "$TESTS/fixtures/list-devices/columns-swapped.txt")" 1 "list-devices columns-swapped: still names MTL0"
same "$(grep -c MTL0 "$TESTS/fixtures/list-devices/no-mtl0.txt")" 0 "list-devices no-mtl0: no MTL0"

# --- launchctl
L=local.auster.engine
printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict><key>Label</key><string>%s</string></dict></plist>\n' "$L" > "$W/job.plist"
launchctl bootstrap gui/501 "$W/job.plist"; same $? 0 "launchctl bootstrap"
case "$(launchctl print gui/501/$L)" in *"path = $W/job.plist"*) ok "launchctl print: the loaded job" ;; *) bad "launchctl print" ;; esac
launchctl bootstrap gui/501 "$W/job.plist" 2>/dev/null; same $? 5 "launchctl bootstrap twice: 5"
launchctl kickstart -k gui/501/$L; same $? 0 "launchctl kickstart -k of a loaded job"
launchctl disable gui/501/$L
case "$(launchctl print-disabled gui/501)" in *"\"$L\" => disabled"*) ok "launchctl disable: listed as disabled" ;; *) bad "launchctl print-disabled" ;; esac
launchctl bootout gui/501/$L; same $? 0 "launchctl bootout"
launchctl print gui/501/$L 2>/dev/null; same $? 113 "launchctl print after bootout: 113"
launchctl kickstart -k gui/501/$L 2>/dev/null; same $? 113 "launchctl kickstart of a job not loaded: 113"
launchctl bootout gui/501/$L 2>/dev/null; same $? 3 "launchctl bootout twice: 3"
launchctl bootstrap gui/501 "$W/job.plist" 2>/dev/null; same $? 5 "launchctl bootstrap of a disabled job: 5"
launchctl enable gui/501/$L
case "$(launchctl print-disabled gui/501)" in *"\"$L\" => enabled"*) ok "launchctl enable: listed as enabled" ;; *) bad "launchctl enable" ;; esac
launchctl bootstrap gui/501 "$W/job.plist"; same $? 0 "launchctl bootstrap after enable"

# --- the command stubs
same "$(uname -m)" arm64 "uname -m"
same "$(sysctl -n sysctl.proc_translated)" 0 "sysctl proc_translated, native"
same "$(STUB_ROSETTA=1 uname -m)" x86_64 "Rosetta: uname -m"
same "$(STUB_ROSETTA=1 sysctl -n sysctl.proc_translated)" 1 "Rosetta: proc_translated"
same "$(STUB_ROSETTA=1 sysctl -n hw.optional.arm64)" 1 "Rosetta: hw.optional.arm64 still 1"
same "$(STUB_MEMSIZE=38654705664 STUB_HW_MODEL=Mac15,9 sysctl -n hw.memsize hw.model)" "38654705664
Mac15,9" "sysctl: memory and model settable"
same "$(STUB_BOOT_SESSION=AAAA sysctl -n kern.bootsessionuuid)" AAAA "sysctl: boot session settable"
sysctl -n hw.nothing 2>/dev/null; same $? 1 "sysctl: an unknown name fails as on a Mac"
same "$(id -u) $(STUB_UID=0 id -u) $(STUB_UID=0 id -un)" "501 0 root" "id"
same "$(sw_vers -productVersion) $(STUB_MACOS=26.1 sw_vers -productVersion)" "27.2 26.1" "sw_vers"
same "$(route -n get default | awk '/interface:/ {print $2}')" en0 "route: the default interface"
STUB_NET_IF= route -n get default 2>/dev/null; same $? 1 "route: no default route"
same "$(ipconfig getifaddr en0)" 10.0.0.5 "ipconfig: the private address"
same "$(arp -n 10.0.0.1)" "? (10.0.0.1) at 0:0:5e:0:53:1 on en0 ifscope [ethernet]" "arp: the router"
networksetup -listallhardwareports | grep -qx 'Device: en0' && ok "networksetup: en0 is a hardware port" || bad "networksetup"
networksetup -listallhardwareports | grep -q utun && bad "networksetup: lists a tunnel" || ok "networksetup: no tunnel"
same "$(pmset -g | awk '$1 == "sleep" {print $2}')" 1 "pmset: the sleep setting"
pmset -g batt | grep -q InternalBattery && bad "pmset: a battery by default" || ok "pmset: no battery by default"
STUB_BATTERY=1 pmset -g batt | grep -q InternalBattery && ok "pmset: a laptop's battery" || bad "pmset battery"
same "$(STUB_NOW=1764148800 date +%s)" 1764148800 "date +%s: the stub clock"
same "$(STUB_NOW=1764148800 date -u +%Y-%m-%d)" 2025-11-26 "date: other formats at the stub clock"
same "$(openssl rand -hex 4 2>/dev/null || echo refused)" refused "openssl rand: told nothing, refuses"
same "$(STUB_OPENSSL_RAND_HEX=0a0b0c0d openssl rand -hex 4)" 0a0b0c0d "openssl rand -hex"
printf 'abc' > "$W/abc"
same "$(openssl dgst -sha256 "$W/abc")" "SHA256($W/abc)= ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" "openssl dgst -sha256"

sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
same "$(ps -p "$live" -o lstart= | sed 's/ *$//')" "Thu Nov 20 10:00:00 2026" "ps: a live process at the start time the table gives"
same "$(ps -p "$$" -o lstart= | sed 's/ *$//')" "Thu Nov 26 09:00:00 2026" "ps: a live process not in the table"
stale_lock "$W/updating"
gone=$(cut -f2 "$W/updating")
ps -p "$gone" -o lstart= >/dev/null; same $? 1 "ps: the stale lock's process is gone"
{ kill "$live"; wait "$live"; } 2>/dev/null
same "$(awk -F'\t' '{print NF, $1, $3, $4}' "$W/updating")" "4 auster-record 1 5E1A2B3C-0D4E-4F60-8A7B-9C0D1E2F3A4B Thu Nov 26 08:00:00 2026" "stale_lock: the form of updating"

osascript -e 'display notification "Hi" with title "Auster"' extra; same $? 0 "osascript notification: exit 0"
same "$(cat "$STUB_NOTIFY_LOG")" "display notification \"Hi\" with title \"Auster\"	extra" "osascript notification: recorded, not shown"
same "$(osascript -e 'return 6 * 7')" 42 "osascript: anything else runs for real"

# --- the helpers
H=$(make_home "$W/h1" --zprofile-link --data-root-link)
case "$H" in *" "*"'"*"&"*) ok "make_home: a space, an apostrophe and &" ;; *) bad "make_home: $H" ;; esac
[ -L "$H/.zprofile" ] && ok "make_home: ~/.zprofile a link" || bad "make_home: zprofile"
[ -L "$H/Library/Application Support/Auster" ] && ok "make_home: the data root a link" || bad "make_home: data root"
H2=$(make_home "$W/h2")
[ -f "$H2/.zprofile" ] && [ ! -L "$H2/.zprofile" ] && ok "make_home: a plain ~/.zprofile by default" || bad "make_home: plain"

mkdir -p "$W/snap/sub"; printf 'abcdef' > "$W/snap/sub/f"; printf 'x' > "$W/snap/g"; ln -s sub/f "$W/snap/l"
s1=$(snapshot "$W/snap")
printf 'abcdeg' > "$W/snap/sub/f"
s2=$(snapshot "$W/snap")
same "$(diff <(echo "$s1") <(echo "$s2") | grep -c '^[<>]')" 2 "snapshot: one changed byte, one line differs"
case "$(diff <(echo "$s1") <(echo "$s2") | grep '^>')" in *$'\tsub/f') ok "snapshot: the changed file named" ;; *) bad "snapshot: which line" ;; esac
chmod 600 "$W/snap/g"; s3=$(snapshot "$W/snap")
[ "$s2" != "$s3" ] && ok "snapshot: a changed mode" || bad "snapshot: mode not seen"
case "$s1" in *$'-> sub/f\tl'*) ok "snapshot: a link and its target" ;; *) bad "snapshot: link" ;; esac

same "$(model_standins "$W/models" | cut -f1,2 | tr '\t\n' ' ')" \
  "standin-a.gguf 3400 standin-b.gguf 2040 standin-a-wrong.gguf 3400 standin-a-short.gguf 1700 " "model_standins: names and sizes"
cmp -s "$W/models/standin-a.gguf" "$W/models/standin-a-wrong.gguf" && bad "model_standins: wrong equals good" || ok "model_standins: same size, other content"

R=$TESTS/fixtures/registry
for size in 524288 524289 1048577; do
  registry_sized "$R/good-v0.1.0.tsv" "$size" "$W/reg-$size"
  same "$(stat -f %z "$W/reg-$size")" "$size" "registry_sized: exactly $size bytes"
  same "$(awk 'length($0) > 1000' "$W/reg-$size" | wc -l | tr -d ' ')" 0 "registry_sized $size: no line over 1,000 bytes"
done
same "$(head -c "$(stat -f %z "$R/good-v0.1.0.tsv")" "$W/reg-524288" | cmp - "$R/good-v0.1.0.tsv" && echo same)" same "registry_sized: the registry unchanged at the start"

# --- the registry fixtures
same "$(sed -n 9p "$R/line-1000.tsv" | awk '{print length($0)}') $(sed -n 9p "$R/line-1001.tsv" | awk '{print length($0)}')" "1000 1001" "registry: lines of 1,000 and 1,001 bytes"
same "$(grep -c $'\r$' "$R/crlf-all.tsv") $(grep -c $'\r$' "$R/crlf-line.tsv")" "8 1" "registry: CRLF endings"
same "$(head -1 "$R/format-2.tsv" | cut -f2)" 2 "registry: format 2"
same "$(head -8 "$R/good-v0.2.0.tsv" | tail -7)" "$(tail -7 "$R/good-v0.1.0.tsv")" "registry v0.2.0: v0.1.0's lines kept as they were"
B=$R/boundary
tail -n +2 "$B/MANIFEST" | while IFS=$'\t' read -r f with lines what; do
  [ -f "$B/$f" ] || { bad "boundary: $f is missing"; continue; }
  [ "$with" != - ] || continue
  d=$(diff "$B/$with" "$B/$f" | grep -E '^[0-9]' | sed -E 's/^([0-9]+)(,[0-9]+)?[acd].*/\1\2/' | paste -sd, -)
  [ "$f" = in-withdraw.tsv ] && { same "$d" 6 "boundary in-withdraw: in-upper and one line"; continue; }
  same "$d" "$lines" "boundary $f differs from $with on line $lines only"
done > "$W/boundary.out"
cat "$W/boundary.out"
FAILS=$((FAILS + $(grep -c '^FAIL' "$W/boundary.out")))
same "$(ls "$B" | grep -v MANIFEST | sort)" "$(tail -n +2 "$B/MANIFEST" | cut -f1 | sort)" "boundary: every file in MANIFEST and every MANIFEST line a file"

P=$TESTS/fixtures/phase-1
if [ -f "$ROOT/scripts/phase-1/questions.json" ]; then   # not in the copies tests/run.sh makes for mutants
  cmp -s "$P/questions.json" "$ROOT/scripts/phase-1/questions.json" && ok "phase 1: the questions are the repo's" || bad "phase 1: questions differ"
fi
same "$(grep -c '"pass": true' "$P/q56-A-replies.json") $(grep -c '"pass": true' "$P/q56-B-replies.json")" "52 53" "phase 1: 52 and 53 of the replies pass"
same "$(grep -c '"n": ' "$P/q56-A-replies.json") $(grep -c '"n": ' "$P/q56-B-replies.json")" "56 56" "phase 1: 56 replies each"

# --- nothing here reaches the network or a real engine
if grep -n -E '/usr/bin/curl|Library/Developer|llama-b[0-9]+/' "$TESTS"/stubs/* "$TESTS/helpers.sh" "$TESTS/stub-lib.sh"; then
  bad "a stub or helper names the real curl or a real engine"
else ok "no stub or helper names the real curl or a real engine"; fi

# --- the records of two and three recipes (tests/fixtures/records/README), as common/auster reads them
records_check() { # DATA -> one line for anything out of place; nothing when every record reads and every file is named
  local s h e
  ( . "$ROOT/common/auster"; AU_DATA=$1
    for s in "$1"/builds/r*/serving "$1"/builds/r*/kept/* "$1"/builds/r*/failed/*; do
      [ -e "$s" ] || continue
      case "$s" in */serving) au_desc_read "$s" ;; *) au_entry_read "$s" ;; esac || { echo "unreadable ${s#"$1"/}"; continue; }
      for h in "$AU_SV_ENGINE" "$AU_SV_MODEL" "$AU_SV_TEMPLATE" "$AU_SV_SYSTEM" "$AU_SV_TEST"; do
        [ "$(shasum -a 256 < "$1/store/$h" 2>/dev/null | cut -c1-64)" = "$h" ] || echo "${s#"$1"/} names $h, not in store/"
        echo "$h" >> "$1.named"
      done
      [ "$(shasum -a 256 < "$1/engines/$AU_SV_ENGINE/files" 2>/dev/null | cut -c1-64)" = "$AU_SV_LIST" ] || echo "${s#"$1"/}: its engine's list"
    done
    for e in "$1"/engines/*; do au_list "$e/root" | cmp -s - "$e/files" || echo "engines/${e##*/}: files is not its list"; done
    for s in "$1"/store/*; do grep -qx "${s##*/}" "$1.named" || echo "store/${s##*/} is named by no descriptor"; done
    for s in "$1"/builds/r*; do
      au_hold_read "${s##*/}"; [ "$AU_HOLD" = ok ] || [ "$AU_HOLD" = absent ] || echo "${s##*/}: hold $AU_HOLD"
      au_start_read "${s##*/}" || echo "${s##*/}: start unreadable"
    done
    au_mac_read; [ "$AU_MAC" = ok ] || echo "mac $AU_MAC"
    au_localname_read; [ "$AU_LN" = ok ] || echo "local-name $AU_LN"
    AU_UID=$(id -u); e=$(au_own_tree "$1") || echo "ownership: $e" )
}
for n in two three; do
  records_fixture "$n" "$W/records-$n"
  same "$(records_check "$W/records-$n")" "" "records of $n recipes: every record reads, every sha256 named is in store/, and every file there is named"
done
same "$(ls "$W/records-two/builds" | grep -c '^r'):$(ls "$W/records-three/builds" | grep -c '^r')" "2:3" "two recipes, and three"
same "$(diff -r "$W/records-two" "$W/records-three" | sed -E 's/[0-9a-f]{64}/<sha>/' | sort)" "Only in $W/records-three/builds: r6xnosrsvgruc
Only in $W/records-three/store: <sha>
Only in $W/records-three/store: <sha>
Only in $W/records-three/store: <sha>" "three/ is two/ and recipe C, with its three files"
[ "$(stat -f %Lp "$W/records-three/builds")$(stat -f %Lp "$W/records-three/builds/rapdsanqlj2eu/serving")$(stat -f %Lp "$W/records-three/store/$(ls "$W/records-three/store" | head -n 1)")" = 700600444 ] &&
  ok "records_fixture: folders 0700, records 0600, store/ 0444" || bad "records_fixture: modes"

stub_cleanup
done_
