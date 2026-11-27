# Sourced by the rule file's tests (U1: T1, T3, T4, T5, T14, T41, T42; U3: T1, T3, T4, T14, T42's registry halves,
# T11, T22, T23, T40, T44) after lib.sh and helpers.sh. common/updates.sh ($ROOT's, the mutant's copy under
# --mutants) is run as the check job runs it, with its folder at a scratch place and the stub curl (AU_CURL, which
# stub_env sets) answering release's changelog and registry:
#   update_env          stub_env; W, a work folder, which is also the data root of the folder U (the rule file's
#                       folder, mode 0700); NOW, the clock; the disk figures by their test variables (C1)
#   fresh               U emptied, builds/, store/ and engines/ removed, and the stub curl's routes and requests cleared
#   stamp LINE VERSION [COMMIT [TIME]]   _update/scripts in the form the driver writes (B3 step 15)
#   offer VERSION [TIME], tried TIME     those records in their form (common/updates.sh's header)
#   changelog OUT VERSION...             a changelog: Unreleased, then one section per version, in that order
#   answer STATUS [BODY [HEADER...]]     the stub curl's route for release's changelog (CHANGELOG); and, unless the
#                       test routed the registry itself, one for release's registry (REGISTRY) answering 200 with
#                       good-v0.1.0.tsv given the changelog's newest version (v0.0.0 when it names none)
#   answer_reg STATUS [BODY [HEADER...]] the stub curl's route for release's registry, in place of any before it
#   reg_as VERSION OUT [SRC]             SRC (default good-v0.1.0.tsv) with its version line saying VERSION
#   upd ARG...          bash updates.sh ARG... with AU_UPDATE_DIR=$U and AU_UPDATE_NOW=${AT:-$NOW}
#   fn FUNCTION ARG...  a function of the file, sourced in a subshell with AU_UPDATE_DIR=$U
#   asks                how many requests the stub curl has had
#   sum FILE            its sha256, or none
#   leftovers           how many temporary files the rule file left in U
# U3's records, in the data root W, built directly (the household recipe of the registry fixtures, HH):
#   mac_put GPU-MIB MEMORY-BYTES         builds/mac in capability-lib.js's form
#   served RECIPE BUILD PEOPLE CONTEXT [REGISTRY]   builds/RECIPE/serving: the build's, its engine's and its
#                       model's lines from REGISTRY (default good-v0.1.0.tsv), byte for byte, and a launch line
#   entry RECIPE kept|failed BUILD [DATE [REGISTRY]]  an entry of kept/ or failed/, named by DATE and the build
#   hold_put RECIPE BUILD...             builds/RECIPE/hold
#   known VERSION [REGISTRY]             stamp, offer and _update/registry, all of VERSION, as a check leaves them
#   line_of RECIPE [OUTPUT]              that recipe's line from --recipes (or from OUTPUT)
#   rfield RECIPE N [OUTPUT]             field N of it
S="$ROOT/common/updates.sh"
CHANGELOG=https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/CHANGELOG.md
REGISTRY=https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/registry.tsv
REGF=$TESTS/fixtures/registry
HEX=0123456789abcdef0123456789abcdef01234567
NOW=1800000000
TAB=$'\t'
HH=rmmsi4vdvxsr4      # the household recipe of the registry fixtures
B1=b7275bkg6tizv      # its order 1, Mistral Small 4 (endorsed)
B2=b7adwcqnfap56      # its order 2, Magistral Small (publisher)
GB36=38654705664 GB64=68719476736

update_env() {
  stub_env
  W=$(mktemp -d "${TMPDIR%/}/update.XXXXXX")
  U="$W/u"
  export AU_DISK_FREE_BYTES=500000000000 AU_DISK_TOTAL_BYTES=1000000000000
}

