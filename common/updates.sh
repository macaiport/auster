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
#   U4  --open: the update's .command file, handed to Terminal (D3.6); until then it refuses;
#   U5  partial downloads among the disk holdings of a recipe's line (where U5 keeps them);
#   U7  the check job's notification, which reads --noted.
# U2 (2026-11-27) made auu_own the ownership rule over the whole data root (D3.1; tests/t6-records-own.sh), and
# T6's and T95's tables run this file's one-line reader through the cases they run every reader through. The
# readers of D3.1's other records are common/auster's, which the installer and bin/auster share: bin/auster must
# still work with _update moved to the Trash.
# U3 (2026-11-27): the second fetch, release's registry.tsv, on every check; offer, notes.md and registry written
# together, only when both were read and agree on the version (D3.3); each recipe's line (--recipes), from
# _update/registry and the records in builds/ through section C (capability.js); and `ready` when some recipe has
# a build waiting. Its own readers of a descriptor and of `hold` follow common/auster's (D3.1), since this file
# sources nothing, and T6's and T95's tables run them too. Its tests: T1, T3, T4, T14, T42 (their registry
# halves), T11, T22 (the update's half), T23, T35 (with bin/auster's status), T40 and T44 (the recipe half).
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
#   registry  the registry as last fetched (A3; its first line carries its own format number and version), written
#             with offer and notes.md and only when its version equals theirs. Read only for each recipe's line,
#             through the registry reader, and never the source of a size or sha256 for an install (D3.6)
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
#   bash updates.sh --recipes          the state line, then one `recipe` line for each recipe this Mac serves (U3)
# Every call exits 0 when it could answer and says the outcome in its output; a usage error exits 2.
# The words, the first that applies (D3.2): off (the file `off` exists) | none (no stamp that this version can
# read; <detail> is `newer` when the stamp is of a newer format) | manual (the stamp's line is not release;
# <detail> is that line) | unknown (no offer) | ready (the offered version is newer than the stamp's, or some
# recipe has a build waiting, D3.3) | current. <scripts> is the stamp's version and <offered> the offer's; a
# field with no value is `-`.
#
# A recipe's line (D3.3), one for each folder builds/<recipe id>/ that holds `serving`, in the order of their ids,
# fifteen fields separated by single tabs, every value matched to its pattern (a field with no value is `-`):
#   recipe <recipe id> <word> <reasons> <build served> <withdrawal> <build waiting> <download> <people> <context>
#          <gpu MiB> <in all MiB> <label> <model file> <released>
#   word        same: the build D3.7 picks for it is the one it serves | waiting: another build is picked |
#               passed-over: nothing can be picked | withdrawn: a `withdraw` line names the build it serves, and
#               nothing else is picked | unknown: not judged, because the word for the Mac is off, none, manual or
#               unknown, or _update/registry is missing, is not of the offered version, or is older than the
#               scripts, or the data root is not this account's alone, or section C's programs are missing or
#               gave no `line`
#   reasons     for passed-over and withdrawn, what rules out its builds, comma-separated: fit (does not fit),
#               room (no room on disk), held, failed (failed its test here), unreadable (the registry cannot be
#               read for it), tier (above the recipe's trust tiers), withdrawn, serving (its `serving` cannot be
#               read), figures (this Mac's figures, builds/mac, cannot be read)
#   withdrawal  of the build served: a reason A3 lists, `other`, or -
#   build waiting, download (the bytes it would fetch that store/ does not hold), people, context (per person),
#   gpu MiB and in all MiB (what it would hold on this Mac, C2): for waiting only
#   label       the recipe's label in the registry; model file, the build waiting's; released, the date of the
#               offered version's heading in notes.md (`## v<a>.<b>.<c> (YYYY-MM-DD`)
# How it is judged: the build served, its people and every descriptor from builds/, read as common/auster reads
# them (D3.1); `hold`, which passes the recipe over when it cannot be read; the build ids of failed/; builds/mac;
# the disk holdings (store/, engines/ and every descriptor; no disk rule when any descriptor cannot be read) and
# `df -k` of the data root; all given to section C's capability.js with _update/registry (its `line` record, D3.7),
# and the label and file name from registry.js. Both are found beside this file (the tree's common/) or in the
# data root's jobs/ (B3 step 3 copies them there). The state line's word reads the same lines when the versions
# alone give `current`, without the names; --noted, --notes and the check's own start read the versions alone.
#
# Sourced (`. updates.sh` defines functions and constants only, and may be sourced twice), with
# AU_UPDATE_DIR set first: auu_state, auu_refresh [--now], auu_notes, auu_noted, auu_open, auu_own,
# auu_version_of <file>, auu_newer <x> <y>, auu_recipes. Run, it uses AU_UPDATE_DIR if set and otherwise the
# folder it lies in, which for the deployed copy is _update itself.
#
# The check (D3.2 to D3.4): in the states off, none and manual nothing is fetched or written. Otherwise at
# most once a day: a try less than 86,400 s after `tried` fetches nothing. `tried` is written before the
# fetch, so that a failure uses up the day, a check stopped by its time limit included, and it is put back
# as it was only when curl exits 6 or 7 on the first request (no route yet: the next firing tries again;
# the second request is then not made). Two requests, the same two whatever is waiting (D3.3, D3.10):
# release's CHANGELOG.md, then release's registry.tsv, asked whatever the first answered; each with
# /usr/bin/curl, the person's curl settings ignored (-q), HTTPS only, 10 s, at most 1 MiB, the body to a file
# of its own, and nothing sent but what curl sends of itself. An answer is taken only when curl exits 0, the
# code is 200 and the file is within 1 MiB when measured again; the changelog's version is its first heading
# `## v<a>.<b>.<c> (`, the registry's the third field of its first line (`auster-registry`, a format number,
# the version, within its first 1,000 bytes and ending in a newline). offer, notes.md and registry are replaced
# together (registry, then notes.md, then offer, each by rename), and only when both answers were taken and
# the two versions are the same; otherwise none is written, the try is failed and nothing is said. Newer,
# never different: an answer that names an older version than `offer` holds never lowers it, since GitHub may
# answer with a copy up to five minutes old.
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
_AUU_REG_URL='https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/registry.tsv'
_AUU_MORE='More: https://github.com/macaiport/auster/blob/release/CHANGELOG.md'
_AUU_RECIPE='^r[a-z2-7]{12}$'
_AUU_BUILD='^b[a-z2-7]{12}$'
_AUU_SHA='^[0-9a-f]{64}$'
_AUU_NUM='^(0|[1-9][0-9]{0,8})$'
_AUU_UNIT='^(0(\.[0-9]{1,3})?|1(\.0{1,3})?)$'
_AUU_SPEED='^(0|[1-9][0-9]{0,5})(\.[0-9]{1,3})?$'
_AUU_DATE='^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$'
_AUU_ENTRY='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z-b[a-z2-7]{12}$'
_AUU_REASONS=' security egress quality licence publisher superseded corrected '
_AUU_HERE=$(cd "$(/usr/bin/dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd -P) || _AUU_HERE=

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

# The readers of a descriptor and of `hold` (D3.1), copies of common/auster's au_desc_read, au_entry_read and
# au_hold_read, with the same bounds and patterns; T6 and T95 run them through the same table.
_auu_format() { # FILE KIND -> the format first, from the first field of the first 4,096 bytes: 0 for `KIND 1`; 2 for
  # KIND with a larger number (a newer format's, left as it is); 1 for anything else (absent)
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin first n
  first=$(head -c 4096 "$1" 2>/dev/null | head -n 1)
  first=${first%%"$_AUU_T"*}
  [ "$first" = "$2 1" ] && return 0
  case "$first" in "$2 "*) n=${first#"$2 "} ;; *) return 1 ;; esac
  [[ $n =~ ^[1-9][0-9]{0,8}$ ]] && return 2
  return 1
}

_auu_nl_end() { local PATH=/usr/bin:/bin:/usr/sbin:/sbin; [ "$(tail -c 1 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = 0a ]; }

# FILE -> _AUU_D_* from a descriptor (A5): `serving`, or an entry of kept/ or failed/. 0 when it reads; 2 when it is
# of a newer format; 1 when it counts as absent. The format first (`auster-descriptor 1`); then a regular file, not
# a link, of at most 8,192 bytes ending in a newline, of five lines of at most 1,000 bytes: the format line alone; the
# build, engine and model lines as the registry has them, each known field matched whole and any field after the
# last one known kept and not read, the build's engine and model being those lines' own; and the launch line,
# exactly six fields: people (1 to 64), context per person (1 to 1,048,576), port (1 to 65,535), the sha256 of the
# engine's file list, and the writing speed
_auu_desc() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f=$1 l n=0 be bm s lines=()
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  _auu_format "$f" auster-descriptor || return $?
  s=$(stat -f %z "$f" 2>/dev/null) && [[ $s =~ $_AUU_SIZE ]] && [ "$s" -le 8192 ] && _auu_nl_end "$f" || return 1
  while IFS= read -r l; do
    n=$((n + 1))
    [ "$n" -le 5 ] && [ "${#l}" -le 1000 ] || return 1
    lines+=("$l")
  done < "$f"
  [ "$n" = 5 ] && [ "${lines[0]}" = 'auster-descriptor 1' ] || return 1
  _auu_split "${lines[1]}"
  [ "${#_AUU_S[@]}" -ge 14 ] && [ "${_AUU_S[0]}" = build ] || return 1
  [[ ${_AUU_S[1]} =~ $_AUU_BUILD ]] && [[ ${_AUU_S[2]} =~ ^e[a-z2-7]{12}$ ]] && [[ ${_AUU_S[3]} =~ ^m[a-z2-7]{12}$ ]] || return 1
  [[ ${_AUU_S[4]} =~ $_AUU_SHA ]] && [[ ${_AUU_S[5]} =~ $_AUU_SHA ]] && [[ ${_AUU_S[6]} =~ $_AUU_SHA ]] || return 1
  [[ ${_AUU_S[7]} =~ $_AUU_NUM ]] && [[ ${_AUU_S[8]} =~ $_AUU_NUM ]] && [[ ${_AUU_S[9]} =~ $_AUU_NUM ]] && [[ ${_AUU_S[10]} =~ $_AUU_NUM ]] || return 1
  [[ ${_AUU_S[11]} =~ $_AUU_UNIT ]] && [[ ${_AUU_S[12]} =~ $_AUU_UNIT ]] && [[ ${_AUU_S[13]} =~ ^[a-z][a-z0-9-]{1,40}$ ]] || return 1
  _AUU_D_BUILD=${_AUU_S[1]} _AUU_D_TEMPLATE=${_AUU_S[4]} _AUU_D_SYSTEM=${_AUU_S[5]} _AUU_D_TEST=${_AUU_S[6]} be=${_AUU_S[2]} bm=${_AUU_S[3]}
  _auu_split "${lines[2]}"
  [ "${#_AUU_S[@]}" -ge 8 ] && [ "${_AUU_S[0]}" = engine ] && [ "${_AUU_S[1]}" = "$be" ] && [ "${_AUU_S[2]}" = macos-arm64 ] || return 1
  [[ ${_AUU_S[3]} =~ ^b[0-9]{4,7}$ ]] && [[ ${_AUU_S[4]} =~ ^llama-b[0-9]{4,7}-bin-macos-arm64\.(tar\.gz|zip)$ ]] || return 1
  [[ ${_AUU_S[5]} =~ $_AUU_SIZE ]] && [[ ${_AUU_S[6]} =~ $_AUU_SHA ]] && [[ ${_AUU_S[7]} =~ $_AUU_NUM ]] || return 1
  _AUU_D_ENGINE=${_AUU_S[6]}
  _auu_split "${lines[3]}"
  [ "${#_AUU_S[@]}" -ge 10 ] && [ "${_AUU_S[0]}" = model ] && [ "${_AUU_S[1]}" = "$bm" ] || return 1
  [[ ${_AUU_S[2]} =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,95}/[A-Za-z0-9][A-Za-z0-9._-]{0,95}$ ]] && [[ ${_AUU_S[3]} =~ ^[0-9a-f]{40}$ ]] || return 1
  [[ ${_AUU_S[4]} =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,200}\.gguf$ ]] && [[ ${_AUU_S[5]} =~ $_AUU_SIZE ]] && [[ ${_AUU_S[6]} =~ $_AUU_SHA ]] || return 1
  [[ ${_AUU_S[7]} =~ ^[a-z0-9.-]{2,30}$ ]] && [[ ${_AUU_S[8]} =~ ^(publisher|endorsed|third-party)$ ]] && [[ ${_AUU_S[9]} =~ $_AUU_NUM ]] || return 1
  _AUU_D_MODEL=${_AUU_S[6]}
  _auu_split "${lines[4]}"
  [ "${#_AUU_S[@]}" -eq 6 ] && [ "${_AUU_S[0]}" = launch ] || return 1
  [[ ${_AUU_S[1]} =~ ^[1-9][0-9]?$ ]] && [ "${_AUU_S[1]}" -le 64 ] || return 1
  [[ ${_AUU_S[2]} =~ ^[1-9][0-9]{0,6}$ ]] && [ "${_AUU_S[2]}" -le 1048576 ] || return 1
  [[ ${_AUU_S[3]} =~ ^[1-9][0-9]{0,4}$ ]] && [ "${_AUU_S[3]}" -le 65535 ] || return 1
  [[ ${_AUU_S[4]} =~ $_AUU_SHA ]] && [[ ${_AUU_S[5]} =~ $_AUU_SPEED ]] || return 1
  _AUU_D_PEOPLE=${_AUU_S[1]} _AUU_D_CONTEXT=${_AUU_S[2]}
}

