# Sourced by every stub in tests/stubs/ (docs/plans/v0.1.md, D6). Not a test helper: test files use
# tests/helpers.sh. Everything here runs under /bin/bash 3.2 with the bare PATH of tests/run.sh.
#
# Common settings, read by every command stub that sources this file:
#   STUB_LOG      if set, each call appends one line: the stub's name and its arguments, joined by
#                 single spaces, with a newline in an argument written as \n. Standard input, when a
#                 stub reads it, is appended as one more line: the name, "<stdin>", and what it read.
#   STUB_CMD_DIR  if set and STUB_CMD_DIR/<name> exists, a line there whose first field equals the
#                 arguments joined by single spaces wins over the stub's own answer. Each line is
#                 ARGS<TAB>EXIT<TAB>OUTPUT: OUTPUT is printed with \n, \t and \\ read as escapes and
#                 a newline after it, or, as @file, that file's content as it is. It lets a test give
#                 any output the stub's own settings do not cover.
#
# A stub that has not been told how to answer exits STUB_UNTOLD (99) with a message on stderr: no real
# command exits 99, so a test that forgot a setting fails where it can be seen.

STUB_UNTOLD=99
STUB_TESTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
STUB_BIN="$STUB_TESTS/stubs"
STUB_NAME=${0##*/}

stub_escape() { # text -> one line, with \ written as \\, newline as \n, tab as \t
  local s=$1
  s=${s//\\/\\\\}; s=${s//$'\n'/\\n}; s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

stub_unescape() { # the reverse of stub_escape, for values a test writes into a settings file
  local s=$1 out= c
  while [ -n "$s" ]; do
    c=${s:0:1}
    if [ "$c" = '\' ] && [ ${#s} -ge 2 ]; then
      case "${s:1:1}" in n) out+=$'\n' ;; t) out+=$'\t' ;; r) out+=$'\r' ;; *) out+=${s:1:1} ;; esac
      s=${s:2}
    else
      out+=$c; s=${s:1}
    fi
  done
  printf '%s' "$out"
}

stub_log() { # arguments of this call -> one line in STUB_LOG
  [ -n "${STUB_LOG:-}" ] || return 0
  local line=$STUB_NAME a
  for a in "$@"; do line+=" $(stub_escape "$a")"; done
  printf '%s\n' "$line" >> "$STUB_LOG"
}

stub_log_input() { # a file holding what the stub read from its standard input
  [ -n "${STUB_LOG:-}" ] || return 0
  printf '%s <stdin> %s\n' "$STUB_NAME" "$(stub_escape "$(cat "$1")")" >> "$STUB_LOG"
}

stub_untold() { # message: the stub was not told how to answer this call
  printf 'stub %s: %s\n' "$STUB_NAME" "$1" >&2
  exit "$STUB_UNTOLD"
}

stub_split() { # line -> array F, split on single tabs, empty fields kept (read with IFS would merge them)
  local rest=$1
  F=()
  while :; do
    case "$rest" in
      *$'\t'*) F+=("${rest%%$'\t'*}"); rest=${rest#*$'\t'} ;;
      *) F+=("$rest"); break ;;
    esac
  done
}

stub_override() { # this call's arguments -> prints the test's answer and returns its exit code, or 255
  [ -n "${STUB_CMD_DIR:-}" ] && [ -f "$STUB_CMD_DIR/$STUB_NAME" ] || return 255
  local want="$*" line
  while IFS= read -r line || [ -n "$line" ]; do
    stub_split "$line"
    [ "${#F[@]}" -ge 2 ] && [ "${F[0]}" = "$want" ] || continue
    case "${F[2]:-}" in
      '') ;;
      @*) cat "${F[2]#@}" ;;
      *) stub_unescape "${F[2]}"; printf '\n' ;;
    esac
    return "${F[1]}"
  done < "$STUB_CMD_DIR/$STUB_NAME"
  return 255
}

stub_begin() { # every command stub starts here: log the call, then let STUB_CMD_DIR answer if it can
  stub_log "$@"
  local rc
  stub_override "$@"; rc=$?
  [ "$rc" -eq 255 ] || exit "$rc"
}

stub_new_dir() { # parent -> creates parent/0001, parent/0002, ... atomically, prints the one it made
  local n=1 d
  mkdir -p "$1"
  while :; do
    d=$(printf '%s/%04d' "$1" "$n")
    mkdir "$d" 2>/dev/null && { printf '%s\n' "$d"; return 0; }
    n=$((n + 1))
  done
}

stub_alive() { # pid -> 0 if a process with that number is running
  case "$1" in ''|*[!0-9]*) return 1 ;; esac
  kill -0 "$1" 2>/dev/null
}

# The home network every network stub describes, so that route, ipconfig, arp, networksetup, scutil
# and nc agree. An empty value (set but empty) means "none": STUB_NET_IF= is a Mac with no default
# route, STUB_NET_ROUTER_MAC= a router arp has no entry for. Addresses are RFC 1918 examples; the
# hardware addresses are from RFC 7042's documentation range.
STUB_NET_IF=${STUB_NET_IF-en0}
STUB_NET_ADDR=${STUB_NET_ADDR-10.0.0.5}
STUB_NET_GATEWAY=${STUB_NET_GATEWAY-10.0.0.1}
STUB_NET_ROUTER_MAC=${STUB_NET_ROUTER_MAC-0:0:5e:0:53:1}
STUB_NET_PORTS=${STUB_NET_PORTS-Wi-Fi=en0|Thunderbolt Bridge=bridge0|Thunderbolt 1=en1|Thunderbolt 2=en2}
