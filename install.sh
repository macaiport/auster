#!/bin/bash
# install.sh: Auster's way in (docs/plans/v0.1.md, B2), the bootstrap. Pasted into Terminal as
#
#   /bin/bash -c "$(curl -q --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/install.sh)" auster-install <recipe id>
#
# it refuses what it must before anything is written or fetched (B3 step 1), fixes one commit (B3 step 2),
# and hands over to the driver in that commit's tree, common/driver.sh, so that every file that does the
# work comes from that one commit.
#
#   install.sh <recipe id>           install the recipe (B3)
#   install.sh --check <recipe id>   B3's steps up to the question, in a temporary folder deleted after;
#                                    nothing is asked, and nothing changes in the data root (T64)
#   install.sh update                the update (D3.6), by the driver of release's newest commit (U4)
#   install.sh remove                remove an install that failed before bin/auster was written (B8)
#
# Which commit. GitHub's API names the commit `release` holds now (commits/heads/release, asked for as the
# bare sha); that commit's tree is fetched as one archive from codeload.github.com, and the commit the
# archive's pax header records (comment=) must be the same. To install a named version, the line has
# refs/tags/v<a>.<b>.<c> in place of refs/heads/release, which fetches that tag's install.sh. It knows its
# own version (AUSTER_SELF_VERSION, which the release gate holds equal to the tag: U9). When the tree
# release holds is of another version, this is such an install: the tag's commit is fixed the same way, the
# stamp will say `tag` (D3.2: the Mac is then manual), and the registry release holds now is passed to the
# driver for its withdrawals (B2, T96).
#
# The contract with the driver. It can never change once anyone has installed (D3.9); a later version may
# add an option, never change or remove one:
#   /bin/bash <tree>/common/driver.sh install|check <recipe id> --commit C --line release|tag --version V [--withdrawals FILE]
#   /bin/bash <tree>/common/driver.sh update|remove --commit C --line release --version V
#
# Exit codes (B3): 0 done; 1 refused, or a fetch failed, and nothing of this run is left; 2 usage; and the
# driver's own, as B3 gives them (3, 4, 5).
#
# All functions and constants: the last line calls auster_install_main, so that a download cut short runs
# nothing (T66). The main function runs nothing outside bash until it has checked its arguments.

AUSTER_SELF_VERSION=v0.1.0
AUSTER_MACOS_FLOOR=27
AUSTER_API=https://api.github.com/repos/macaiport/auster/commits
AUSTER_CODELOAD=https://codeload.github.com/macaiport/auster/tar.gz
AUSTER_TREE_MAX=33554432
AUSTER_RE_RECIPE='^r[a-z2-7]{12}$'
AUSTER_RE_COMMIT='^[0-9a-f]{40}$'
AUSTER_RE_MACOS='^[1-9][0-9]?\.(0|[1-9][0-9]?)(\.(0|[1-9][0-9]?))?$'
AUSTER_RE_VERSION='^v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'
AUSTER_RE_NAME='^[A-Za-z0-9._+@-]+$'

auster_install_usage() {
  printf '%s\n' "usage: install.sh <recipe id>            install the recipe the guide names" \
    "       install.sh --check <recipe id>    check that it would install, changing nothing" \
    "       install.sh update                 update Auster on this Mac" \
    "       install.sh remove                 remove an install that stopped before \`auster\` was written" >&2
}

auster_install_refuse() { # MODE -> 0 to go on; otherwise says why and returns 1. B3 step 1: before
  # anything is written or fetched. Apple Silicon is asked of hw.optional.arm64, which a Terminal under
  # Rosetta does not hide; the macOS version is compared as a number on its major part.
  local uid arm v major
  uid=$(id -u 2>/dev/null)
  if [ "$uid" = 0 ]; then
    echo "Do not run Auster's installer as root (with sudo): it would leave files only root can change. Run it from your own account."
    return 1
  fi
  case "$uid" in ''|*[!0-9]*) echo "The installer cannot tell which account runs it."; return 1 ;; esac
  [ "$1" != remove ] || return 0
  arm=$(sysctl -n hw.optional.arm64 2>/dev/null)
  if [ "$arm" != 1 ]; then
    echo "Auster runs only on a Mac with Apple Silicon (M1 or later). This Mac is not one, so nothing was installed."
    return 1
  fi
  v=$(sw_vers -productVersion 2>/dev/null)
  if ! [[ $v =~ $AUSTER_RE_MACOS ]]; then
    echo "The installer cannot tell which version of macOS this is, so nothing was installed."
    return 1
  fi
  major=${v%%.*}
  if [ "$major" -lt "$AUSTER_MACOS_FLOOR" ]; then
    echo "This Mac has macOS $v. Auster installs on macOS $AUSTER_MACOS_FLOOR or later, so nothing was installed."
    return 1
  fi
}