_auu_entry() { # FILE -> as _auu_desc, for an entry of kept/ or failed/, whose name is also matched: the date and the
  # build id, `2026-11-26T15:04:05Z-b...`, the build its own build line names
  local n=${1##*/} rc=0
  [[ $n =~ $_AUU_ENTRY ]] || return 1
  _auu_desc "$1" || rc=$?
  [ "$rc" = 0 ] || return "$rc"
  [ "${n#*Z-}" = "$_AUU_D_BUILD" ]
}

# RECIPE -> AUU_HOLD from builds/<recipe>/hold (D3.7): absent, when there is none (no holds); ok, with AUU_HOLD_IDS,
# the builds this recipe is not to be moved to; newer, left as it is; or unreadable. Unreadable and newer pass the
# recipe over, and are never taken as no holds (D3.1). Its form: `auster-record 1`, then one build id a line, at most
# 64, every line ending in a newline; bound 1,024 bytes. A link or a folder is unreadable
_auu_hold() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="${AU_UPDATE_DIR%/*}/builds/$1/hold" l n=0 rc=0 s
  AUU_HOLD=absent AUU_HOLD_IDS=()
  [ -e "$f" ] || [ -L "$f" ] || return 0
  AUU_HOLD=unreadable
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  _auu_format "$f" auster-record || rc=$?
  if [ "$rc" = 2 ]; then AUU_HOLD=newer; return 0; fi
  s=$(stat -f %z "$f" 2>/dev/null)
  [ "$rc" = 0 ] && [[ $s =~ $_AUU_SIZE ]] && [ "$s" -le 1024 ] && _auu_nl_end "$f" || return 0
  while IFS= read -r l; do
    n=$((n + 1))
    if [ "$n" = 1 ]; then [ "$l" = 'auster-record 1' ] || return 0; continue; fi
    [ "$n" -le 65 ] && [[ $l =~ $_AUU_BUILD ]] || { AUU_HOLD_IDS=(); return 0; }
    AUU_HOLD_IDS+=("$l")
  done < "$f"
  AUU_HOLD=ok
}

