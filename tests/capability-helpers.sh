# Sourced by the capability tests (T88 to T93, T102) after lib.sh: how they run section C's command line
# (common/capability.js), and the fixtures' ids and figures. The fixtures are described in
# tests/fixtures/capability/README.
CAPF=$TESTS/fixtures/capability
HREG=$CAPF/household.tsv
HH=rmmsi4vdvxsr4      # the household recipe
B1=b7275bkg6tizv      # order 1, Mistral Small 4 (A6)
B2=b7adwcqnfap56      # order 2, Magistral Small 2509 (A6)
T=$'\t'
MIB=1048576
GIB=1073741824
GB16=17179869184 GB36=38654705664 GB64=68719476736 GB128=137438953472   # AU_RAM_BYTES of four Macs

cap() { # REGISTRY RECIPE [OPTION...] -> what capability.js prints, then a line `exit<TAB><code>`
  local rc
  osascript -l JavaScript "$ROOT/common/capability.js" "$@"; rc=$?
  printf 'exit\t%s\n' "$rc"
}

on() { # RAM-BYTES GPU-MIB REGISTRY RECIPE [OPTION...] -> cap, with the Mac's memory and GPU limit given
  # by their test variables (C1)
  local ram=$1 gpu=$2
  shift 2
  AU_RAM_BYTES=$ram AU_GPU_MIB=$gpu cap "$@"
}

kind() { # OUTPUT KIND -> the output's lines of that kind
  printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k'
}

pick() { # OUTPUT -> "build people context" from the choice line, or "refused <reason> [<detail>]", then
  # the exit code
  local c
  c=$(kind "$1" choice | cut -f2-4)
  [ -n "$c" ] || c=$(kind "$1" refused)
  printf '%s %s\n' "$(printf '%s' "$c" | tr '\t' ' ')" "$(kind "$1" exit | cut -f2)"
}

context_of() { # OUTPUT -> the context of the choice line, or - when refused
  local c
  c=$(kind "$1" choice | cut -f4)
  printf '%s\n' "${c:--}"
}

mac_record() { # FILE GPU-MIB MEMORY-BYTES -> a `mac` record in the form capability-lib.js gives
  printf 'auster-record 1\ngpu-mib\t%s\nmemory-bytes\t%s\nmacos\t27.2.1\nmeasured\t2026-11-26T15:04:05Z\nrouter\t0a:1b:2c:3d:4e:5f\nkeep-awake\tyes\n' \
    "$2" "$3" > "$1"
}
