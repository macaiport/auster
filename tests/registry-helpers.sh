# Sourced by the registry tests (T22, T36, T44, T48 to T55) after lib.sh: the ways they run the reader
# (common/registry.js and common/registry-lib.js) and the gate (tools/check-registry), and the fixtures'
# ids. The fixtures are described in tests/fixtures/registry/README.
REG=$TESTS/fixtures/registry
HH=rmmsi4vdvxsr4      # the household recipe
B1=b7275bkg6tizv      # order 1, Mistral Small 4 (endorsed)
B2=b7adwcqnfap56      # order 2, Magistral Small (publisher)
B3=bhoe4j755eetl      # the build in no order line (judgements.tsv)
T=$'\t'

reader() { osascript -l JavaScript "$ROOT/common/registry.js" "$@"; }   # REGISTRY [RECIPE]
gate() { "$ROOT/tools/check-registry" "$@"; }

each() { # RECIPE-or-- FILE... -> for each file `file<TAB>path`, what registry.js prints, `exit<TAB>code`
  osascript -l JavaScript "$TESTS/registry-each.js" "$ROOT" "$@"
}

section() { # OUTPUT FILE -> the lines `each` printed for FILE
  printf '%s\n' "$1" | awk -F'\t' -v f="$2" '$1 == "file" { on = ($2 == f); next } on'
}

kind() { # OUTPUT KIND -> the output's lines of that kind
  printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k'
}

passed_lines() { # OUTPUT -> the numbers of the lines passed over, comma-separated
  kind "$1" passed | cut -f2 | paste -sd, -
}

own_passed() { # OUTPUT -> the lines passed over for what they hold, not for an id another line lost
  kind "$1" passed | awk -F'\t' 'index($4, "names ") != 1 { print $2 }' | paste -sd, -
}

taken() { # OUTPUT -> the build the recipe takes as far as the registry knows: the first build line `ok`
  kind "$1" build | awk -F'\t' '$3 == "ok" { print $5; exit }'
}

state() { # OUTPUT -> the recipe line's state
  kind "$1" recipe | cut -f3 | head -1
}

rec() { # FIELD... -> one registry line, the fields joined by tabs
  local IFS=$'\t'
  printf '%s\n' "$*"
}

extend() { # SRC OUT LINE... -> OUT is SRC with the lines added at the end
  local out=$2
  cp "$1" "$out"
  shift 2
  printf '%s\n' "$@" >> "$out"
}

jxa() { # BODY ARG... -> runs BODY as the body of run(argv), with registry-lib.js loaded and argv holding
  # the ARGs; prints what BODY returns
  local body=$1
  shift
  osascript -l JavaScript -e "ObjC.import('Foundation');
function auLoad(p) { return ObjC.unwrap(\$.NSString.stringWithContentsOfFileEncodingError(p, \$.NSUTF8StringEncoding, null)); }
function run(argv) { eval(auLoad(argv.shift() + '/common/registry-lib.js'));
$body
}" "$ROOT" "$@"
}