_auu_reg_version() { # FILE -> the version on a registry's first line (A3: auster-registry, a format number, the
  # version, any fields after it not read), within its first 1,000 bytes and ending in a newline; 1 when there is none
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin line
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  line=$(head -c 1001 "$1" 2>/dev/null | { IFS= read -r l && printf '%s' "$l"; }) || return 1
  _auu_split "$line"
  [ "${#_AUU_S[@]}" -ge 3 ] && [ "${_AUU_S[0]}" = auster-registry ] && [[ ${_AUU_S[1]} =~ ^[1-9][0-9]{0,8}$ ]] \
    && [[ ${_AUU_S[2]} =~ $_AUU_VER ]] || return 1
  printf '%s\n' "${_AUU_S[2]}"
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
# -> 0 when AU_UPDATE_DIR, its data root (the folder above it, mode 0700) and every folder in that root, at any
# depth, are this account's and nobody else may write to them, and no link in the root leads to a folder, but those
# inside an engine's unpacked tree, which the installer checked point inside it (D3.1, Ownership; common/auster's
# au_own_tree is the same rule for the installer and bin/auster). Every write here comes after it
auu_own() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin root=${AU_UPDATE_DIR%/*} bad
  _auu_own1 "$AU_UPDATE_DIR" || return 1
  [ -n "$root" ] && [ "$root" != "$AU_UPDATE_DIR" ] && _auu_own1 "$root" && [ "$(stat -f %Lp "$root" 2>/dev/null)" = 700 ] || return 1
  bad=$(cd "$root" 2>/dev/null && find . \( -type d \( ! -user "$(id -u)" -o -perm +022 \) \) -print -o \
    \( -type l ! -path './engines/*/root/*' -exec test -d {} \; \) -print 2>/dev/null) || return 1
  [ -z "$bad" ]
}

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

# [versions] -> AUU_WORD, AUU_INSTALLED (the stamp's version), AUU_OFFERED and AUU_DETAIL; auu_state prints them.
# When the versions alone give `current`, each recipe's line is judged (without names), and a build waiting makes
# the word `ready` (D3.3); with `versions` the word is the versions' alone and no recipe is judged
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
  if auu_newer "$AUU_OFFERED" "$AUU_INSTALLED"; then AUU_WORD=ready; else AUU_WORD=current; fi
  [ "${1:-}" != versions ] && [ "$AUU_WORD" = current ] || return 0
  _auu_recipes
  [ "$AUU_WAITING" = 0 ] || AUU_WORD=ready
}
auu_state() {
  _auu_state
  printf '%s\t%s\t%s\t%s\n' "$AUU_WORD" "$AUU_INSTALLED" "$AUU_OFFERED" "$AUU_DETAIL"
}

# [--now] -> asks GitHub which version release holds, at most once a day (the header gives the rules). Sets
# AUU_FETCH to fetched, failed or skipped. No rule reads curl's exit code for more than 0, or 6 and 7.
auu_refresh() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin force=${1:-} now t tmp reg code rcode rc rrc size rsize ver have keep= curl=/usr/bin/curl
  AUU_FETCH=skipped
  _auu_state versions
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
  # The registry, asked whatever the changelog answered, so that the same two requests go out on every check (D3.3,
  # D3.10); a no route here uses up the day like any other failure (D3.4)
  reg=$(mktemp "$AU_UPDATE_DIR/.fetch.XXXXXX" 2>/dev/null) || { rm -f "$tmp"; return 0; }
  rrc=0
  rcode=$("$curl" -q --proto '=https' --tlsv1.2 -sS --max-time 10 --max-filesize "$_AUU_CAP" -o "$reg" -w '%{http_code}' "$_AUU_REG_URL" 2>/dev/null) || rrc=$?
  size=$(stat -f %z "$tmp" 2>/dev/null) || size=
  rsize=$(stat -f %z "$reg" 2>/dev/null) || rsize=
  if [ "$rc" = 0 ] && [ "$code" = 200 ] && [[ $size =~ $_AUU_SIZE ]] && [ "$size" -le "$_AUU_CAP" ] \
     && ver=$(auu_version_of "$tmp") && [[ $ver =~ $_AUU_VER ]] \
     && [ "$rrc" = 0 ] && [ "$rcode" = 200 ] && [[ $rsize =~ $_AUU_SIZE ]] && [ "$rsize" -le "$_AUU_CAP" ] \
     && [ "$(_auu_reg_version "$reg")" = "$ver" ]; then
    have=$(_auu_offer) || have=-
    if auu_newer "$have" "$ver"; then
      rm -f "$tmp" "$reg"   # an answer up to five minutes old must not lower the offer
    else   # the three together (D3.3): the offer last, so that a run cut short between them leaves a registry whose
      # version the offer does not name, which no recipe's line uses (_auu_recipes) until the next check
      _auu_move "$reg" "$AU_UPDATE_DIR/registry" && _auu_move "$tmp" "$AU_UPDATE_DIR/notes.md" \
        && _auu_put "$AU_UPDATE_DIR/offer" "auster-record 1$_AUU_T$ver$_AUU_T$now" || { rm -f "$tmp" "$reg"; return 0; }
    fi
    AUU_FETCH=fetched
  else
    rm -f "$tmp" "$reg"
  fi
  return 0
}

# --- each recipe's line (D3.3, D3.7; the header gives its form and how it is judged) --------------------------------

_auu_js() { # -> the folder that holds section C's capability.js, the two files it loads, and registry.js: this file's
  # own (the tree's common/), else the data root's jobs/ (B3 step 3 copies them there); 1 when neither holds all four
  local d
  for d in "$_AUU_HERE" "${AU_UPDATE_DIR%/*}/jobs"; do
    [ -n "$d" ] && [ -f "$d/capability.js" ] && [ -f "$d/capability-lib.js" ] && [ -f "$d/registry-lib.js" ] \
      && [ -f "$d/registry.js" ] || continue
    printf '%s\n' "$d"
    return 0
  done
  return 1
}

_auu_holdings() { # OUT -> the disk holdings in capability-lib.js's form (`auster-disk 1`): each file in store/ and folder
  # in engines/ named by a sha256, with what it takes on disk, and a `desc` line for every descriptor of every recipe
  # (C6: a file counts as free only when no descriptor names it). 1 when a descriptor cannot be read or an entry's
  # date is out of form, so that no disk rule is applied rather than one that would count its files free.
  # TODO(U5): partial downloads, once U5 settles where they are kept
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin root=${AU_UPDATE_DIR%/*} f n s r kind date
  {
    printf 'auster-disk 1\n'
    for f in "$root"/store/*; do
      n=${f##*/}
      [[ $n =~ $_AUU_SHA ]] && [ -f "$f" ] && [ ! -L "$f" ] || continue
      s=$(stat -f %z "$f" 2>/dev/null) && [[ $s =~ $_AUU_SIZE ]] || return 1
      printf 'file\tstore/%s\t%s\n' "$n" "$s"
    done
    for f in "$root"/engines/*; do
      n=${f##*/}
      [[ $n =~ $_AUU_SHA ]] && [ -d "$f" ] && [ ! -L "$f" ] || continue
      s=$(du -sk "$f" 2>/dev/null) || return 1
      s=${s%%[!0-9]*}
      [[ $s =~ ^(0|[1-9][0-9]{0,11})$ ]] || return 1
      printf 'file\tengines/%s\t%s\n' "$n" $((s * 1024))
    done
    for f in "$root"/builds/r*/serving "$root"/builds/r*/kept/* "$root"/builds/r*/failed/*; do
      [ -e "$f" ] || [ -L "$f" ] || continue
      case "$f" in
        */serving) kind=serving date=- r=${f%/serving} ;;
        *) kind=${f%/*}; kind=${kind##*/} r=${f%/*/*} date=${f##*/}; date=${date%-b*} ;;
      esac
      r=${r##*/}
      [[ $r =~ $_AUU_RECIPE ]] || continue
      if [ "$kind" = serving ]; then _auu_desc "$f" || return 1; else _auu_entry "$f" && [[ $date =~ $_AUU_DATE ]] || return 1; fi
      printf 'desc\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$r" "$kind" "$date" "$_AUU_D_BUILD" "$_AUU_D_ENGINE" \
        "$_AUU_D_MODEL" "$_AUU_D_TEMPLATE" "$_AUU_D_SYSTEM" "$_AUU_D_TEST"
    done
  } > "$1"
}

