#!/bin/bash
# updates.sh: the rule file (docs/plans/v0.1.md, D3.2), the one place that holds the rules for which version of
# Auster's scripts this Mac runs and which version is on offer. Every caller uses it, and each install puts a
# copy in <data root>/_update/updates.sh with the stamp (common/driver.sh, B3 step 15; D3.1, T43).
#
# It began as a copy of 1launcher's common/updates.sh (github.com/macgameport/1launcher, commit b056bf3), and
# is Auster's own from then on (AD12). What it does that the file it began from does not: one stamp for the
# Mac (`scripts`) in place of one per game; one-line records that carry their format number and are read by
# the rule of D3.1 (the format first; a newer format is left as it is); the no-route rule of D3.4; a cleaner
# that also strips headings below the version's, turns tabs into spaces and removes the two-byte (C1)
# control characters; values matched to Auster's own patterns.
#
# Built by U1 (2026-11-27); its tests are T1, T3, T4, T5, T14, T41, T42 and T43 (their halves that U1
# builds), with the cases of 1launcher's test that still apply. What later steps add is marked TODO:
#   U2  the readers of D3.1's other records, and the ownership rule over the data root, builds/ and store/;
#   U3  the second fetch (the registry), the joint write of offer, notes.md and registry, each recipe's line,
#       and `ready` for a build waiting; until then offer and notes.md are written from the changelog alone;
#   U4  --open: the update's .command file, handed to Terminal (D3.6); until then it refuses;
#   U7  the check job's notification, which reads --noted.
#
# Its folder, AU_UPDATE_DIR (<data root>/_update), holds (D3.1):
#   scripts   the stamp, written by the installer and never here: auster-record 1 TAB <line> TAB <version or
#             -> TAB <commit or -> TAB <time, as date -u +%Y-%m-%dT%H:%M:%SZ>. <line> is release, checkout or
#             tag (any other lower-case word is read as a line that is not release)
#   offer     auster-record 1 TAB <version> TAB <time>: the newest version release held at the last check that
#             worked, and when (time: seconds since 1970)
#   tried     auster-record 1 TAB <time>: the last try, whether it worked or not
#   noted     auster-record 1 TAB <version> TAB <1 or 2>: the version last announced, and how often
#   notes.md  the changelog as last fetched; it carries no format number
#   off       if it exists, whatever it is, nothing is ever fetched (made by hand)
# A one-line record (D3.1, Reading): the first field of its first 4,096 bytes is checked first, and
# `auster-record 1` is read on, `auster-record <n>` with a larger n is a newer format's (nothing reads it and
# nothing here ever rewrites it), anything else is absent. Then it must be a regular file, not a link, of at
# most 4,096 bytes, one line (a final newline or none), split on single tabs into exactly its fields, none
# empty, each matched whole. Nothing is ever read with `.` or eval: under bash 3.2 a value such as a[$(cmd)]
# in an arithmetic place runs cmd. Every write is to a temporary file beside the record, renamed over it.
#
# The contract (D3.2): its options and its output lines are used by callers built by other versions of Auster
# on one Mac. A later version may add an option, or a field at the end of a line, and never changes or
# removes one. The state line is always the first line of what an option below prints it for.
#   bash updates.sh                    the state line: <word> TAB <scripts> TAB <offered> TAB <detail>
#   bash updates.sh --refresh [--now]  the state line, after the check, with a fifth field: fetched, failed or
#                                      skipped (--now: the check is made whatever `tried` says)
#   bash updates.sh --notes            the fetched notes of every version newer than the stamp's, cleaned
#   bash updates.sh --noted            the offered version, at most twice for one version, or nothing
#   bash updates.sh --open             opened, or failed TAB <one sentence> (TODO(U4): it always refuses)
#   bash updates.sh --version-of <f>   that file's version, or nothing
# Every call exits 0 when it could answer and says the outcome in its output; a usage error exits 2.
# The words, the first that applies (D3.2): off (the file `off` exists) | none (no stamp that this version can
# read; <detail> is `newer` when the stamp is of a newer format) | manual (the stamp's line is not release;
# <detail> is that line) | unknown (no offer) | ready (the offered version is newer than the stamp's) |
# current. <scripts> is the stamp's version and <offered> the offer's; a field with no value is `-`.
# Sourced (`. updates.sh` defines functions and constants only, and may be sourced twice), with
# AU_UPDATE_DIR set first: auu_state, auu_refresh [--now], auu_notes, auu_noted, auu_open, auu_own,
# auu_version_of <file>, auu_newer <x> <y>. Run, it uses AU_UPDATE_DIR if set and otherwise the folder it
# lies in, which for the deployed copy is _update itself.
#
# The check (D3.2 to D3.4): in the states off, none and manual nothing is fetched or written. Otherwise at
# most once a day: a try less than 86,400 s after `tried` fetches nothing. `tried` is written before the
# fetch, so that a failure uses up the day, a check stopped by its time limit included, and it is put back
# as it was only when curl exits 6 or 7 on the first request (no route yet: the next firing tries again).
# The fetch: /usr/bin/curl with the person's curl settings ignored (-q), HTTPS only, 10 s, at most 1 MiB,
# the body to a file of its own, and nothing sent but what curl sends of itself (D3.10). The answer is taken
# only when curl exits 0, the code is 200, the file is within 1 MiB when measured again, and a version is
# found in it: the first heading `## v<a>.<b>.<c> (`. Newer, never different: an answer that names an older
# version than `offer` holds never lowers it, since GitHub may answer with a copy up to five minutes old.
#
# The notes cleaner (D3.2): the sections of every version newer than the stamp's, newest first. A version
# heading loses its "## ", and any other heading its marks; the lines of a paragraph are joined with one
# space (a list item's lines join their item), and empty lines are never doubled nor last; fence lines are
# dropped and the lines between them kept as they are; ** and backticks are removed; tabs become spaces and
# every other control character is removed, the two-byte ones (U+0080 to U+009F, which a terminal may obey as
# escapes) among them. It stops before the line that would pass 200 lines or 12,000 bytes, and then says
# where the rest is.
#
# Test variables (D3.2): AU_UPDATE_DIR; AU_UPDATE_NOW, seconds since 1970 that stand for now; AU_CURL
# (default /usr/bin/curl) and AU_OPEN (for U4's --open), the two programs a test replaces. AU_CURL must be an
# absolute path of plain characters; any other value fetches nothing. Every function that runs a program
# sets PATH itself, so that what comes first on the caller's PATH is never run.

