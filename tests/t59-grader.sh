# T59: the JavaScript grader (common/grade-lib.js, loaded as common/recipe-test.js loads it) gives the
# verdict of scripts/phase-1/quiz.py on every one of phase 1's saved replies for both builds, 112 in all,
# and the same verdict twice. Also on the constructed cases of tests/fixtures/recipe-test/grader-cases.json,
# whose verdicts are quiz.py's too: one for each rule (the last "Answer:", fractions, mixed numbers, the
# value after the last "=", Python's whitespace, json.loads), so that a rule the saved replies happen not
# to exercise is still held. Mutants: tests/mutants/T59a and T59b.
. "$TESTS/lib.sh"
W=$(mktemp -d "${TMPDIR%/}/t59.XXXXXX")
P=$TESTS/fixtures/phase-1
cat > "$W/regrade.js" <<'EOF'
// regrade.js <grade-lib.js> <questions.json> <replies.json>: "n true|false" for each reply, in order
ObjC.import('Foundation');
function auLoad(p) { return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null)); }
function run(argv) {
  eval(auLoad(argv[0]));
  var qs = JSON.parse(auLoad(argv[1])).questions;
  return JSON.parse(auLoad(argv[2])).map(function (r) { return r.n + ' ' + auGrade(qs[r.n - 1], r.reply); }).join('\n');
}
EOF
regrade() { osascript -l JavaScript "$W/regrade.js" "$ROOT/common/grade-lib.js" "$P/questions.json" "$1"; }
saved() { # replies file -> "n true|false" for each record, read by plutil, not by the grader
  local f=$1 i=0 count
  count=$(grep -c '"n": ' "$f")
  while [ $i -lt "$count" ]; do
    printf '%s %s\n' "$(plutil -extract $i.n raw -o - "$f")" "$(plutil -extract $i.pass raw -o - "$f")"
    i=$((i + 1))
  done
}

total=0
for f in "$P/q56-A-replies.json" "$P/q56-B-replies.json" "$TESTS/fixtures/recipe-test/grader-cases.json"; do
  name=${f##*/}
  saved "$f" > "$W/want"
  regrade "$f" > "$W/got1"; rc=$?
  regrade "$f" > "$W/got2"
  same "$rc" 0 "$name: the grader ran"
  n=$(wc -l < "$W/want" | tr -d ' ')
  agree=$(paste -d'|' "$W/want" "$W/got1" | awk -F'|' '$1 == $2' | wc -l | tr -d ' ')
  same "$agree of $(wc -l < "$W/got1" | tr -d ' ')" "$n of $n" "$name: quiz.py's verdict on every one"
  paste -d'|' "$W/want" "$W/got1" | awk -F'|' '$1 != $2 { print "      quiz.py " $1 ", the grader " $2 }'
  cmp -s "$W/got1" "$W/got2" && ok "$name: the same verdicts twice" || bad "$name: the verdicts differ between two runs"
  case $name in q56-*) total=$((total + n)) ;; esac
done
same "$total" 112 "phase 1's saved replies: 112 in all"
same "$(grep -c '"pass": false' "$TESTS/fixtures/recipe-test/grader-cases.json") $(grep -c '"pass": true' "$TESTS/fixtures/recipe-test/grader-cases.json")" \
  "21 28" "the constructed cases: 21 that fail and 28 that pass"

done_