_auu_released() { # VERSION -> the date of its heading in notes.md, `## <version> (YYYY-MM-DD)`, or -
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin f="$AU_UPDATE_DIR/notes.md" l d
  [[ $1 =~ $_AUU_VER ]] && [ -f "$f" ] && [ ! -L "$f" ] || { echo -; return 0; }
  l=$(head -c 1048576 "$f" 2>/dev/null | LC_ALL=C grep -m 1 -E "^## ${1//./\\.} \\([0-9]{4}-[0-9]{2}-[0-9]{2}\\)")
  d=${l#*\(}; d=${d%%)*}
  if [[ ${d}T00:00:00Z =~ $_AUU_DATE ]]; then printf '%s\n' "$d"; else echo -; fi
}

# RECIPE JS WORK [names] -> its line appended to AUU_RECIPES, AUU_WAITING=1 when it is waiting. JS is _auu_js's
# folder; WORK holds the disk holdings (disk) and `df -k` (df) when they could be made, which capability.js reads;
# with `names`, the label, the model file and the date
_auu_recipe_line() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin r=$1 js=$2 w=$3 root=${AU_UPDATE_DIR%/*} f id l out opts=() nodisk=() lf=() cf=()
  local word=unknown reasons=- served=- wd=- pick=- dl=- people=- ctx=- gpu=- all=- label=- file=- released=- T=$_AUU_T
  if _auu_desc "$root/builds/$r/serving"; then
    served=$_AUU_D_BUILD
    opts=(--serving "$served" --people "$_AUU_D_PEOPLE" --mac "$root/builds/mac")
    _auu_hold "$r"
    case "$AUU_HOLD" in
      absent) ;;
      ok) for id in ${AUU_HOLD_IDS[@]+"${AUU_HOLD_IDS[@]}"}; do opts+=(--held "$id"); done ;;
      *) opts+=(--hold-unreadable) ;;   # unreadable, or a newer version's: never taken as no holds (D3.1)
    esac
    for f in "$root/builds/$r"/failed/*; do
      { [ -e "$f" ] || [ -L "$f" ]; } && _auu_entry "$f" && opts+=(--failed "$_AUU_D_BUILD")
    done
    if [ -f "$w/disk" ]; then
      opts+=(--disk "$w/disk")
      [ ! -f "$w/df" ] || opts+=(--df "$w/df")
    else
      nodisk=(-u AU_DISK_FREE_BYTES -u AU_DISK_TOTAL_BYTES)   # no disk figures at all: no disk rule
    fi
    out=$(env ${nodisk[@]+"${nodisk[@]}"} osascript -l JavaScript "$js/capability.js" "$AU_UPDATE_DIR/registry" "$r" "${opts[@]}" 2>/dev/null)
    while IFS= read -r l; do
      _auu_split "$l"
      case "${_AUU_S[0]}" in
        line) lf=("${_AUU_S[@]}") ;;
        choice) cf=("${_AUU_S[@]}") ;;
      esac
    done <<< "$out"
    if [ "${#lf[@]}" -ge 6 ] && [[ ${lf[1]} =~ ^(same|waiting|withdrawn|passed-over|unreadable)$ ]] \
       && { [ "${lf[2]}" = - ] || [[ ${lf[2]} =~ $_AUU_BUILD ]]; } && { [ "${lf[3]}" = - ] || [ "${lf[3]}" = other ] || [[ $_AUU_REASONS = *" ${lf[3]} "* ]]; } \
       && { [ "${lf[4]}" = - ] || [[ ${lf[4]} =~ ^[a-z]{1,20}(,[a-z]{1,20}){0,15}$ ]]; } && { [ "${lf[5]}" = - ] || [[ ${lf[5]} =~ $_AUU_SIZE ]]; }; then
      word=${lf[1]} reasons=${lf[4]} wd=${lf[3]}
      if [ "$word" = unreadable ]; then word=passed-over reasons=unreadable; fi
      if [ "$word" = waiting ] && [ "${lf[2]}" != - ]; then
        AUU_WAITING=1 pick=${lf[2]} dl=${lf[5]}
        if [ "${#cf[@]}" -ge 6 ] && [ "${cf[1]}" = "$pick" ] && [[ ${cf[2]} =~ ^[1-9][0-9]?$ ]] && [[ ${cf[3]} =~ $_AUU_NUM ]] \
           && [[ ${cf[4]} =~ $_AUU_NUM ]] && [[ ${cf[5]} =~ $_AUU_NUM ]]; then
          people=${cf[2]} ctx=${cf[3]} gpu=${cf[4]} all=${cf[5]}
        fi
      elif [ "$word" = waiting ]; then word=unknown
      fi
    fi
  else
    word=passed-over reasons=serving
  fi
  if [ "${4:-}" = names ] && [ "$reasons" != unreadable ]; then
    out=$(osascript -l JavaScript "$js/registry.js" "$AU_UPDATE_DIR/registry" "$r" 2>/dev/null)
    while IFS= read -r l; do
      _auu_split "$l"
      case "${_AUU_S[0]}" in
        recipe) [ "${#_AUU_S[@]}" -ge 5 ] && [ "${_AUU_S[1]}" = "$r" ] && [[ ${_AUU_S[4]} =~ ^[a-z][a-z0-9-]{1,40}$ ]] && label=${_AUU_S[4]} ;;
        build) [ "$pick" != - ] && [ "${#_AUU_S[@]}" -ge 28 ] && [ "${_AUU_S[4]}" = "$pick" ] \
                 && [[ ${_AUU_S[27]} =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,200}\.gguf$ ]] && file=${_AUU_S[27]} ;;
      esac
    done <<< "$out"
    released=$(_auu_released "$AUU_OFFERED")
  fi
  AUU_RECIPES+=("recipe$T$r$T$word$T$reasons$T$served$T$wd$T$pick$T$dl$T$people$T$ctx$T$gpu$T$all$T$label$T$file$T$released")
}

# [names] -> AUU_RECIPES, each recipe's line, and AUU_WAITING (1 when one is waiting). A recipe is judged only when the
# word is current or ready, _update/registry is of the offered version and not older than the scripts (a registry
# fetched before this Mac was updated knows nothing of what it serves now), section C's programs are found, and the data
# root is this account's alone (they run from jobs/); otherwise every line says unknown. Nothing is written but in a
# folder of TMPDIR's, removed at the end
_auu_recipes() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin root=${AU_UPDATE_DIR%/*} s r js= w= judge=1 v
  AUU_RECIPES=() AUU_WAITING=0
  case "$AUU_WORD" in current|ready) ;; *) judge=0 ;; esac
  if [ "$judge" = 1 ]; then
    v=$(_auu_reg_version "$AU_UPDATE_DIR/registry") && [ "$v" = "$AUU_OFFERED" ] && ! auu_newer "$AUU_INSTALLED" "$AUU_OFFERED" \
      && js=$(_auu_js) && auu_own && w=$(mktemp -d "${TMPDIR:-/tmp}/auster-recipes.XXXXXX" 2>/dev/null) || judge=0
  fi
  if [ "$judge" = 1 ]; then
    if _auu_holdings "$w/disk"; then df -k "$root" > "$w/df" 2>/dev/null || rm -f "$w/df"; else rm -f "$w/disk"; fi
  fi
  for s in "$root"/builds/r*/serving; do
    [ -e "$s" ] || [ -L "$s" ] || continue
    r=${s%/serving}; r=${r##*/}
    [[ $r =~ $_AUU_RECIPE ]] || continue
    if [ "$judge" = 1 ]; then _auu_recipe_line "$r" "$js" "$w" "${1:-}"
    else AUU_RECIPES+=("recipe$_AUU_T$r${_AUU_T}unknown$(printf "$_AUU_T%s" - - - - - - - - - - - -)"); fi
  done
  [ -z "$w" ] || rm -rf "$w"
}

auu_recipes() { # -> the state line, then each recipe's line (the header gives the form)
  _auu_state versions
  _auu_recipes names
  [ "$AUU_WORD" != current ] || [ "$AUU_WAITING" = 0 ] || AUU_WORD=ready
  printf '%s\t%s\t%s\t%s\n' "$AUU_WORD" "$AUU_INSTALLED" "$AUU_OFFERED" "$AUU_DETAIL"
  [ "${#AUU_RECIPES[@]}" = 0 ] || printf '%s\n' "${AUU_RECIPES[@]}"
}

# The fetched notes of every version newer than the stamp's, cleaned (the header gives the rules)
auu_notes() {
  local PATH=/usr/bin:/bin:/usr/sbin:/sbin low a=-1 b=0 c=0 f="$AU_UPDATE_DIR/notes.md" c1
  [ -f "$f" ] && [ ! -L "$f" ] || return 0
  _auu_state versions; low=$AUU_INSTALLED
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

# For the check job's notification (TODO(U7)): prints the offered version when the versions alone give ready (a
# notification is sent for a new version, D3.3: a build waiting for a reason on the Mac itself is not one) and
# `noted` does not yet hold that version with the count 2, and then writes `noted` with the count raised. Otherwise
# it prints nothing; a `noted` of a newer format is left as it is, and nothing is printed.
auu_noted() {
  local n=1 rc=0
  _auu_state versions
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
    --recipes) auu_recipes ;;
    *) echo "usage: updates.sh [--refresh [--now] | --notes | --noted | --open | --version-of <file> | --recipes]" >&2; exit 2 ;;
  esac
  exit 0
fi
