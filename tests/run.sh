#!/bin/bash
# Runs Auster's tests (docs/plans/v0.1.md, D6) under /bin/bash 3.2 with an empty environment and a PATH
# of what macOS ships, less the tools macOS 14 lacks or a household Mac may not have (T98).
#
#   tests/run.sh                  every test file
#   tests/run.sh 47 98            the test files for T47 and T98
#   tests/run.sh --mutants [47]   each mutant (tests/mutants/T<n><letter>) applied to a copy of the
#                                 source; its test must turn red. T98's mutants run the whole suite.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
DENY="timeout jq git brew base32"   # and every python3*
WORK=$(mktemp -d "${TMPDIR:-/tmp}/auster-tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

BARE="$WORK/bin"; mkdir "$BARE"
for d in /usr/bin /bin /usr/sbin /sbin; do
  for f in "$d"/*; do
    n=${f##*/}
    case " $DENY " in *" $n "*) continue ;; esac
    case "$n" in python3*) continue ;; esac
    [ -e "$BARE/$n" ] || ln -s "$f" "$BARE/$n"
  done
done

run_file() { # root, test file -> exit code of the test
  mkdir -p "$WORK/home"
  env -i HOME="$WORK/home" TMPDIR="$WORK/" PATH="$BARE" ROOT="$1" TESTS="$1/tests" \
    /bin/bash "$2"
}

files_for() { # root, numbers... -> test files
  local r=$1; shift
  if [ $# -eq 0 ]; then ls "$r"/tests/t[0-9]*.sh; return; fi
  for n in "$@"; do ls "$r"/tests/t"$n"-*.sh 2>/dev/null; done
}

if [ "${1:-}" = --mutants ]; then
  shift; red=0; other=0
  for m in "$ROOT"/tests/mutants/T*; do
    id=${m##*/}; num=${id#T}; num=${num%[a-z]}
    if [ $# -gt 0 ]; then case " $* " in *" $num "*) ;; *) continue ;; esac; fi
    file=$(sed -n 's/^# file: //p' "$m" | head -1)
    copy="$WORK/m-$id"; mkdir "$copy"
    for p in tools tests common assets install.sh registry.tsv; do
      [ -e "$ROOT/$p" ] && cp -R "$ROOT/$p" "$copy/"
    done
    sed -f "$m" "$copy/$file" > "$copy/$file.new" && cat "$copy/$file.new" > "$copy/$file" && rm "$copy/$file.new"
    if cmp -s "$ROOT/$file" "$copy/$file"; then echo "REFUSED  $id: it no longer applies to $file"; other=$((other + 1)); continue; fi
    if [ "$num" = 98 ]; then tf=$(files_for "$copy"); else tf=$(files_for "$copy" "$num"); fi
    rc=0; for t in $tf; do run_file "$copy" "$t" > "$copy/out" 2>&1 || rc=1; done
    if [ "$rc" -ne 0 ]; then echo "red      $id ($(sed -n 2p "$m" | sed 's/^# //'))"; red=$((red + 1))
    else echo "SURVIVED $id ($(sed -n 2p "$m" | sed 's/^# //'))"; other=$((other + 1)); fi
  done
  echo "mutants: $red red, $other not"
  [ "$other" -eq 0 ]; exit $?
fi

fails=0
for t in $(files_for "$ROOT" "$@"); do
  echo "== ${t##*/}"
  run_file "$ROOT" "$t" || fails=$((fails + 1))
done
echo "test files failed: $fails"
[ "$fails" -eq 0 ]
