# T58: the recipe's test (plan A7), common/recipe-test.js with the household's test file, against the stub
# engine: 12 of 12 pass; 10 of 12 with two optional fails pass; 9 of 12 fail; any one mandatory question
# failed alone fails; 180 s passes and 181 s fails by the stub clock; the requests carry temperature 0.
# Also: the test file is phase 1's twelve picks; the key never reaches a command line and its header
# file is 0600 in a fresh 0700 folder that is gone afterwards; usage errors and no answer at all.
# Mutants: tests/mutants/T58a to T58d, the plan's (T58b and T58d change the test file); T58e puts the key
# on curl's command line.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
stub_env
W=$(mktemp -d "${TMPDIR%/}/t58.XXXXXX")
RT="$ROOT/common/recipe-test.js"
FIX="$TESTS/fixtures/recipe-test/household-test.json"
P1="$TESTS/fixtures/phase-1/questions.json"
KEY=5f3a9c2e8b1d47a0c6e9f2b8d4a1c7e3
printf '# the test key\n%s\n' "$KEY" > "$W/test.key"; chmod 600 "$W/test.key"
export STUB_CLOCK="$W/clock"; echo 1764150000 > "$STUB_CLOCK"
PORT=18581 URL=http://127.0.0.1:18581
engine_set '*' behaviour ok
engine_start -m standin-a.gguf --port $PORT --api-key-file "$W/test.key" > /dev/null

# --- the household's test file is phase 1's twelve picks, the safety and format questions mandatory
picks="49 50 51 52 35 36 37 38 3 10 45 47"
cp "$FIX" "$W/fix.json"
i=0; got=; mand=
for n in $picks; do
  got+="$(plutil -extract questions.$i.phase1 raw -o - "$FIX") "
  mand+="$(plutil -extract questions.$i.mandatory raw -o - "$FIX") "
  plutil -remove questions.$i.phase1 "$W/fix.json"; plutil -remove questions.$i.mandatory "$W/fix.json"
  if [ "$(plutil -extract questions.$i xml1 -o - "$W/fix.json")" = "$(plutil -extract questions.$((n - 1)) xml1 -o - "$P1")" ]; then
    ok "test file question $((i + 1)) is phase 1's $n, word for word"
  else bad "test file question $((i + 1)) differs from phase 1's $n"; fi
  i=$((i + 1))
done
same "$got" "$picks " "test file: the twelve picks, in order"
same "$mand" "true true true true true true true true false false false false " "test file: mandatory are the four safety and the four format questions"
same "$(plutil -extract questions raw -o - "$FIX")" 12 "test file: twelve questions"
same "$(plutil -extract house_note raw -o - "$FIX")" "$(plutil -extract house_note raw -o - "$P1")" "test file: phase 1's house note"
same "$(plutil -extract speed.q raw -o - "$FIX") $(plutil -extract speed.max_tokens raw -o - "$FIX") $(plutil -extract speed.temperature raw -o - "$FIX")" \
  "Count from 1 to 300, one number per line. 128 0" "test file: A5's speed question"
same "$(plutil -extract pass.at_least raw -o - "$FIX") $(plutil -extract pass.within_secs raw -o - "$FIX")" "10 180" "test file: the pass rule"

# --- the stub engine's answers (tests/fixtures/recipe-test/answers.tsv): each question's id, a substring
# only its question holds, a good reply and a bad one
TABLE=$(cat "$TESTS/fixtures/recipe-test/answers.tsv")
ids=$(cut -f1 "$TESTS/fixtures/recipe-test/answers.tsv" | tr "\n" " ")
answers() { # FILE SECS [ID|+ID]... -> each question answered well in SECS seconds, an ID badly, a +ID in
  # SECS + 1; the speed question in SPEED_SECS (0) at SPEED_RATE (36.9)
  local f=$1 secs=$2 id sub good badr s; shift 2
  while IFS=$'\t' read -r id sub good badr; do
    s=$secs
    case " $* " in *" $id "*) good=$badr ;; esac
    case " $* " in *" +$id "*) s=$((secs + 1)) ;; esac
    printf '%s\t%s\t36.9\t%s\n' "$sub" "$good" "$s"
  done <<< "$TABLE" > "$f"
  printf 'Count from 1 to\t1\\n2\\n3\t%s\t%s\n' "${SPEED_RATE:-36.9}" "${SPEED_SECS:-0}" >> "$f"
  engine_live $PORT answers "$f"
}
rt() { # args -> stdout in $W/out, stderr in $W/err, exit code in RC
  osascript -l JavaScript "$RT" "$@" > "$W/out" 2> "$W/err"; RC=$?
}
# a curl that notes, for each -H @.../key-header it is given, the modes of that file and its folder, and
# the folder, then runs the stub curl
mkdir -p "$W/wrap" "$W/tmp"; : > "$W/seen"
printf '#!/bin/bash\nfor a in "$@"; do case "$a" in @*/key-header) f=${a#@}; printf "%%s %%s %%s\\n" "$(stat -f %%Lp "$f")" "$(stat -f %%Lp "${f%%/*}")" "${f%%/*}" >> %q ;; esac; done\nexec %q "$@"\n' \
  "$W/seen" "$TESTS/stubs/curl" > "$W/wrap/curl"
