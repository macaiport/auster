# T102: the real `--list-devices` output of b12359 gives the GPU limit (C1, B3 step 4); the altered copies
# (columns swapped, no MTL0) refuse with a reason, and no limit is guessed, not even from the `mac` record.
# Also C1's one place for the figures: a test variable over a measurement over the `mac` record, and the
# `mac` record's reader, whose form V3 defines (common/capability-lib.js's header) and U2 writes. The
# hostile cases every record of D3.1 must survive are T6's (U2). Mutant: tests/mutants/T102a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/capability-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t102.XXXXXX")
LD=$TESTS/fixtures/list-devices

measure() { # LIST-DEVICES-FILE [OPTION...] -> cap with the measured memory of a 64 GB Mac
  local f=$1
  shift
  cap "$HREG" $HH --ram $GB64 --list-devices "$f" "$@"
}
o=$(measure "$LD/b12359.txt")
same "$(kind "$o" figures | cut -f2,6)" "53084${T}measured" "b12359's output: GPU limit 53,084 MiB, measured"
same "$(pick "$o")" "$B1 4 32768 0" "and the choice made with it: order 1 at 32,768"
same "$(pick "$(measure "$LD/columns-swapped.txt")")" "refused figures gpu,mtl0-form 3" "columns swapped: refused, the MTL0 line not in its form"
same "$(kind "$(measure "$LD/columns-swapped.txt")" figures | cut -f2,6)" "-${T}-" "columns swapped: no limit at all"
same "$(pick "$(measure "$LD/no-mtl0.txt")")" "refused figures gpu,no-mtl0 3" "no MTL0: refused, saying there is no MTL0 line"

# The same, through the stub engine, as the installer runs it
stub_env
engine_set '*' list-devices b12359
"$TESTS/stubs/llama-server" --list-devices > "$W/stub-real" 2>/dev/null
mv "$STUB_ENGINE_DIR/config" "$STUB_ENGINE_DIR/config.real"; engine_set '*' list-devices columns-swapped
"$TESTS/stubs/llama-server" --list-devices > "$W/stub-swapped" 2>/dev/null
same "$(kind "$(measure "$W/stub-real")" figures | cut -f2):$(kind "$(measure "$W/stub-swapped")" refused | cut -f3)" "53084:gpu,mtl0-form" \
  "the stub engine's output: the same limit, and the same refusal"

# Other shapes the output must not be read from
{ cat "$LD/b12359.txt"; sed -n 2p "$LD/b12359.txt"; } > "$W/twice"
same "$(kind "$(measure "$W/twice")" refused | cut -f3)" "gpu,mtl0-twice" "two MTL0 lines: refused"
sed 1d "$LD/b12359.txt" > "$W/headless"
same "$(kind "$(measure "$W/headless")" refused | cut -f3)" "gpu,not-list-devices" "no 'Available devices:' line: refused"
{ sed -n 2p "$LD/b12359.txt"; sed -n 1p "$LD/b12359.txt"; sed -n 3p "$LD/b12359.txt"; } > "$W/before"
same "$(kind "$(measure "$W/before")" refused | cut -f3)" "gpu,mtl0-form" "the MTL0 line before the header: refused"
sed 's/(53084 MiB/(0 MiB/' "$LD/b12359.txt" > "$W/zero"
same "$(kind "$(measure "$W/zero")" refused | cut -f3)" "gpu,mtl0-figure" "a total of 0 MiB: refused"
sed 's/(53084 MiB/(053084 MiB/' "$LD/b12359.txt" > "$W/lead"
same "$(kind "$(measure "$W/lead")" refused | cut -f3)" "gpu,mtl0-form" "a total with a leading zero: refused"
sed 's/^  MTL0/MTL0/' "$LD/b12359.txt" > "$W/indent"
same "$(kind "$(measure "$W/indent")" refused | cut -f3)" "gpu,mtl0-form" "the MTL0 line not indented as the engine prints it: refused"

# --- C1: the order of the sources
mac_record "$W/mac" 27648 $GB36
same "$(kind "$(cap "$HREG" $HH --mac "$W/mac")" figures | cut -f2,3,6,7)" "27648${T}$GB36${T}mac${T}mac" "the mac record alone: its two figures"
same "$(kind "$(measure "$LD/b12359.txt" --mac "$W/mac")" figures | cut -f2,3,6,7)" "53084${T}$GB64${T}measured${T}measured" "a measurement wins over the record"
same "$(pick "$(measure "$LD/no-mtl0.txt" --mac "$W/mac")")" "refused figures gpu,no-mtl0 3" "a measurement refused is never replaced by the record: no limit is guessed"
o=$(AU_GPU_MIB=40000 measure "$LD/columns-swapped.txt" --mac "$W/mac")
same "$(kind "$o" figures | cut -f2,6)" "40000${T}test" "a test variable wins over everything"
same "$(pick "$(AU_GPU_MIB=4e4 measure "$LD/columns-swapped.txt")")" "refused figures gpu,mtl0-form 3" "4e4 is not a test value: the measurement decides, and it refuses"
same "$(pick "$(cap "$HREG" $HH --ram $GB64)")" "refused figures gpu,missing 3" "no source of the GPU limit at all: refused"
same "$(pick "$(cap "$HREG" $HH --list-devices "$LD/b12359.txt")")" "refused figures memory,missing 3" "no source of the memory: refused"

