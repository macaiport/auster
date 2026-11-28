# T144, before an install (the conventions' audit, its second pass, 2026-11-28; docs/conventions.md section 2, "Fixed
# sentences"; C1, C3, C6, B3 steps 5 and 6): the figures section C (common/capability.js) prints are matched before a
# sentence names them or a sum takes them, since bash's arithmetic on a value that is no number runs what it holds
# (a[$(...)]). The driver is run from a copy of the fetched tree, as install.sh runs it, with a stand-in capability.js
# that prints one figure as such a value, a command that would touch a file; for each, the run says a fixed sentence that
# names no figure, the file is never touched, and the value is never printed:
#   - refused fit, the GPU limit (figures) and then the memory a Mac needs (needs) not a number: the fit refusal without
#     figures;
#   - refused room, the free disk (figures) and then the free bytes needed (room) not a number: the room refusal without
#     figures;
#   - a choice, with a room line for the first choice whose download is not a number: the question's Room line without
#     figures, and the question is asked;
#   - a choice whose GPU figure, and then this Mac's memory, is not a number: refused as nothing worked out.
# tests/t144-figures-update.sh holds the update's half and `auster people`'s.
# Mutants: tests/mutants/T144a (the fit refusal unmatched), T144b (the room refusal unmatched), T144c (the question's
# Room line unmatched), T144d (the choice's MiB unmatched), T144e (this Mac's GPU limit and memory unmatched at step 5);
# T144f and T144g are tests/t144-figures-update.sh's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
before=$(snapshot "$H")
cp -R "$FX/tree-src-$COMMIT" "$W/tree"
P="BASH_VERSINFO[\$(touch $W/ran)]"   # no number: bash's arithmetic, even under set -u, would run the touch
OK=68719476736 FREE=500000000000 DISK=1000000000000 FROM='measured|measured|measured|measured'

cap() { # EXIT LINE... -> the tree's capability.js a stand-in that prints each LINE, its fields separated by |, and exits EXIT
  local rc=$1 l s=
  shift
  for l in "$@"; do s+="${l//|/\\t}\\n"; done
  printf "ObjC.import('Foundation'); ObjC.import('stdlib');\nfunction run() {\n  \$.NSFileHandle.fileHandleWithStandardOutput.writeData(\$('%s').dataUsingEncoding(\$.NSUTF8StringEncoding));\n  \$.exit(%s);\n}\n" "$s" "$rc" > "$W/tree/common/capability.js"
}
drive() { # ANSWERS -> the tree's driver, `install <recipe>` as install.sh runs it; output in $W/out, exit code in RC
  printf '%s' "$1" > "$W/answers"
  HOME="$H" AU_TTY="$W/answers" /bin/bash "$W/tree/common/driver.sh" install "$IR" --commit "$COMMIT" --line release \
    --version v0.1.0 > "$W/out" 2>&1
  RC=$?
}
matched() { # -> the figure that is no number ran nothing, was never printed, and nothing of the run is left
  if [ -e "$W/ran" ]; then bad "  ...the figure ran"; rm -f "$W/ran"; else ok "  ...nothing ran"; fi
  grep -q 'touch' "$W/out" && bad "  ...the figure printed as it came" || ok "  ...the figure never printed"
  same "$(snapshot "$H")" "$before" "  ...nothing left in the home folder"
}

# --- refused fit
cap 3 "figures|$P|$OK|$FREE|$DISK|$FROM" 'refused|fit' "needs|$IB1|1|8192|20000|30000|21024|42288"
drive ''
same "$RC" 1 "refused fit, the GPU limit no number: exit 1"
says "This Mac does not have the GPU limit and memory the smallest build of this recipe needs, so nothing was installed." "  ...the fit refusal, naming no figure"
matched
cap 3 "figures|53084|$OK|$FREE|$DISK|$FROM" 'refused|fit' "needs|$IB1|1|8192|20000|30000|21024|$P"
drive ''
same "$RC" 1 "refused fit, the memory needed no number: exit 1"
says "This Mac does not have the GPU limit and memory the smallest build of this recipe needs, so nothing was installed." "  ...the fit refusal, naming no figure"
matched

# --- refused room
cap 3 "figures|53084|$OK|$P|$DISK|$FROM" 'refused|room' "room|$IB1|20000000000|70000000000"
drive ''
same "$RC" 1 "refused room, the free disk no number: exit 1"
says "There is not room on this Mac's disk for the smallest download that fits (Auster keeps the larger of 20 GB and 5% of the disk free). Nothing was fetched." "  ...the room refusal, naming no figure"
matched
cap 3 "figures|53084|$OK|$FREE|$DISK|$FROM" 'refused|room' "room|$IB1|20000000000|$P"
drive ''
same "$RC" 1 "refused room, the free bytes needed no number: exit 1"
says "There is not room on this Mac's disk for the smallest download that fits (Auster keeps the larger of 20 GB and 5% of the disk free). Nothing was fetched." "  ...the room refusal, naming no figure"
matched

# --- a choice, and the question's Room line
cap 0 "figures|53084|$OK|$FREE|$DISK|$FROM" "choice|$IB2|4|32768|20000|30000|in-turn|room" "room|$IB1|$P|520000000000"
drive $'no\nno\n'
same "$RC" 1 "a choice, the first choice's download no number, the question answered no: exit 1"
says "Auster is ready to install household on this Mac." "  ...the question is asked"
says "would need more room on disk than this Mac has free," "  ...its Room line, naming no figure"
says "  Memory      The engine will hold 29.3 GB of this Mac's 64.0 GB of memory, 19.5 GB of it on the GPU." "  ...and its other figures, matched"
matched

# --- a choice whose figures are no numbers
cap 0 "figures|53084|$OK|$FREE|$DISK|$FROM" "choice|$IB2|4|32768|$P|30000|in-turn|room"
drive $'no\nno\n'
same "$RC" 1 "a choice whose GPU figure is no number: exit 1"
says "Auster could not work out what fits this Mac, so nothing was installed." "  ...refused, naming no figure"
matched
cap 0 "figures|53084|$P|$FREE|$DISK|$FROM" "choice|$IB2|4|32768|20000|30000|in-turn|room"
drive $'no\nno\n'
same "$RC" 1 "a choice, this Mac's memory no number: exit 1"
says "Auster could not work out what fits this Mac, so nothing was installed." "  ...refused, naming no figure"
matched
done_
