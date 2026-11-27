# T61: B3 step 1's refusals, which install.sh makes before anything is fetched or written: run as root
# (id -u 0), not Apple Silicon (hw.optional.arm64 0), a macOS below the floor of 27 (26.1, and 9.0, which a
# comparison as text would put above 27). Each exits 1, leaves the home folder as it was, sends no request,
# and calls no stub but those that answer the three questions. Under Rosetta (uname -m x86_64,
# hw.optional.arm64 1) it goes on: its first request asks GitHub which commit release names (answered 404
# here, so the run ends there). Mutants: tests/mutants/T61a to T61c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
stub_env
W=$(mktemp -d "${TMPDIR%/}/t61.XXXXXX")
H=$(make_home "$W")
curl_route GET "$API/heads/release" 404 -
before=$(snapshot "$H")

refused() { # LABEL SAYS STUBS -> after the run: exit 1, the sentence, no request, the stubs called, home unchanged
  same "$RC" 1 "$1: exit 1"
  says "$2" "$1: says why"
  same "$(requests)" "" "$1: no request"
  same "$(cut -d' ' -f1 "$STUB_LOG" | sort -u | tr '\n' ' ')" "$3" "$1: no stub called but $3"
  same "$(snapshot "$H")" "$before" "$1: the home folder as it was"
  : > "$STUB_LOG"
}

STUB_UID=0 run_install '' "$IR"
refused "run as root" "Do not run Auster's installer as root" "id "
STUB_ARM64=0 run_install '' "$IR"
refused "hw.optional.arm64 0" "Auster runs only on a Mac with Apple Silicon" "id sysctl "
STUB_ARM64= run_install '' "$IR"
refused "no hw.optional.arm64 at all" "Auster runs only on a Mac with Apple Silicon" "id sysctl "
STUB_MACOS=26.1 run_install '' "$IR"
refused "macOS 26.1" "This Mac has macOS 26.1. Auster installs on macOS 27 or later" "id sw_vers sysctl "
STUB_MACOS=9.0 run_install '' "$IR"
refused "macOS 9.0" "This Mac has macOS 9.0. Auster installs on macOS 27 or later" "id sw_vers sysctl "
STUB_MACOS=27 run_install '' "$IR"
refused "a version in no form it reads" "cannot tell which version of macOS" "id sw_vers sysctl "

# Rosetta: uname says x86_64, hw.optional.arm64 still says 1, so it goes on to GitHub
STUB_ROSETTA=1 run_install '' "$IR"
same "$(STUB_ROSETTA=1 uname -m)" x86_64 "under Rosetta, uname -m says x86_64"
same "$(requests | head -n 1)" "GET $API/heads/release" "Rosetta: it goes on, and asks GitHub which commit release names"
says "GitHub has no release of Auster" "Rosetta: it stops only where the fetch fails"
same "$(snapshot "$H")" "$before" "Rosetta: the home folder as it was"
: > "$STUB_LOG"; rm -rf "$STUB_CURL_DIR/requests"
STUB_MACOS=27.0 run_install '' "$IR"
same "$(requests | head -n 1)" "GET $API/heads/release" "macOS 27.0, the floor itself: it goes on"
done_
