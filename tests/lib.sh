# Sourced by every test file. A test file prints one line per check and exits non-zero if any failed.
FAILS=0
ok()   { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
same() { if [ "$1" = "$2" ]; then ok "$3"; else bad "$3: got [$1], expected [$2]"; fi; }
done_() { [ "$FAILS" -eq 0 ]; exit $?; }
