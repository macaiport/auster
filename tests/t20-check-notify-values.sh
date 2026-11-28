# T20 (U7; B5 step 6, D3.5): a version and a label containing ", \, a newline, a backtick and $(touch f) never reach a
# notification. The deployed rule file is replaced by a stand-in whose --refresh says it fetched and whose --noted and
# --recipes print what the test puts beside it: a version (--noted's line) and a recipe's label (the 13th field of the
# one recipe line whose word is waiting). For each case the stub notifier gets one notification, whose script is the
# fixed one (`on run argv`, `display notification (item 1 of argv) with title "Auster"`, `end run`) and whose only
# argument is one of the four fixed sentences: the value that fails its pattern is left out, and the sentence is the one
# without it. Both hostile, with the newline first and with no newline; each hostile alone, the other good; both good;
# and a good version with two recipes waiting, which names no recipe. No file f is made anywhere.
# Mutants: tests/mutants/T20a (build the text into the AppleScript source), T20b (use the version unmatched) and T20c
# (use the label unmatched).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
U="$DATA/_update"
engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
cat > "$U/updates.sh" <<'UPD'
# T20's stand-in for the rule file: --refresh says it fetched; --noted and --recipes print the files beside it
d=${0%/*}
case "${1:-}" in
  --refresh) printf 'ready\tv0.1.0\tv0.2.0\t-\tfetched\n' ;;
  --noted) cat "$d/t20-noted" ;;
  --recipes) cat "$d/t20-recipes" ;;
esac
UPD
mkdir -p "$W/run"; cd "$W/run" || exit 1
SCRIPT='on run argv\ndisplay notification (item 1 of argv) with title "Auster"\nend run'
TAIL="auster status says what would change, and auster update asks before changing anything."
BAD_NL=$'"\\\n`touch f`$(touch f)'   # ", \, a newline, a backtick and $(touch f)
BAD_LINE='"\`touch f`$(touch f)'      # the same with no newline
recipe() { # LABEL -> one recipe line, waiting, with LABEL as its 13th field
  printf 'recipe\t%s\twaiting\t-\t%s\t-\t%s\t3400\t4\t32768\t45000\t46000\t%s\tstandin-a.gguf\t2026-12-01\n' "$IR" "$IB2" "$IB1" "$1"
}
told() { # VERSION LABEL SENTENCE CASE -> the check job, with --noted printing VERSION and the one recipe line LABEL
  printf '%s\n' "$1" > "$U/t20-noted"
  { printf 'ready\tv0.1.0\tv0.2.0\t-\n'; recipe "$2"; } > "$U/t20-recipes"
  : > "$STUB_NOTIFY_LOG"
  check_job
  same "$(notes)" 1 "$4: one notification"
  same "$(awk -F'\t' '{ print NF }' "$STUB_NOTIFY_LOG")" 2 "  ...the fixed script and one argument"
  same "$(cut -f1 "$STUB_NOTIFY_LOG")" "$SCRIPT" "  ...the script is the fixed one, with no value in it"
  same "$(cut -f2 "$STUB_NOTIFY_LOG")" "$3" "  ...its argument is the sentence"
}
told "v0.2.0$BAD_NL" "household$BAD_NL" "A new version of Auster is out. $TAIL" "both hostile, a newline first"
told "v0.2.0$BAD_LINE" "household$BAD_LINE" "A new version of Auster is out. $TAIL" "both hostile, on one line"
told "v0.2.0$BAD_LINE" household "A new version of Auster is out, with a new build for the recipe household. $TAIL" "the version hostile, the label good"
told v0.2.0 "household$BAD_LINE" "Auster v0.2.0 is out. $TAIL" "the version good, the label hostile"
told v0.2.0 "household$BAD_NL" "Auster v0.2.0 is out. $TAIL" "the version good, the label hostile with a newline"
told v0.2.0 household "Auster v0.2.0 is out, with a new build for the recipe household. $TAIL" "both good"
told $'v0.2.0\tmore' household "Auster v0.2.0 is out, with a new build for the recipe household. $TAIL" "a field after the version (D3.2: a later version's): the version is read"
{ printf 'ready\tv0.1.0\tv0.2.0\t-\n'; recipe household; recipe kitchen | sed "s/$IR/rsb5yknee42is/"; } > "$U/t20-recipes"
: > "$STUB_NOTIFY_LOG"; check_job
same "$(cut -f2 "$STUB_NOTIFY_LOG")" "Auster v0.2.0 is out. $TAIL" "two recipes waiting: the version, and no recipe named"
: > "$U/t20-noted"; : > "$STUB_NOTIFY_LOG"; check_job
same "$(notes)" 0 "--noted prints nothing: no notification"
same "$(find "$W" -name f | wc -l | tr -d ' ')" 0 "no file f anywhere under the test's folder, the data root and the check job's folder among them"
done_
