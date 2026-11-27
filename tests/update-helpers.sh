# Sourced by the rule file's tests (U1: T1, T3, T4, T5, T14, T41, T42) after lib.sh and helpers.sh.
# common/updates.sh ($ROOT's, the mutant's copy under --mutants) is run as the check job runs it, with its
# folder at a scratch place and the stub curl (AU_CURL, which stub_env sets) answering release's changelog:
#   update_env          stub_env; W, a work folder; U, the rule file's folder (mode 0700); NOW, the clock
#   fresh               U emptied, and the stub curl's routes and requests cleared
#   stamp LINE VERSION [COMMIT [TIME]]   _update/scripts in the form the driver writes (B3 step 15)
#   offer VERSION [TIME], tried TIME     those records in their form (common/updates.sh's header)
#   changelog OUT VERSION...             a changelog: Unreleased, then one section per version, in that order
#   answer STATUS [BODY [HEADER...]]     the stub curl's route for release's changelog (CHANGELOG)
#   upd ARG...          bash updates.sh ARG... with AU_UPDATE_DIR=$U and AU_UPDATE_NOW=${AT:-$NOW}
#   fn FUNCTION ARG...  a function of the file, sourced in a subshell with AU_UPDATE_DIR=$U
#   asks                how many requests the stub curl has had
#   sum FILE            its sha256, or none
#   leftovers           how many temporary files the rule file left in U
S="$ROOT/common/updates.sh"
CHANGELOG=https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/CHANGELOG.md
HEX=0123456789abcdef0123456789abcdef01234567
NOW=1800000000
TAB=$'\t'

update_env() {
  stub_env
  W=$(mktemp -d "${TMPDIR%/}/update.XXXXXX")
  U="$W/u"
}

fresh() {
  rm -rf "$U" "$STUB_CURL_DIR/requests" "$STUB_CURL_DIR"/.count-*
  mkdir -m 700 "$U"
  : > "$STUB_CURL_DIR/routes"
}

stamp() { printf 'auster-record 1\t%s\t%s\t%s\t%s\n' "$1" "$2" "${3:-$HEX}" "${4:-2026-11-27T10:00:00Z}" > "$U/scripts"; }
offer() { printf 'auster-record 1\t%s\t%s\n' "$1" "${2:-1700000000}" > "$U/offer"; }
tried() { printf 'auster-record 1\t%s\n' "$1" > "$U/tried"; }

changelog() {
  local out=$1 v
  shift
  {
    printf '# Changelog\n\nOne section per release, newest first.\n\n## Unreleased\n\nNot released yet.\n'
    for v in "$@"; do printf '\n## %s (2026-12-01)\n\n**The change in %s.** What it does.\n' "$v" "$v"; done
  } > "$out"
}

answer() { # STATUS [BODY [HEADER...]]
  local st=$1 body=${2:--}
  shift; [ $# -eq 0 ] || shift
  curl_route GET "$CHANGELOG" "$st" "$body" "$@"
}

upd() { env AU_UPDATE_DIR="$U" AU_UPDATE_NOW="${AT:-$NOW}" /bin/bash "$S" "$@"; }

fn() { ( AU_UPDATE_DIR=$U; . "$S"; "$@" ); }

asks() { ls "$STUB_CURL_DIR/requests" 2>/dev/null | wc -l | tr -d ' '; }

sum() { if [ -e "$1" ]; then shasum -a 256 < "$1" | cut -c1-64; else echo none; fi; }

leftovers() { ls -A "$U" | grep -c '^\.' ; }
