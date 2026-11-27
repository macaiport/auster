# T64: `install.sh --check` runs B3's steps up to the question in a temporary folder that it deletes: it
# leaves the data root, ~/Library/LaunchAgents and ~/.zprofile exactly as they were (snapshot), asks
# nothing, touches no job, fetches nothing from the model's host, and leaves no temporary folder. Once on a
# Mac with no Auster, once on a Mac where Auster serves. Mutant: tests/mutants/T64a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir "$W/tmp"

checked() { # LABEL -> after the run: exit 0, what it says, nothing changed, nothing left in TMPDIR
  same "$RC" 0 "$1: exit 0"
  says "--check: this Mac can install household. Nothing was changed." "$1: it says the Mac can install it"
  says "The engine will hold 44.6 GB of this Mac's 64.0 GB of memory" "$1: it says what the question would"
  same "$(snapshot "$H")" "$before" "$1: the data root, ~/Library/LaunchAgents and ~/.zprofile as they were"
  same "$(ls -A "$W/tmp")" "" "$1: no temporary folder is left"
  same "$(grep -c '^launchctl' "$STUB_LOG")" 0 "$1: no job was touched"
  same "$(requests huggingface.co)" "" "$1: nothing was asked of the model's host"
}

before=$(snapshot "$H")
TMPDIR="$W/tmp/" run_install '' --check "$IR"
checked "no Auster on the Mac"
[ -e "$DATA" ] && bad "a data root exists" || ok "no Auster on the Mac: still no data root"

run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "then Auster is installed"
: > "$STUB_LOG"; rm -rf "$STUB_CURL_DIR/requests"
before=$(snapshot "$H")
TMPDIR="$W/tmp/" run_install '' --check "$IR"
checked "Auster serving"
says "http://test-mac.local:8485/" "Auster serving: the port it would choose is the next free one, since its own engine holds 8484"
done_