fresh() {
  rm -rf "$U" "$W/builds" "$W/store" "$W/engines" "$STUB_CURL_DIR/requests" "$STUB_CURL_DIR"/.count-*
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

reg_as() { # VERSION OUT [SRC]
  awk -F'\t' -v OFS='\t' -v v="$1" 'NR == 1 { $3 = v } { print }' "${3:-$REGF/good-v0.1.0.tsv}" > "$2"
}

answer() { # STATUS [BODY [HEADER...]]
  local st=$1 body=${2:--} v
  shift; [ $# -eq 0 ] || shift
  curl_route GET "$CHANGELOG" "$st" "$body" "$@"
  grep -qF "$REGISTRY" "$STUB_CURL_DIR/routes" && return 0
  v=
  [ "$body" = - ] || v=$(sed -n -E 's/^## (v[0-9]+\.[0-9]+\.[0-9]+) \(.*/\1/p' "$body" 2>/dev/null | head -n 1)
  reg_as "${v:-v0.0.0}" "$W/reg-${v:-v0.0.0}.tsv"
  curl_route GET "$REGISTRY" 200 "$W/reg-${v:-v0.0.0}.tsv"
}

answer_reg() { # STATUS [BODY [HEADER...]]
  local st=$1 body=${2:--}
  shift; [ $# -eq 0 ] || shift
  awk -F'\t' -v u="$REGISTRY" '$2 != u' "$STUB_CURL_DIR/routes" > "$STUB_CURL_DIR/routes.new" && mv "$STUB_CURL_DIR/routes.new" "$STUB_CURL_DIR/routes"
  curl_route GET "$REGISTRY" "$st" "$body" "$@"
}

upd() { env AU_UPDATE_DIR="$U" AU_UPDATE_NOW="${AT:-$NOW}" /bin/bash "$S" "$@"; }

fn() { ( AU_UPDATE_DIR=$U; . "$S"; "$@" ); }

asks() { ls "$STUB_CURL_DIR/requests" 2>/dev/null | wc -l | tr -d ' '; }

sum() { if [ -e "$1" ]; then shasum -a 256 < "$1" | cut -c1-64; else echo none; fi; }

leftovers() { ls -A "$U" | grep -c '^\.' ; }

mac_put() {
  mkdir -p "$W/builds"
  printf 'auster-record 1\ngpu-mib\t%s\nmemory-bytes\t%s\nmacos\t27.2.1\nmeasured\t2026-11-26T15:04:05Z\nrouter\t0a:1b:2c:3d:4e:5f\nkeep-awake\tno\n' \
    "$1" "$2" > "$W/builds/mac"
}

_descriptor() { # BUILD PEOPLE CONTEXT REGISTRY -> a descriptor (A5) on standard output
  local b e m
  b=$(grep "^build	$1	" "$4"); e=$(printf '%s\n' "$b" | cut -f3); m=$(printf '%s\n' "$b" | cut -f4)
  printf 'auster-descriptor 1\n%s\n%s\n%s\n' "$b" "$(grep "^engine	$e	" "$4")" "$(grep "^model	$m	" "$4")"
  printf 'launch\t%s\t%s\t8484\t%s\t36.9\n' "$2" "$3" 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
}

served() {
  mkdir -p "$W/builds/$1/kept" "$W/builds/$1/failed"
  _descriptor "$2" "$3" "$4" "${5:-$REGF/good-v0.1.0.tsv}" > "$W/builds/$1/serving"
}

entry() { # RECIPE kept|failed BUILD [DATE [REGISTRY]]
  mkdir -p "$W/builds/$1/$2"
  _descriptor "$3" 4 32768 "${5:-$REGF/good-v0.1.0.tsv}" > "$W/builds/$1/$2/${4:-2026-11-20T10:00:00Z}-$3"
}

hold_put() { local r=$1; shift; mkdir -p "$W/builds/$r"; printf 'auster-record 1\n' > "$W/builds/$r/hold"; printf '%s\n' "$@" >> "$W/builds/$r/hold"; }

known() { # VERSION [REGISTRY]: stamp, offer and the registry, all of VERSION
  stamp release "$1"; offer "$1"; reg_as "$1" "$U/registry" "${2:-$REGF/good-v0.1.0.tsv}"
}

line_of() { # RECIPE [OUTPUT]
  if [ $# -ge 2 ]; then printf '%s\n' "$2"; else upd --recipes; fi | awk -F'\t' -v r="$1" '$1 == "recipe" && $2 == r'
}

rfield() { line_of "$1" ${3+"$3"} | cut -f"$2"; }
