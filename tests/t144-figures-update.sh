# T144, on a Mac that serves (the conventions' audit, its second pass, 2026-11-28; docs/conventions.md section 2, "Fixed
# sentences"; D3.6, B6, C4): the figures of section C's choice are matched before the update's question names them or a
# sum takes them. The driver is run from a copy of the fetched tree, as install.sh runs it, with a stand-in capability.js
# whose choice gives its GPU figure as a value that is no number, a command that would touch a file:
#   - an update, the choice a change of setting on the build served, the stand-in also in jobs/ so that no program
#     changes: the recipe is passed over, since what an update would change cannot be worked out, and nothing is asked;
#   - `people 2` (`auster people 2`): nothing is changed, since section C gave no setting, and the question is not asked.
# In each the file is never touched and the value is never printed.
# Mutants: tests/mutants/T144f (the update's choice unmatched), T144g (`people`'s choice unmatched); T144a to T144e are
# tests/t144-figures-install.sh's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
cp -R "$FX/tree-src-$COMMIT" "$W/tree"
P="BASH_VERSINFO[\$(touch $W/ran)]"   # no number: bash's arithmetic, even under set -u, would run the touch
FIG="figures	53084	68719476736	500000000000	1000000000000	measured	measured	measured	measured"

cap() { # EXIT LINE... -> the tree's capability.js a stand-in that prints each LINE, its fields separated by |, and exits EXIT
  local rc=$1 l s=
  shift
  for l in "$@"; do s+="${l//|/\\t}\\n"; done
  printf "ObjC.import('Foundation'); ObjC.import('stdlib');\nfunction run() {\n  \$.NSFileHandle.fileHandleWithStandardOutput.writeData(\$('%s').dataUsingEncoding(\$.NSUTF8StringEncoding));\n  \$.exit(%s);\n}\n" "$s" "$rc" > "$W/tree/common/capability.js"
}
drive() { # ANSWERS ARG... -> the tree's driver with ARG... as install.sh runs it; output in $W/out, exit code in RC
  printf '%s' "$1" > "$W/answers"; shift
  HOME="$H" AU_TTY="$W/answers" /bin/bash "$W/tree/common/driver.sh" "$@" --commit "$COMMIT" --line release \
    --version v0.1.0 > "$W/out" 2>&1
  RC=$?
}
matched() { # -> the figure that is no number ran nothing, was never printed, and serving is as it was
  if [ -e "$W/ran" ]; then bad "  ...the figure ran"; rm -f "$W/ran"; else ok "  ...nothing ran"; fi
  grep -q 'touch' "$W/out" && bad "  ...the figure printed as it came" || ok "  ...the figure never printed"
  grep -qi 'nothing changes without a yes' "$W/out" && bad "  ...the question was asked" || ok "  ...no question"
  same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"
}
s0=$(cat "$DATA/builds/$IR/serving")
same "$(sed -n 5p "$DATA/builds/$IR/serving" | cut -f1-3)" "launch	4	32768" "the install serves four people at 32,768"

# --- an update: a change of setting on the build served, its GPU figure no number
cap 0 "${FIG//	/|}" "line|same|$IB1|-|-|0" "choice|$IB1|4|16384|$P|30000|in-turn|unknown"
cat "$W/tree/common/capability.js" > "$DATA/jobs/capability.js"   # the same program in place, so that only the recipe is judged
drive '' update
same "$RC" 3 "an update whose choice's GPU figure is no number: the recipe passed over, exit 3"
says "The recipe household: what an update would change cannot be worked out, so it is not updated: it keeps serving build $IB1." "  ...in fixed words, naming no figure"
matched

# --- auster people 2, its GPU figure no number
cap 0 "${FIG//	/|}" "choice|$IB1|2|32768|$P|30000|in-turn|unknown"
drive '' people 2
same "$RC" 1 "people 2, the choice's GPU figure no number: nothing changed, exit 1"
says "The recipe household: section C gave no setting for 2 people at a time, so nothing was changed." "  ...in fixed words, naming no figure"
matched
done_
