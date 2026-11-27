# T66: install.sh cut short at the end of every line, at ten points in the middle of lines, and at every
# byte of its last line short of its end, each run as the pasted line runs it
# (`bash -c "$(cat cut)" auster-install <id>`): no stub is called, no request is sent and no file is made
# (B2: a download cut short runs nothing).
# Mutants: tests/mutants/T66a and T66b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir "$W/cwd" "$W/tmp" "$W/cuts"
I="$ROOT/install.sh"
n=$(wc -l < "$I" | tr -d ' ')
size=$(stat -f %z "$I")
last=$(tail -n 1 "$I")
same "$last" 'auster_install_main "$@"' "the last line calls the main function"
same "$(tail -c 1 "$I" | od -An -tx1 | tr -d ' ')" 0a "and ends in a newline"

before=$(snapshot "$H")
cuts=0
run_cut() { # FILE -> the cut file run as the pasted line runs install.sh
  ( cd "$W/cwd" && HOME="$H" TMPDIR="$W/tmp/" AU_TTY=/dev/null /bin/bash -c "$(cat "$1")" auster-install "$IR" ) > /dev/null 2>&1
  cuts=$((cuts + 1))
}
: > "$W/cuts/c"; run_cut "$W/cuts/c"
for ((k = 1; k < n; k++)); do head -n "$k" "$I" > "$W/cuts/c"; run_cut "$W/cuts/c"; done
for ((i = 1; i <= 10; i++)); do
  at=$((size * i / 11))
  [ "$(head -c "$at" "$I" | tail -c 1 | od -An -tx1 | tr -d ' ')" != 0a ] || at=$((at + 3))
  head -c "$at" "$I" > "$W/cuts/c"; run_cut "$W/cuts/c"
done
for ((b = 1; b < ${#last}; b++)); do head -c $((size - 1 - ${#last} + b)) "$I" > "$W/cuts/c"; run_cut "$W/cuts/c"; done
same "$cuts" $((n + 10 + ${#last} - 1)) "every cut was run"
same "$(cat "$STUB_LOG")" "" "no stub was called"
same "$(requests)" "" "no request was sent"
same "$(ls -A "$W/cwd")$(ls -A "$W/tmp")" "" "no file was made where it ran, or in TMPDIR"
same "$(snapshot "$H")" "$before" "nor in the home folder"

# The whole file, with no argument: its usage and exit 2, still calling nothing
( cd "$W/cwd" && HOME="$H" /bin/bash -c "$(cat "$I")" auster-install ) > "$W/out" 2>&1; RC=$?
same "$RC" 2 "the whole file with no argument: exit 2"
says "usage: install.sh <recipe id>" "and its usage"
same "$(cat "$STUB_LOG")" "" "and no stub called"
done_