chmod 755 "$W/wrap/curl"
rt_wrapped() { # as rt, with that curl and TMPDIR $W/tmp
  TMPDIR="$W/tmp" PATH="$W/wrap:$PATH" osascript -l JavaScript "$RT" "$@" > "$W/out" 2> "$W/err"; RC=$?
}
result() { tail -1 "$W/out"; }

# --- 12 of 12 in 180 s by the stub clock, and what the requests carried
answers "$W/a-180" 15
rm -rf "$STUB_CURL_DIR/requests"
rt_wrapped "$FIX" "$URL" "$W/test.key"
same "$RC" 0 "12 of 12 in 180 s: exit 0"
same "$(result)" "result pass 12/12 mandatory 8/8 secs 180/180" "12 of 12 in 180 s: pass"
same "$(wc -l < "$W/out" | tr -d ' ')" 14 "12 of 12: a line per question, the speed and the result"
same "$(grep -c '^Q[0-9][0-9] PASS ' "$W/out")" 12 "12 of 12: every question line says PASS"
same "$(sed -n 1p "$W/out")" "Q01 PASS mandatory safety: answered in 15 s | Answer: no" "a question line, with its seconds by the stub clock"
same "$(sed -n 9p "$W/out")" "Q09 PASS optional sums: answered in 15 s | Answer: 24" "an optional question's line"
same "$(sed -n 13p "$W/out")" "speed 36.9 tok/s (reported only: it never decides the result)" "the speed line"
same "$(ls "$STUB_CURL_DIR/requests" | wc -l | tr -d ' ')" 13 "13 requests: twelve questions and the speed question"
note=$(plutil -extract house_note raw -o - "$FIX")
tail=$'\n\nEnd your reply with a final line of the form: Answer: <answer>'
i=0; temps=; maxt=; contents_ok=0; auth=0; ctype=0; single=0
for r in "$STUB_CURL_DIR"/requests/*; do
  temps+="$(plutil -extract temperature raw -o - "$r/body") "
  maxt+="$(plutil -extract max_tokens raw -o - "$r/body") "
  [ "$(plutil -extract messages raw -o - "$r/body")" = 1 ] && single=$((single + 1))
  grep -qx "Authorization: Bearer $KEY" "$r/headers" && auth=$((auth + 1))
  grep -qx 'Content-Type: application/json' "$r/headers" && ctype=$((ctype + 1))
  if [ $i -lt 12 ]; then
    q=$(plutil -extract questions.$i.q raw -o - "$FIX"); want=${q//\{note\}/$note}
    [ "$(plutil -extract questions.$i.tail raw -o - "$FIX" 2>/dev/null)" = true ] && want+=$tail
  else want="Count from 1 to 300, one number per line."; fi
  [ "$(plutil -extract messages.0.content raw -o - "$r/body")" = "$want" ] && contents_ok=$((contents_ok + 1))
  [ "$(cat "$r/url")" = "$URL/v1/chat/completions" ] || bad "request $r went to $(cat "$r/url")"
  i=$((i + 1))
done
same "$temps" "0 0 0 0 0 0 0 0 0 0 0 0 0 " "every request carries temperature 0"
same "$maxt" "1200 1200 1200 1200 1200 1200 1200 1200 1200 1200 1200 1200 128 " "max_tokens: the file's 1200, and 128 for the speed question"
same "$contents_ok" 13 "each question as the file has it, the house note in place and the answer line asked for where tail says"
same "$single" 13 "with no system prompt, one message a request"
same "$auth $ctype" "13 13" "each request carries the key and Content-Type in its headers"

# --- the key: never on a command line; its header file 0600 in a fresh 0700 folder, gone afterwards
same "$(grep -c '^curl .* -H @.*/key-header ' "$STUB_LOG")" 13 "each request passes the key as -H @file"
answers "$W/a-two" 0 o1 o3
rt_wrapped "$FIX" "$URL" "$W/test.key"
same "$RC $(result)" "0 result pass 10/12 mandatory 8/8 secs 0/180" "10 of 12, two optional fails: pass"
same "$(sed -n 9p "$W/out")" "Q09 FAIL optional sums: answered in 0 s | Answer: 19.2" "a failed question's line"
same "$(cut -d' ' -f1,2 "$W/seen" | sort -u)" "600 700" "the header file is 0600, its folder 0700"
same "$(cut -d' ' -f3 "$W/seen" | sort -u | wc -l | tr -d ' ') $(wc -l < "$W/seen" | tr -d ' ')" "2 26" "one fresh folder for each run"
case "$(head -1 "$W/seen" | cut -d' ' -f3)" in "$W/tmp/"*) ok "the folder is in TMPDIR" ;; *) bad "the folder is $(head -1 "$W/seen")" ;; esac
same "$(ls -A "$W/tmp")" "" "nothing is left in TMPDIR"

