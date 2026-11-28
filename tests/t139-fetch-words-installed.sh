# T139 (the conventions' audit, 2026-11-28; docs/conventions.md section 2, "Plain words" and "Fixed sentences"): on a Mac
# that serves, what a fetch or a request came to is said in plain words, never as curl's exit code, and the HTTP code only
# once it is matched as one. `auster people 2` with release's install.sh answered by a code that is no number ("2OO", the
# stub curl's X-Stub-Code) and with GitHub unreachable; the update's .command file, run as Terminal runs it, with that
# install.sh answered 503, by a code that is no number, unreachable, and with no answer in time; and the server check of
# `auster restart` against an engine that answers a request with no key, which names the code it answered.
# Mutants: tests/mutants/T139a (the .command file takes any code), T139b (people says curl exit), T139c (the open check's
# reason in the old words).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
jargon() { # LABEL -> neither curl's exit code nor the code that is no number in what the run printed
  grep -q 'curl exit' "$W/out" && bad "$1: it says curl exit: $(cat "$W/out")" || ok "$1: no curl exit"
  grep -q '2OO' "$W/out" && bad "$1: it prints the code that is no number" || ok "$1: the code that is no number not printed"
}
installer() { route_drop "$INSTALL_SH"; curl_route GET "$INSTALL_SH" "$@"; }   # STATUS BODY [HEADER...]: release's install.sh

# --- auster people
installer 200 "$ROOT/install.sh" "X-Stub-Code: 2OO"
auster people 2
same "$RC" 1 "auster people, the installer's code no number: exit 1"
outsays "GitHub did not give Auster's installer (it gave no answer Auster can read), so nothing was changed." "  ...it says it could not read one"
jargon "people, the code no number"
installer exit:7 -
auster people 2
same "$RC" 1 "auster people, GitHub unreachable: exit 1"
outsays "GitHub did not give Auster's installer (it could not be reached), so nothing was changed. Check the network, then try again." "  ...it says so"
jargon "people, unreachable"

# --- the update's .command file, run as Terminal runs it
command_says() { # STATUS BODY HEADER TEXT LABEL -> a fresh .command file from `auster update`, run with release's
  # install.sh answered so: exit 1, and its line TEXT
  installer 200 "$ROOT/install.sh"
  auster update
  local f
  f=$(opened | tail -n 1)
  if [ -n "$3" ]; then installer "$1" "$2" "$3"; else installer "$1" "$2"; fi
  run_command "$f" ''
  same "$RC" 1 "$5: the file exits 1"
  says "$4" "  ...it says so"
  jargon "$5"
}
command_says 503 - '' "GitHub answered 503, so nothing was changed. Run auster update again in a few minutes." "the file, 503"
command_says 200 "$ROOT/install.sh" "X-Stub-Code: 2OO" "GitHub gave no answer this file can read, so nothing was changed." "the file, a code that is no number"
command_says exit:7 - '' "GitHub could not be reached (no network?), so nothing was changed. Check the network, then run auster update again." "the file, unreachable"
command_says exit:28 - '' "GitHub did not give Auster's installer in time, so nothing was changed." "the file, no answer in time"
installer 200 "$ROOT/install.sh"

# --- the server check, against an engine that answers a request with no key
engine_up
engine_set '*' behaviour open
auster restart
same "$RC" 4 "auster restart, the engine open: exit 4"
outsays "The server did not refuse a request that carried no key, so Auster stopped it: it did not refuse a request that carried no key (it answered 200)." "  ...it names the code the engine answered"
grep -q 'it gave' "$W/out" && bad "  ...in the old words" || ok "  ...in plain words"
engine_set '*' behaviour ok
done_