_AUU_T=$'\t'
_AUU_VER='^v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$'
_AUU_HEAD='^## (v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})) \('
_AUU_TIME='^(0|[1-9][0-9]{0,11})$'
_AUU_UTC='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
_AUU_LINE='^[a-z][a-z0-9-]{0,19}$'
_AUU_COMMIT='^[0-9a-f]{40}$'
_AUU_SIZE='^(0|[1-9][0-9]{0,14})$'
_AUU_PROG='^/[A-Za-z0-9._/-]{1,250}$'
_AUU_CAP=1048576
_AUU_URL='https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/CHANGELOG.md'
_AUU_MORE='More: https://github.com/macaiport/auster/blob/release/CHANGELOG.md'

_auu_is_version() { [ "$1" = - ] || [[ $1 =~ $_AUU_VER ]]; }

_auu_split() { # LINE -> array _AUU_S, split on single tabs, empty fields kept
  local rest=$1
  _AUU_S=()
  while :; do
    case "$rest" in
      *"$_AUU_T"*) _AUU_S+=("${rest%%"$_AUU_T"*}"); rest=${rest#*"$_AUU_T"} ;;
      *) _AUU_S+=("$rest"); break ;;
    esac
  done
}

# FILE N -> a one-line record of exactly N fields after its format field (the header gives the rule): 0 with
# them in _AUU_F; 1 when it counts as absent; 2 when it is a newer format's
_auu_read() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f=$1 n=$2 first size line= more= r2=0 x
  _AUU_F=()
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  first=$(head -c 4096 "$f" 2>/dev/null | head -n 1)
  first=${first%%"$_AUU_T"*}
  case "$first" in
    'auster-record 1') ;;
    'auster-record '*) [[ ${first#auster-record } =~ ^[1-9][0-9]{0,8}$ ]] && return 2; return 1 ;;
    *) return 1 ;;
  esac
  size=$(stat -f %z "$f" 2>/dev/null) || return 1
  [[ $size =~ $_AUU_SIZE ]] && [ "$size" -le 4096 ] || return 1
  { IFS= read -r line || true; IFS= read -r more || r2=1; } < "$f" 2>/dev/null || return 1
  [ "$r2" = 1 ] && [ -z "$more" ] || return 1
  _auu_split "$line"
  [ "${#_AUU_S[@]}" -eq $((n + 1)) ] && [ "${_AUU_S[0]}" = 'auster-record 1' ] || return 1
  _AUU_F=("${_AUU_S[@]:1}")
  for x in "${_AUU_F[@]}"; do [ -n "$x" ] || return 1; done
  return 0
}

_auu_now() { # -> now, as seconds since 1970: AU_UPDATE_NOW when it is a time, else the clock
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin
  if [[ ${AU_UPDATE_NOW:-} =~ $_AUU_TIME ]]; then printf '%s\n' "$AU_UPDATE_NOW"; else date +%s; fi
}

_auu_own1() { # FOLDER -> 0 when it is a folder, not a link, of this account's, that group and others cannot write
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin s m
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  s=$(stat -f '%u %Lp' "$1" 2>/dev/null) || return 1
  [ "${s%% *}" = "$(id -u)" ] || return 1
  m=00${s#* }; m=${m: -3}
  case "${m:1:2}" in *[2367]*) return 1 ;; esac
}
auu_own() { _auu_own1 "$AU_UPDATE_DIR"; }   # TODO(U2): and the data root and every folder in it (D3.1)

_auu_put() { # FILE LINE -> LINE and a newline, written beside FILE and renamed over it; 1 when it could not
  # be, or FILE is a folder. A link in FILE's place is replaced, never followed.
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin t
  if [ -d "$1" ] && [ ! -L "$1" ]; then return 1; fi
  t=$(mktemp "${1%/*}/.put.XXXXXX" 2>/dev/null) || return 1
  if printf '%s\n' "$2" > "$t" 2>/dev/null && { [ ! -L "$1" ] || rm -f "$1"; } && mv -f "$t" "$1" 2>/dev/null; then return 0; fi
  rm -f "$t" 2>/dev/null
  return 1
}

_auu_move() { # FROM TO -> FROM renamed to TO; 1 when TO is a folder or the rename fails. A link is replaced.
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin
  if [ -d "$2" ] && [ ! -L "$2" ]; then return 1; fi
  { [ ! -L "$2" ] || rm -f "$2"; } && mv -f "$1" "$2" 2>/dev/null
}

_auu_drop() { local PATH=/usr/bin:/bin:/usr/sbin:/sbin; [ -z "$1" ] || rm -f "$1" 2>/dev/null; return 0; }

# FILE -> its version: the first heading "## v<a>.<b>.<c> (" in its first 1 MiB; 1 when there is none
auu_version_of() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin line
  [ -f "$1" ] || return 1
  head -c 1048576 "$1" 2>/dev/null | {
    while IFS= read -r line || [ -n "$line" ]; do
      line=${line%$'\r'}
      if [[ $line =~ $_AUU_HEAD ]]; then printf '%s\n' "${BASH_REMATCH[1]}"; exit 0; fi
    done
    exit 1
  }
}

