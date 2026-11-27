# T98, the source's half (U2): the bare PATH of tests/run.sh cannot reach a program that sets its own PATH (the rule
# file does, D3.2), so a gate on the source: no file the household's Mac runs -- common/, install.sh and
# tools/mint-id -- runs timeout, jq, python3, git, brew or base32 (BD15, BD17). A run is the name in a command's place
# (where a command starts -- a line, after ; | & ( { ` $( or the quote of bash -c and osascript -e -- then keywords and
# assignments; or after env and its options; with or without a path or quotes), any path that names one, and in
# JavaScript a string that is one or a doShellScript that holds one.
# Comments are not code; prose that names them in a string is not a run. The gate first proves itself on two files
# made here: one of mentions only, which it passes, and one of calls, each of which it finds. Mutant:
# tests/mutants/T98b, a call to timeout in the rule file, which runs under its own PATH (T98a is the runner's).
. "$TESTS/lib.sh"
W=$(mktemp -d "${TMPDIR%/}/t98.XXXXXX")
TOOL='(timeout|jq|python3?|git|brew|base32)'
END='(["'"'"']?([[:space:];|&)]|$))'
SEP="(^|[;&|({\`]|\\\$\\(|-[ce][[:space:]]+[\"'])"   # where a command starts: a line, ; | & ( { \` \$(, bash -c, osascript -e
PRE="([[:space:]]*(then|do|else|elif|if|while|until|exec|command|nohup|xargs|!|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*))*"
CMD="$SEP$PRE[[:space:]]*[\"']?(/[^[:space:]\"']*/)?$TOOL$END"
ENV="(^|[^A-Za-z0-9_.-])env([[:space:]]+(-[^[:space:]]*|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*))*[[:space:]]+[\"']?(/[^[:space:]\"']*/)?$TOOL$END"
PATHS="/(usr/|opt/|local/|homebrew/|s?bin/)+$TOOL([^A-Za-z0-9_-]|$)"
JS="[\"'](/[^\"']*/)?$TOOL[\"']|doShellScript\\(.*[^A-Za-z0-9_-]$TOOL([^A-Za-z0-9_-]|$)"

code() { # FILE -> its lines that are code, `<line>: <text>`, comments taken out (# in shell; // and /* */ lines in JavaScript)
  case "$1" in
    *.js) awk '{ l = $0; if (l ~ /^[[:space:]]*(\/\/|\/\*|\*)/) l = ""; else sub(/[[:space:]]\/\/.*$/, "", l); print NR ": " l }' "$1" ;;
    *) awk '{ l = $0; if (l ~ /^[[:space:]]*#/) l = ""; else sub(/[[:space:]]#.*$/, "", l); print NR ": " l }' "$1" ;;
  esac
}
runs() { # FILE -> each line of code that runs one of the six, `<file>:<line>: <text>`
  local f=$1
  { code "$f" | sed 's/^[0-9]*: //' | grep -n -E -e "$CMD" -e "$ENV" -e "$PATHS"
    case "$f" in *.js) code "$f" | sed 's/^[0-9]*: //' | grep -n -E -e "$JS" ;; esac
    grep -q 'doShellScript' "$f" && code "$f" | sed 's/^[0-9]*: //' | grep -n -E -e "$JS" | grep doShellScript
  } | sort -t: -k1,1n -u | sed "s|^|${f#"$ROOT"/}:|"
}

# --- the gate on itself
cat > "$W/mentions.sh" <<'EOF'
#!/bin/bash
# timeout, jq, python3, git, brew and base32 are named here and never run
# /usr/bin/timeout is not assumed; `git archive` writes the comment
au_say "Auster needs no git, no jq and no python3: macOS has no base32 command, and brew is not used."
x=${y#timeout}   # a pattern, not a run: timeout
echo "a time jq" 'it is time to brew tea'
EOF
cat > "$W/mentions.js" <<'EOF'
// timeout and jq are named here; doShellScript is not used
var s = 'no jq, no git, no python3 needed';   // and git here
/* base32 is done by hand */
EOF
cat > "$W/calls.sh" <<'EOF'
timeout 5 true
x=$(jq -r . f)
cat f | python3 -c 1
if git status; then :; fi
PATH=/usr/bin brew list
env -i PATH=/usr/bin base32 < f
y=`git rev-parse HEAD`
"$d"/x || /usr/bin/timeout 3 sleep 1
osascript -l JavaScript -e 'doShellScript("jq -n 1")'
EOF
cat > "$W/calls.js" <<'EOF'
var r = auTask(['jq', '-n', '1']);
t.launchPath = '/usr/bin/git';
app.doShellScript("python3 -c 1");
EOF
for f in mentions.sh mentions.js; do same "$(runs "$W/$f")" "" "the gate on $f, mentions only: nothing found"; done
same "$(runs "$W/calls.sh" | cut -d: -f2 | paste -sd, -)" "1,2,3,4,5,6,7,8,9" "the gate on calls.sh: each of its nine calls found"
same "$(runs "$W/calls.js" | cut -d: -f2 | paste -sd, -)" "1,2,3" "the gate on calls.js: each of its three calls found"

# --- the files the household's Mac runs
n=0
for f in "$ROOT"/common/* "$ROOT/install.sh" "$ROOT/tools/mint-id"; do
  [ -f "$f" ] || continue
  n=$((n + 1))
  same "$(runs "$f")" "" "${f#"$ROOT"/} runs none of timeout, jq, python3, git, brew and base32"
done
[ "$n" -ge 12 ] && ok "$n files read" || bad "only $n files read"
done_