auster_install_get() { # URL FILE MAX [HEADER] -> 0 when curl exits 0, the code is 200 and FILE is at most
  # MAX bytes, measured again. AUSTER_CODE and AUSTER_RC say what came back. HTTPS only, the person's own
  # curl settings ignored (-q first), only HTTPS redirects followed.
  local h=()
  [ $# -lt 4 ] || h=(-H "$4")
  AUSTER_CODE=$(curl -q --proto =https --proto-redir =https --tlsv1.2 -sS -L --max-time 300 --max-filesize "$3" \
    ${h[@]+"${h[@]}"} -o "$2" -w '%{http_code}' "$1" 2>/dev/null)
  AUSTER_RC=$?
  [ "$AUSTER_RC" = 0 ] && [ "$AUSTER_CODE" = 200 ] && [ -f "$2" ] && [ "$(stat -f %z "$2")" -le "$3" ]
}

auster_install_unreached() { # WHAT -> one sentence for a fetch that failed
  case "$AUSTER_RC:$AUSTER_CODE" in
    0:404|0:422|22:404|22:422) echo "GitHub has no $1, so nothing was installed. Check the line against the guide." ;;
    6:*|7:*) echo "GitHub could not be reached (no network?). Check the connection, then paste the line again." ;;
    *) echo "GitHub did not give the $1 (curl exit $AUSTER_RC, answer ${AUSTER_CODE:-none}). Try again in a few minutes." ;;
  esac
}

auster_install_commit() { # REF WHAT -> AUSTER_GOT: the commit GitHub's API says REF names now
  local f="$AUSTER_TMP/commit" c
  rm -f "$f"
  if ! auster_install_get "$AUSTER_API/$1" "$f" 1024 'Accept: application/vnd.github.sha'; then
    auster_install_unreached "$2"
    return 1
  fi
  c=$(head -c 41 "$f")
  if ! [[ $c =~ $AUSTER_RE_COMMIT ]]; then
    echo "GitHub's answer for $2 is not a commit, so nothing was installed."
    return 1
  fi
  AUSTER_GOT=$c
}