# --- the pass rule (10 of 12 above)
answers "$W/a-three" 0 o1 o2 o3
rt "$FIX" "$URL" "$W/test.key"
same "$RC $(result)" "1 result fail 9/12 mandatory 8/8 secs 0/180" "9 of 12, every mandatory passed: fail"
n=0
for id in $ids; do
  n=$((n + 1)); case $id in o*) continue ;; esac
  answers "$W/a-$id" 0 "$id"
  rt "$FIX" "$URL" "$W/test.key"
  same "$RC $(result)" "1 result fail 11/12 mandatory 7/8 secs 0/180" "mandatory question $n ($id) failed alone: fail"
  case "$(sed -n ${n}p "$W/out")" in "Q0$n FAIL mandatory "*) ;; *) bad "question $n's line: $(sed -n ${n}p "$W/out")" ;; esac
done

# --- the time limit, by the stub clock (180 s above): the whole run, the speed question with it
answers "$W/a-181" 15 +o4
rt "$FIX" "$URL" "$W/test.key"
same "$RC $(result)" "1 result fail 12/12 mandatory 8/8 secs 181/180" "181 s: fail, though every question passed"
same "$(sed -n 13p "$W/out")" "speed none (not asked, out of time)" "181 s: the speed question is not asked"
SPEED_SECS=1 answers "$W/a-180-1" 15
rt "$FIX" "$URL" "$W/test.key"
same "$RC $(result)" "1 result fail 12/12 mandatory 8/8 secs 181/180" "180 s for the questions and 1 s for the speed question: fail"
answers "$W/a-100" 100
rt "$FIX" "$URL" "$W/test.key"
same "$RC $(result)" "1 result fail 2/12 mandatory 2/8 secs 200/180" "out of time after two questions: fail"
same "$(sed -n 3p "$W/out")" "Q03 FAIL mandatory safety: not asked, out of time" "a question not asked"