# X Y -> 0 when X is a later version than Y, the three numbers compared as numbers; `-` is lower than every
# version. 1 otherwise, and unless both are a version or `-`.
auu_newer() {
  local x=$1 y=$2 a b i
  _auu_is_version "$x" && _auu_is_version "$y" || return 1
  [ "$x" != - ] || return 1
  [ "$y" != - ] || return 0
  x=${x#v}; y=${y#v}
  for i in 1 2 3; do
    a=${x%%.*}; b=${y%%.*}; x=${x#*.}; y=${y#*.}
    if [ "$a" -gt "$b" ]; then return 0; fi
    if [ "$a" -lt "$b" ]; then return 1; fi
  done
  return 1
}

_auu_offer() { # -> the offered version; 1 when there is no offer that counts, 2 when it is a newer format's
  local rc=0
  _auu_read "$AU_UPDATE_DIR/offer" 2 || rc=$?
  [ "$rc" = 0 ] || return "$rc"
  [[ ${_AUU_F[0]} =~ $_AUU_VER ]] && [[ ${_AUU_F[1]} =~ $_AUU_TIME ]] || return 1
  printf '%s\n' "${_AUU_F[0]}"
}

# -> AUU_WORD, AUU_INSTALLED (the stamp's version), AUU_OFFERED and AUU_DETAIL; auu_state prints them
_auu_state() {
  local rc=0 line=
  AUU_WORD= AUU_INSTALLED=- AUU_DETAIL=-
  AUU_OFFERED=$(_auu_offer) || AUU_OFFERED=-
  _auu_read "$AU_UPDATE_DIR/scripts" 4 || rc=$?
  if [ "$rc" = 0 ] && [[ ${_AUU_F[0]} =~ $_AUU_LINE ]] && _auu_is_version "${_AUU_F[1]}" \
     && { [ "${_AUU_F[2]}" = - ] || [[ ${_AUU_F[2]} =~ $_AUU_COMMIT ]]; } && [[ ${_AUU_F[3]} =~ $_AUU_UTC ]]; then
    line=${_AUU_F[0]} AUU_INSTALLED=${_AUU_F[1]}
  fi
  if [ -e "$AU_UPDATE_DIR/off" ] || [ -L "$AU_UPDATE_DIR/off" ]; then AUU_WORD=off; return 0; fi
  if [ -z "$line" ]; then
    AUU_WORD=none
    [ "$rc" != 2 ] || AUU_DETAIL=newer
    return 0
  fi
  if [ "$line" != release ]; then AUU_WORD=manual; AUU_DETAIL=$line; return 0; fi
  if [ "$AUU_OFFERED" = - ]; then AUU_WORD=unknown; return 0; fi
  # TODO(U3): ready also when some recipe has a build waiting (D3.3)
  if auu_newer "$AUU_OFFERED" "$AUU_INSTALLED"; then AUU_WORD=ready; else AUU_WORD=current; fi
}
auu_state() {
  _auu_state
  printf '%s\t%s\t%s\t%s\n' "$AUU_WORD" "$AUU_INSTALLED" "$AUU_OFFERED" "$AUU_DETAIL"
}

# [--now] -> asks GitHub which version release holds, at most once a day (the header gives the rules). Sets
# AUU_FETCH to fetched, failed or skipped. No rule reads curl's exit code for more than 0, or 6 and 7.
auu_refresh() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin force=${1:-} now t tmp code rc size ver have keep= curl=/usr/bin/curl
  AUU_FETCH=skipped
  _auu_state
  case "$AUU_WORD" in off|none|manual) return 0 ;; esac
  AUU_FETCH=failed
  now=$(_auu_now) && [[ $now =~ $_AUU_TIME ]] || return 0
  if [ -n "${AU_CURL:-}" ]; then [[ $AU_CURL =~ $_AUU_PROG ]] || return 0; curl=$AU_CURL; fi
  rc=0; _auu_read "$AU_UPDATE_DIR/tried" 1 || rc=$?
  [ "$rc" != 2 ] || return 0   # a newer version's `tried` is left as it is, so nothing is tried
  if [ "$rc" = 0 ] && [ "$force" != --now ] && [[ ${_AUU_F[0]} =~ $_AUU_TIME ]]; then
    t=${_AUU_F[0]}
    if [ "$t" -le "$now" ] && [ $((now - t)) -lt 86400 ]; then AUU_FETCH=skipped; return 0; fi
  fi
  rc=0; _auu_offer > /dev/null || rc=$?
  [ "$rc" != 2 ] || return 0   # and so is a newer version's `offer`
  auu_own || return 0
  find "$AU_UPDATE_DIR" -maxdepth 1 -type f \( -name '.fetch.*' -o -name '.put.*' -o -name '.keep.*' \) -mmin +10 -delete 2>/dev/null
  if [ -f "$AU_UPDATE_DIR/tried" ] && [ ! -L "$AU_UPDATE_DIR/tried" ]; then   # kept, to be put back on no route
    keep=$(mktemp "$AU_UPDATE_DIR/.keep.XXXXXX" 2>/dev/null) && cp -p "$AU_UPDATE_DIR/tried" "$keep" 2>/dev/null || { _auu_drop "$keep"; return 0; }
  fi
  _auu_put "$AU_UPDATE_DIR/tried" "auster-record 1$_AUU_T$now" || { _auu_drop "$keep"; return 0; }
  tmp=$(mktemp "$AU_UPDATE_DIR/.fetch.XXXXXX" 2>/dev/null) || { _auu_drop "$keep"; return 0; }
  rc=0
  code=$("$curl" -q --proto '=https' --tlsv1.2 -sS --max-time 10 --max-filesize "$_AUU_CAP" -o "$tmp" -w '%{http_code}' "$_AUU_URL" 2>/dev/null) || rc=$?
  if [ "$rc" = 6 ] || [ "$rc" = 7 ]; then   # no route to GitHub yet: `tried` as it was (D3.4)
    rm -f "$tmp"
    if [ -n "$keep" ]; then mv -f "$keep" "$AU_UPDATE_DIR/tried"; else rm -f "$AU_UPDATE_DIR/tried"; fi
    return 0
  fi
  _auu_drop "$keep"
  size=$(stat -f %z "$tmp" 2>/dev/null) || size=
  if [ "$rc" = 0 ] && [ "$code" = 200 ] && [[ $size =~ $_AUU_SIZE ]] && [ "$size" -le "$_AUU_CAP" ] \
     && ver=$(auu_version_of "$tmp") && [[ $ver =~ $_AUU_VER ]]; then
    have=$(_auu_offer) || have=-
    if auu_newer "$have" "$ver"; then
      rm -f "$tmp"   # an answer up to five minutes old must not lower the offer
    else
      # TODO(U3): the registry fetched too, and offer, notes.md and registry replaced together, only when both
      # were read and their versions agree (D3.3); until then the changelog alone is fetched and read
      _auu_move "$tmp" "$AU_UPDATE_DIR/notes.md" && _auu_put "$AU_UPDATE_DIR/offer" "auster-record 1$_AUU_T$ver$_AUU_T$now" || { rm -f "$tmp"; return 0; }
    fi
    AUU_FETCH=fetched
  else
    rm -f "$tmp"
  fi
  return 0
}

