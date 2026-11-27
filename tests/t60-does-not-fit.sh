# T60: a candidate that does not fit, whose stub engine answers HTTP 500 after a "ready" /health (as in
# phase 1 step 11), fails the recipe's test; one that fits passes whatever its speed; the test's speed
# is reported and never decides the result, and the test writes it nowhere: it leaves no file behind, so
# that only the server check after the switch can set this Mac's baseline (B3 step 13, built by U5).
# The test file is assets/household-test.json, the one the registry's builds name. Mutants:
# tests/mutants/T60a to T60c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
stub_env
W=$(mktemp -d "${TMPDIR%/}/t60.XXXXXX")
RT="$ROOT/common/recipe-test.js"
KEY=9b2e4d6f8a0c1e3f5a7b9c1d3e5f7a9b
mkdir -p "$W/case" "$W/cwd" "$W/tmp"
cp "$ROOT/assets/household-test.json" "$W/case/test.json"
printf '%s\n' "$KEY" > "$W/case/test.key"; chmod 600 "$W/case/test.key"
export STUB_CLOCK="$W/clock"; echo 1764150000 > "$STUB_CLOCK"
engine_set 'port=18611' behaviour http500
engine_set 'port=18612' behaviour ok
engine_start -m standin-a.gguf --port 18611 --api-key-file "$W/case/test.key" > /dev/null
engine_start -m standin-b.gguf --port 18612 --api-key-file "$W/case/test.key" > /dev/null
good() { # FILE RATE -> answers for 18612: every question answered well, every answer at RATE tokens a second
  awk -F'\t' -v r="$2" '{ print $2 "\t" $3 "\t" r "\t0" }' "$TESTS/fixtures/recipe-test/answers.tsv" > "$1"
  printf 'Count from 1 to\t1\\n2\\n3\t%s\t0\n' "$2" >> "$1"
  engine_live 18612 answers "$1"
}
rt() { # PORT -> stdout in $W/out, exit code in RC; run from an empty folder, with TMPDIR $W/tmp
  ( cd "$W/cwd" && TMPDIR="$W/tmp" osascript -l JavaScript "$RT" "$W/case/test.json" "http://127.0.0.1:$1" "$W/case/test.key" > "$W/out" 2> "$W/err" ); RC=$?
}
result() { tail -1 "$W/out"; }

# --- does not fit: /health says ready, every question HTTP 500
same "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18611/health)" 200 "the candidate that does not fit: /health 200"
rt 18611
same "$RC $(result)" "1 result fail 0/12 mandatory 0/8 secs 0/180" "the candidate that does not fit: fail"
same "$(grep -c '^Q[0-9][0-9] FAIL .*: HTTP 500 in 0 s$' "$W/out")" 12 "every question: HTTP 500"
same "$(sed -n 13p "$W/out")" "speed none (HTTP 500)" "no speed from it"

# --- fits, very slow and very fast: the same result
before=$(snapshot "$W/case"; snapshot "$W/cwd"; snapshot "$HOME")
good "$W/slow" 0.4
rt 18612
same "$RC $(result)" "0 result pass 12/12 mandatory 8/8 secs 0/180" "a candidate that fits at 0.4 tok/s: pass"
same "$(sed -n 13p "$W/out")" "speed 0.4 tok/s (reported only: it never decides the result)" "its speed is reported"
grep -v '^speed ' "$W/out" > "$W/slow.out"
good "$W/fast" 400
rt 18612
same "$RC $(result)" "0 result pass 12/12 mandatory 8/8 secs 0/180" "the same candidate at 400 tok/s: pass"
same "$(sed -n 13p "$W/out")" "speed 400.0 tok/s (reported only: it never decides the result)" "its speed is reported"
grep -v '^speed ' "$W/out" > "$W/fast.out"
cmp -s "$W/slow.out" "$W/fast.out" && ok "every line but the speed is the same at either speed" || bad "the speed changed another line: $(diff "$W/slow.out" "$W/fast.out")"
case "$(result)" in *400*|*tok*) bad "the result line carries the speed" ;; *) ok "the result line carries no speed" ;; esac

# --- the test writes nothing: its own folder gone, and nothing beside the test file, in the folder it
# ran in, or in the home folder
same "$(snapshot "$W/case"; snapshot "$W/cwd"; snapshot "$HOME")" "$before" "no file written beside the test file, where it ran, or at home"
same "$(ls -A "$W/tmp")" "" "nothing left in TMPDIR"

stub_cleanup
done_
