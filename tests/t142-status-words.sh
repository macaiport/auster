# T142 (the conventions' audit, 2026-11-28; docs/conventions.md section 2, "Plain words"; B6): `auster status` says its
# records in plain words, and `auster remove` its sizes as Finder gives them. Status's serving line gives the people at a
# time and each one's context in tokens, with commas; the engine job's last start (each of the five codes, written into
# builds/<recipe>/start) and the check job's last probe (each of its seven results, written into _update/engine) each get a
# fixed sentence, the code after it in parentheses and never alone; the time the engine was stopped (builds/stopped, for
# the household and for open) is given as `2026-11-28 09:15:00 UTC`, not in the record's own form. `auster remove`,
# answered yes and then no, lists what is left with each size as au_bytes gives it (du's KiB times 1,024), never in KB.
# Mutants: tests/mutants/T142a (the context printed raw, without tokens), T142b (a start code printed alone), T142c (a probe
# result printed alone), T142d (the stopped time in the record's form), T142e (remove's sizes in KB).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
START="$DATA/builds/$IR/start" PROBE="$DATA/_update/engine" STOPPED="$DATA/builds/stopped"

auster status
same "$RC" 0 "status: exit 0"
outsays "Serving build $IB1 for 4 people at a time, each with a context of 32,768 tokens, on port 8484." "  ...its serving line, in tokens with commas"

# --- the engine job's last start, each code
start_is() { printf 'auster-record 1\ncode\t%s\naddress\t-\nboot\t-\ntime\t1764300000\n' "$1" > "$START"; }
while IFS='|' read -r code words; do
  start_is "$code"
  auster status < /dev/null
  outsays "The engine job's last start: $words ($code)." "start $code: in a sentence, the code after it"
  grep -q "last start: $code\.$" "$W/out" && bad "  ...the code alone" || ok "  ...not the code alone"
done <<'EOF'
starting|it started the engine
keys|the engine's key file (keys/engine.keys) holds no key it can use, so it did not start the engine
engine-hash|a check it makes at every start failed
not-home|this Mac is not on the home network Auster was installed on, so it did not start the engine
no-network|this Mac had no network connection, so it did not start the engine
EOF
rm -f "$START"

# --- the check job's last probe, each result
probe_is() { printf 'auster-record 1\nprobe\t%s\t%s\t1764300000\nfailures\t0\naddress\t10.0.0.5\ntold-probe\t-\ntold-address\t10.0.0.5\ntold-fit\tno\n' "$1" "$2" > "$PROBE"; }
while IFS='|' read -r result speed words; do
  probe_is "$result" "$speed"
  auster status < /dev/null
  outsays "The check job's last probe: $words ($result)." "probe $result: in a sentence, the result after it"
  grep -q "last probe: $result[.,]" "$W/out" && bad "  ...the result alone" || ok "  ...not the result alone"
done <<'EOF'
ok|36.9|the server answered, at 36.9 tokens a second
slow|12.5|the server answered slowly, at 12.5 tokens a second, below half the speed its server check measured
open|-|the server answered a request that carried no key
broken|-|the server is up, but failed to answer a question
failed|-|the server did not answer a question as it should
down|-|nothing was listening on the server's address
stopped|-|none was made, since the server is stopped
EOF
rm -f "$PROBE"

# --- the time the engine was stopped
printf 'auster-record 1\thousehold\t2026-11-28T09:15:00Z\n' > "$STOPPED"
auster status
outsays "The engine is stopped: the household stopped it (auster stop) at 2026-11-28 09:15:00 UTC." "stopped by the household: the time as status gives a time"
grep -q '2026-11-28T09:15:00Z' "$W/out" && bad "  ...in the record's form" || ok "  ...not in the record's form"
printf 'auster-record 1\topen\t2026-11-28T09:16:30Z\n' > "$STOPPED"
auster status
outsays "The engine is stopped: Auster stopped it at 2026-11-28 09:16:30 UTC, because it answered a request that carried no key." "stopped as open: the time as status gives a time"
rm -f "$STOPPED"

# --- remove: what is left, with sizes as Finder gives them
ANSWERS=$'yes\nno\n' auster remove
same "$RC" 0 "remove, answered yes then no: exit 0"
outsays "What is left, in $DATA:" "  ...it lists what is left"
k=$(du -sk "$DATA/store" | cut -f1)
size=$( . "$DATA/bin/auster"; au_bytes $((k * 1024)) )
grep -qE "^  store +$size\$" "$W/out" && ok "  ...store/ with its size from du, as au_bytes gives it ($size)" || bad "  ...store/ is not given as $size: $(cat "$W/out")"
grep -q ' KB$' "$W/out" && bad "  ...a size in KB" || ok "  ...no size in KB"
same "$(sed -n '/^What is left/,$p' "$W/out" | grep '^  ' | grep -cvE ' [0-9][0-9,.]* (bytes|MB|GB)$')" 0 "  ...every size in bytes, MB or GB"
done_