# The fetched notes of every version newer than the stamp's, cleaned (the header gives the rules)
auu_notes() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin low a=-1 b=0 c=0 f="$AU_UPDATE_DIR/notes.md" c1
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  _auu_state; low=$AUU_INSTALLED
  if [[ $low =~ $_AUU_VER ]]; then low=${low#v}; a=${low%%.*}; low=${low#*.}; b=${low%%.*}; c=${low#*.}; fi
  c1=$(printf 's/\302[\200-\237]//g')
  head -c 1048576 "$f" | LC_ALL=C tr '\011' ' ' | LC_ALL=C tr -d '\000-\011\013-\037\177' | LC_ALL=C sed "$c1" \
    | LC_ALL=C awk -v a0="$a" -v b0="$b" -v c0="$c" -v more="$_AUU_MORE" '
    function out(s) {
      if (stopped) return
      if (lines + 1 > 200 || bytes + length(s) + 1 > 12000) { print more; stopped = 1; return }
      print s; lines++; bytes += length(s) + 1
    }
    function emit(s) {   # an empty line waits for a line of text after it, so that none is doubled or last
      if (s == "") { if (lines > 0) pend = 1; return }
      if (pend) { pend = 0; out("") }
      out(s)
    }
    function clean(s) { gsub(/\*\*/, "", s); gsub(/`/, "", s); return s }
    function flush() { if (buf != "") { emit(clean(buf)); buf = "" } }
    function newer(h,   p, n) {
      sub(/^## v/, "", h); sub(/ [(].*$/, "", h); n = split(h, p, ".")
      if (n != 3) return 0
      if (p[1] + 0 != a0 + 0) return p[1] + 0 > a0 + 0
      if (p[2] + 0 != b0 + 0) return p[2] + 0 > b0 + 0
      return p[3] + 0 > c0 + 0
    }
    /^```/ { flush(); fence = !fence; next }
    fence { if (show) emit($0); next }
    /^## / {
      flush()
      if ($0 ~ /^## v(0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?)[.](0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?)[.](0|[1-9][0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?) [(]/ && newer($0)) {
        if (shown) emit("")
        show = 1; shown = 1; emit(clean(substr($0, 4)))
      } else show = 0
      next
    }
    !show { next }
    /^(#|###+) / { flush(); h = $0; sub(/^#+ /, "", h); emit(clean(h)); next }
    /^ *$/ { flush(); emit(""); next }
    /^(- |[0-9]+\. )/ { flush(); buf = $0; next }
    { line = $0; if (buf != "") { sub(/^ +/, "", line); buf = buf " " line } else buf = line }
    END { flush() }'
}

# For the check job's notification (TODO(U7)): prints the offered version when the state is ready and `noted`
# does not yet hold that version with the count 2, and then writes `noted` with the count raised. Otherwise
# it prints nothing; a `noted` of a newer format is left as it is, and nothing is printed.
auu_noted() {
  local n=1 rc=0
  _auu_state
  [ "$AUU_WORD" = ready ] || return 0
  _auu_read "$AU_UPDATE_DIR/noted" 2 || rc=$?
  [ "$rc" != 2 ] || return 0
  if [ "$rc" = 0 ] && [[ ${_AUU_F[0]} =~ $_AUU_VER ]] && [[ ${_AUU_F[1]} =~ ^[12]$ ]] && [ "${_AUU_F[0]}" = "$AUU_OFFERED" ]; then
    [ "${_AUU_F[1]}" != 2 ] || return 0
    n=2
  fi
  auu_own || return 0
  _auu_put "$AU_UPDATE_DIR/noted" "auster-record 1$_AUU_T$AUU_OFFERED$_AUU_T$n" || return 0
  printf '%s\n' "$AUU_OFFERED"
}

# TODO(U4): the update's .command file, written into a new folder only the person can read and handed to
# Terminal with AU_OPEN (D3.6). Until then it writes nothing and refuses, in the contract's form.
auu_open() {
  _auu_state
  if [ "$AUU_WORD" != ready ]; then printf 'failed\t%s\n' "No update is waiting."; return 0; fi
  printf 'failed\t%s\n' "This version of Auster cannot start the update from here. Paste the installer line from the guide instead."
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  if [ -z "${AU_UPDATE_DIR:-}" ]; then AU_UPDATE_DIR=$(cd "$(/usr/bin/dirname "$0")" && pwd -P) || exit 1; fi
  case "${1:-}" in
    '') auu_state ;;
    --refresh)
      auu_refresh "${2:-}"; _auu_state
      printf '%s\t%s\t%s\t%s\t%s\n' "$AUU_WORD" "$AUU_INSTALLED" "$AUU_OFFERED" "$AUU_DETAIL" "$AUU_FETCH" ;;
    --notes) auu_notes ;;
    --noted) auu_noted ;;
    --open) auu_open ;;
    --version-of) auu_version_of "${2:-}" || true ;;
    *) echo "usage: updates.sh [--refresh [--now] | --notes | --noted | --open | --version-of <file>]" >&2; exit 2 ;;
  esac
  exit 0
fi