auster_install_tree() { # COMMIT DIR -> the tree of COMMIT unpacked in DIR: AUSTER_TREE its folder and
  # AUSTER_TREE_VERSION the version its registry's first line gives
  local c=$1 d=$2 a e top first n
  mkdir -p "$d/x" || return 1
  a="$d/tree.tar.gz"
  if ! auster_install_get "$AUSTER_CODELOAD/$c" "$a" "$AUSTER_TREE_MAX"; then
    auster_install_unreached "files of commit $c"
    return 1
  fi
  # The commit recorded inside the archive: its first header is a pax global header (type g) whose
  # record is exactly "52 comment=<commit>", as git archive writes it.
  gzip -dc "$a" 2>/dev/null | head -c 1024 > "$d/head"
  if [ "$(head -c 157 "$d/head" | tail -c 1)" != g ] ||
     [ "$(head -c 564 "$d/head" | tail -c 52; echo .)" != "52 comment=$c"$'\n.' ]; then
    echo "The archive GitHub sent does not record commit $c, the one its API named, so nothing was installed."
    return 1
  fi
  tar -tzf "$a" > "$d/names" 2>/dev/null || { echo "The archive GitHub sent cannot be read."; return 1; }
  first=$(head -n 1 "$d/names"); top=${first%%/*}
  [[ $top =~ $AUSTER_RE_NAME ]] && [ "$top" != . ] && [ "$top" != .. ] || { echo "The archive GitHub sent is not one folder."; return 1; }
  while IFS= read -r e; do
    case "$e" in "$top"|"$top"/*) ;; *) echo "The archive GitHub sent is not one folder."; return 1 ;; esac
    case "/$e/" in */../*|*/./*) echo "The archive GitHub sent holds a name Auster does not accept."; return 1 ;; esac
  done < "$d/names"
  tar -xzf "$a" -C "$d/x" 2>/dev/null || { echo "The archive GitHub sent cannot be unpacked."; return 1; }
  AUSTER_TREE="$d/x/$top"
  if [ ! -d "$AUSTER_TREE" ] || [ -L "$AUSTER_TREE" ] || [ ! -f "$AUSTER_TREE/common/driver.sh" ] || [ ! -f "$AUSTER_TREE/registry.tsv" ]; then
    echo "Commit $c is not a version of Auster that can install."
    return 1
  fi
  IFS= read -r first < "$AUSTER_TREE/registry.tsv"
  n=${first#auster-registry$'\t'1$'\t'}
  if [ "$n" = "$first" ] || ! [[ $n =~ $AUSTER_RE_VERSION ]]; then
    echo "The registry of commit $c cannot be read, so nothing was installed."
    return 1
  fi
  AUSTER_TREE_VERSION=$n
}

auster_install_main() {
  set -u
  local mode recipe= commit line=release version tree wd=
  case "${1:-}" in
    '') auster_install_usage; return 2 ;;
    --check) mode=check; recipe=${2:-}; [ $# -eq 2 ] || { auster_install_usage; return 2; } ;;
    update|remove) mode=$1; [ $# -eq 1 ] || { auster_install_usage; return 2; } ;;
    *) mode=install; recipe=$1; [ $# -eq 1 ] || { auster_install_usage; return 2; } ;;
  esac
  if [ "$mode" = install ] || [ "$mode" = check ]; then
    if ! [[ $recipe =~ $AUSTER_RE_RECIPE ]]; then
      echo "The word after auster-install must be a recipe id: r and 12 letters or digits, as the guide gives it." >&2
      auster_install_usage
      return 2
    fi
  fi
  auster_install_refuse "$mode" || return 1

  AUSTER_TMP=$(mktemp -d "${TMPDIR:-/tmp}/auster-install.XXXXXX") || { echo "A temporary folder could not be made."; return 1; }
  trap 'rm -rf "$AUSTER_TMP"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  auster_install_commit heads/release "release of Auster" || return 1
  commit=$AUSTER_GOT
  auster_install_tree "$commit" "$AUSTER_TMP/release" || return 1
  tree=$AUSTER_TREE version=$AUSTER_TREE_VERSION
  if { [ "$mode" = install ] || [ "$mode" = check ]; } && [ "$version" != "$AUSTER_SELF_VERSION" ]; then
    wd="$tree/registry.tsv"
    auster_install_commit "tags/$AUSTER_SELF_VERSION" "version $AUSTER_SELF_VERSION of Auster" || return 1
    commit=$AUSTER_GOT
    auster_install_tree "$commit" "$AUSTER_TMP/tag" || return 1
    tree=$AUSTER_TREE
    if [ "$AUSTER_TREE_VERSION" != "$AUSTER_SELF_VERSION" ]; then
      echo "GitHub's tag $AUSTER_SELF_VERSION holds another version, so nothing was installed."
      return 1
    fi
    line=tag version=$AUSTER_SELF_VERSION
    echo "This installs Auster $version, a named version: it is never offered updates."
    echo "If you pasted the line from the guide, GitHub gave an older copy of it: wait five minutes and paste it again."
  fi
  echo "Auster $version, commit $commit."
  auster_install_handover "$tree" "$mode" "$recipe" "$commit" "$line" "$version" "$wd"
}

auster_install_handover() { # TREE MODE RECIPE COMMIT LINE VERSION WITHDRAWALS -> the driver's exit code
  local a=("$2")
  [ -z "$3" ] || a+=("$3")
  a+=(--commit "$4" --line "$5" --version "$6")
  [ -z "$7" ] || a+=(--withdrawals "$7")
  /bin/bash "$1/common/driver.sh" "${a[@]}"
}

auster_install_main "$@"