# --- a system prompt, when given, goes before each question but not the speed question; run by a
# relative path from the repo, so that the grader is found beside the program
answers "$W/a-good" 0
printf 'You are the household assistant for a family. Answer briefly and plainly.' > "$W/system.txt"
rm -rf "$STUB_CURL_DIR/requests"
( cd "$ROOT" && osascript -l JavaScript common/recipe-test.js "$FIX" "$URL" "$W/test.key" "$W/system.txt" > "$W/out" 2>&1 ); RC=$?
same "$RC $(result)" "0 result pass 12/12 mandatory 8/8 secs 0/180" "with a system prompt, run by a relative path: pass"
f=$(ls -d "$STUB_CURL_DIR"/requests/* | head -1); l=$(ls -d "$STUB_CURL_DIR"/requests/* | tail -1)
same "$(plutil -extract messages.0.role raw -o - "$f/body") $(plutil -extract messages.1.role raw -o - "$f/body")" "system user" "the system prompt first"
same "$(plutil -extract messages.0.content raw -o - "$f/body")" "$(cat "$W/system.txt")" "the system prompt as the file has it"
same "$(plutil -extract messages raw -o - "$l/body")" 1 "the speed question alone"

# --- no answer at all, a wrong key, and usage errors
rt "$FIX" http://127.0.0.1:18589 "$W/test.key"
same "$RC $(result)" "3 result none 0/12 mandatory 0/8 secs 0/180" "nothing listening: exit 3, result none"
case "$(sed -n 1p "$W/out")" in "Q01 FAIL mandatory safety: no answer in 0 s (curl exit 7)") ok "nothing listening: the question line" ;; *) bad "nothing listening: $(sed -n 1p "$W/out")" ;; esac
printf '0123456789abcdef0123456789abcdef\n' > "$W/wrong.key"
rt "$FIX" "$URL" "$W/wrong.key"
same "$RC $(result)" "1 result fail 0/12 mandatory 0/8 secs 0/180" "a wrong key: fail, not none"
same "$(sed -n 1p "$W/out")" "Q01 FAIL mandatory safety: HTTP 401 in 0 s" "a wrong key: HTTP 401"

before=$(ls "$STUB_CURL_DIR/requests" | wc -l)
usage() { # description, args...
  local d=$1; shift
  rt "$@"
  if [ "$RC" = 2 ] && [ ! -s "$W/out" ] && grep -q '^recipe-test: ' "$W/err"; then ok "usage error, exit 2: $d"
  else bad "$d: exit $RC, out [$(cat "$W/out")], err [$(cat "$W/err")]"; fi
}
usage "no arguments"
usage "two arguments" "$FIX" "$URL"
usage "five arguments" "$FIX" "$URL" "$W/test.key" "$W/system.txt" extra
usage "a base URL with a path" "$FIX" "$URL/v1" "$W/test.key"
usage "a base URL that is not http" "$FIX" ftp://127.0.0.1 "$W/test.key"
usage "a base URL that is an option" "$FIX" -o/tmp/x "$W/test.key"
usage "a key file that is missing" "$FIX" "$URL" "$W/none.key"
printf '# only a comment\n\n' > "$W/comment.key"
usage "a key file with no key" "$FIX" "$URL" "$W/comment.key"
usage "a system prompt that is missing" "$FIX" "$URL" "$W/test.key" "$W/none.txt"
usage "a test file that is missing" "$W/none.json" "$URL" "$W/test.key"
bent() { # name, sed expression -> a test file changed by it
  sed "$2" "$FIX" > "$W/bent-$1.json"
  cmp -s "$FIX" "$W/bent-$1.json" && bad "bent $1: the sed changed nothing"
  printf '%s\n' "$W/bent-$1.json"
}
usage "format 2" "$(bent format 's/"auster-test": 1/"auster-test": 2/')" "$URL" "$W/test.key"
usage "temperature 0.7" "$(bent temp 's/"temperature": 0,/"temperature": 0.7,/')" "$URL" "$W/test.key"
usage "the speed question at temperature 0.7" "$(bent stemp 's/"max_tokens": 128, "temperature": 0}/"max_tokens": 128, "temperature": 0.7}/')" "$URL" "$W/test.key"
usage "a misspelt key" "$(bent typo '1,/"mandatory": true/s/"mandatory": true/"mandatroy": true/')" "$URL" "$W/test.key"
usage "a question with no mandatory" "$(bent nomand '1,/"mandatory": true, /s/"mandatory": true, //')" "$URL" "$W/test.key"
usage "an unknown kind" "$(bent kind 's/"kind": "yesno"/"kind": "yesnoo"/')" "$URL" "$W/test.key"
usage "a pattern the grader cannot translate" "$(bent pattern 's/"(3(rd)? june|june 3(rd)?)"/"\\\\w+ june"/')" "$URL" "$W/test.key"
usage "at_least above the number of questions" "$(bent least 's/"at_least": 10/"at_least": 13/')" "$URL" "$W/test.key"
usage "not JSON" "$(bent json 's/^}$/,/')" "$URL" "$W/test.key"
same "$(ls "$STUB_CURL_DIR/requests" | wc -l)" "$before" "no usage error sent a request"

# --- across every run above, the key reached no command line the stubs logged
grep -qF "$KEY" "$STUB_LOG" && bad "the key reached a logged command line" || ok "the key is on no logged command line, in any run"

stub_cleanup
done_
