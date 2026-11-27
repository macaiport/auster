# T38 (U4; D3.6, B6): over SSH the update runs in that session; at the Mac's screen it opens Terminal. With a build
# waiting (the word ready), `auster update` at the screen asks the stub open to open the update's .command file with
# Terminal, and returns: the file is in a new folder of mode 0700, mode 0700 itself, and holds constants only (curl's
# path, the stub's, a plain absolute path; release's install.sh address), none of the home folder's path. Run as
# Terminal runs it, it fetches release's install.sh into a file beside itself and runs it with `update`, whose
# question it shows; answered no, it says in one line what happened, exits 1, and leaves neither itself nor its folder.
# Over SSH (SSH_CONNECTION, or SSH_TTY alone), `auster update` opens nothing: the update runs in the same session, its
# question asked there, and its exit code is the command's. GitHub answering 404 for install.sh: the file says so, runs
# nothing, and exits 1. Mutant: tests/mutants/T38a (always open Terminal).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
leftover() { ls -d "${TMPDIR%/}"/auster-update.* 2>/dev/null | wc -l | tr -d ' '; }

# --- at the Mac's own screen
auster update
same "$RC" 0 "at the screen: exit 0"
outsays "The update opens in a Terminal window on this Mac's screen" "  ...it says Terminal opens with the update"
f=$(opened)
same "$(printf '%s\n' "$f" | grep -c .)" 1 "  ...one file handed to the stub open"
same "$(cat "$STUB_DIR"/opened/*/app)" Terminal "  ...with -a Terminal"
same "${f##*/}" "Update Auster.command" "  ...named Update Auster.command"
same "$(stat -f %Lp "$f"):$(stat -f %Lp "${f%/*}")" "700:700" "  ...mode 0700, in a folder of mode 0700"
same "$(sed -n 2,3p "$f")" "CURL='$TESTS/stubs/curl'
URL='$INSTALL_SH'" "  ...its constants: curl's path and release's install.sh"
same "$(grep -c '^[A-Z]*=' "$f")" 4 "  ...and no other assignment but its own two (D, F)"
grep -qF "$H" "$f" && bad "  ...it names the home folder" || ok "  ...it names no home folder"
same "$(grep -cE 'AU_|HOME' "$f")" 0 "  ...and reads no variable of Auster's or the home"
run_command "$f" $'no\n'
same "$RC" 1 "the file run as Terminal runs it, the question answered no: exit 1"
says "Fetching Auster's installer from github.com/macaiport/auster" "  ...it fetches the installer"
says "The recipe household: an update is waiting." "  ...the update's question is asked"
same "$(tail -n 1 "$W/out")" "Nothing was changed. You can close this window." "  ...and its last line says what happened"
same "$(requests raw.githubusercontent.com | grep -c "GET $INSTALL_SH")" 1 "  ...after one request for release's install.sh"
[ -e "$f" ] || [ -e "${f%/*}" ] && bad "  ...the file or its folder is left" || ok "  ...and neither the file nor its folder is left"
same "$(leftover)" 0 "  ...nothing of it left in TMPDIR"

# --- over SSH
n=$(opened | grep -c .)
ANSWERS=$'no\n' SSH_CONNECTION='10.0.0.9 50111 10.0.0.5 22' auster update
same "$RC" 1 "over SSH (SSH_CONNECTION), the question answered no: exit 1, the update's"
same "$(opened | grep -c .)" "$n" "  ...the stub open was not asked to open anything"
outsays "Over SSH, the update runs here, in this session" "  ...it says the update runs here"
outsays "The recipe household: an update is waiting." "  ...and the question is asked in this session"
outsays "Nothing was changed. You can close this window." "  ...the file's last line"
same "$(leftover)" 0 "  ...and nothing of the file left"
ANSWERS=$'no\n' SSH_TTY=/dev/ttys009 auster update
same "$RC:$(opened | grep -c .)" "1:$n" "over SSH (SSH_TTY alone): runs here too, nothing opened"
outsays "The recipe household: an update is waiting." "  ...the question asked here"

# --- GitHub without the installer
route_drop "$INSTALL_SH"; curl_route GET "$INSTALL_SH" 404 -
ANSWERS=$'no\n' SSH_CONNECTION='10.0.0.9 50111 10.0.0.5 22' auster update
same "$RC" 1 "install.sh answering 404: exit 1"
outsays "GitHub has no installer on Auster's release line, so nothing was changed." "  ...the file says so"
grep -q 'Measuring this Mac' "$W/out" && bad "  ...it ran the installer" || ok "  ...and runs nothing"
same "$(leftover)" 0 "  ...nothing of the file left"
done_