# --- The mac record's reader
mac_says() { # FILE -> the figures line's GPU limit and its source, or the refusal
  local o
  o=$(cap "$HREG" $HH --mac "$1")
  if [ -n "$(kind "$o" refused)" ] && [ "$(kind "$o" refused | cut -f3)" != gpu,missing ]; then kind "$o" refused | cut -f2,3 | tr '\t' ' '
  else kind "$o" figures | cut -f2,6 | tr '\t' ' '; fi
}
same "$(mac_says "$W/mac")" "27648 mac" "a record in form: read"
variant() { # NAME SED-EXPRESSION -> the record with the change, as a file
  sed "$2" "$W/mac" > "$W/mac-$1"
  printf '%s\n' "$W/mac-$1"
}
same "$(mac_says "$(variant newer 's/^auster-record 1$/auster-record 2/')")" "figures mac,newer" "format 2: Auster refuses, even with nothing else to go on"
o=$(measure "$LD/b12359.txt" --mac "$W/mac-newer")
same "$(kind "$o" refused | cut -f2,3)" "figures${T}mac,newer" "format 2 with a measurement: still refused, never misread"
same "$(mac_says "$(variant zero 's/^auster-record 1$/auster-record 0/')")" "- -" "format 0: absent"
same "$(mac_says "$(variant order '2{h;d;};3G')")" "- -" "two keys swapped: absent"
same "$(mac_says "$(variant spaces 's/^gpu-mib\t/gpu-mib /')")" "- -" "a space for the tab: absent"
same "$(mac_says "$(variant extra '$a\
chip\tm5')")" "- -" "a key this version does not know: absent"
same "$(mac_says "$(variant missing '/^router/d')")" "- -" "a key missing: absent"
same "$(mac_says "$(variant ceiling 's/^gpu-mib\t.*/gpu-mib\t1048577/')")" "- -" "a GPU limit over 1,048,576 MiB: absent"
same "$(mac_says "$(variant router 's/^router\t.*/router\t0:1b:2c:3d:4e:5f/')")" "- -" "a router address as arp prints it, unpadded: absent"
same "$(mac_says "$(variant subst 's/^macos\t.*/macos\t$(touch f)/')")" "- -" "a command in a value: absent"
if [ -e f ] || [ -e "$W/f" ]; then bad "a value was run"; else ok "and nothing was run"; fi
same "$(mac_says "$(variant crlf 's/$/\r/')")" "- -" "CR LF endings: absent"
printf '%s' "$(cat "$W/mac")" > "$W/mac-cut"
same "$(mac_says "$W/mac-cut")" "- -" "no final newline (cut short): absent"
{ cat "$W/mac"; head -c 1100 /dev/zero | tr '\0' x; echo; } > "$W/mac-big"
same "$(mac_says "$W/mac-big")" "- -" "over 1,024 bytes: absent"
ln -s "$W/mac" "$W/mac-link"
same "$(mac_says "$W/mac-link")" "- -" "a link to a good record: absent"
mkdir "$W/mac-dir"
same "$(mac_says "$W/mac-dir")" "- -" "a folder: absent"
same "$(cd "$W" && osascript -l JavaScript -e "ObjC.import('Foundation');
function auLoad(p) { return ObjC.unwrap(\$.NSString.stringWithContentsOfFileEncodingError(p, \$.NSUTF8StringEncoding, null)); }
function run(argv) { eval(auLoad(argv[0] + '/common/registry-lib.js')); eval(auLoad(argv[0] + '/common/capability-lib.js'));
  var r = auCapReadFile(argv[1], AU_CAP_MAX.mac), m = auCapParseMac(r.bytes, r.big);
  return [m.state, m.gpuMiB, m.ramBytes, m.macos, m.measured, m.router, m.keepAwake].join(' '); }" "$ROOT" "$W/mac")" \
  "ok 27648 $GB36 27.2.1 2026-11-26T15:04:05Z 0a:1b:2c:3d:4e:5f true" "the reader gives every field, keep-awake as true or false"
done_
