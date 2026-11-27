# Sourced by test files after lib.sh (docs/plans/v0.1.md, D6): the stubs' set-up and the fixtures that
# are made at run time. The stubs themselves are described at the top of each file in tests/stubs/.

stub_env() { # puts the stubs first on PATH, with fresh state folders; stops stub engines on exit. AU_CURL
  # names the stub curl, so that common/updates.sh, which runs the system's curl by its full path, never
  # reaches the network from a test (the check job runs the deployed copy with the test's environment)
  case ":$PATH:" in ":$TESTS/stubs:"*) ;; *) PATH="$TESTS/stubs:$PATH" ;; esac
  STUB_DIR=$(mktemp -d "${TMPDIR%/}/stubs.XXXXXX")
  export PATH STUB_DIR
  export STUB_LOG="$STUB_DIR/log" STUB_CURL_DIR="$STUB_DIR/curl" STUB_ENGINE_DIR="$STUB_DIR/engine"
  export STUB_LAUNCHCTL_DIR="$STUB_DIR/launchctl" STUB_PS_TABLE="$STUB_DIR/ps-table"
  export STUB_NOTIFY_LOG="$STUB_DIR/notify" STUB_CMD_DIR="$STUB_DIR/cmd"
  export AU_CURL="$TESTS/stubs/curl" AU_OPEN="$TESTS/stubs/open"   # and AU_OPEN, so that no test opens Terminal (U4)
  mkdir -p "$STUB_CURL_DIR" "$STUB_ENGINE_DIR" "$STUB_LAUNCHCTL_DIR" "$STUB_CMD_DIR"
  : > "$STUB_LOG"; : > "$STUB_CURL_DIR/routes"; : > "$STUB_PS_TABLE"; : > "$STUB_NOTIFY_LOG"
  trap stub_cleanup EXIT
}

stub_cleanup() { # stops every stub engine still running (the test's EXIT trap)
  local f
  for f in "${STUB_ENGINE_DIR:-/nonexistent}"/pids/*; do
    [ -f "$f" ] && kill "${f##*/}" 2>/dev/null
  done
  return 0
}

curl_route() { # METHOD URL STATUS BODYFILE [HEADER...] -> one line in the stub curl's routes
  local IFS=$'\t'
  printf '%s\n' "$*" >> "$STUB_CURL_DIR/routes"
}

engine_set() { # SELECTOR SETTING VALUE -> one line in the stub engine's config
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$STUB_ENGINE_DIR/config"
}

engine_start() { # engine options... -> starts the stub engine in the background and prints its pid
  # once it has registered its port, decided not to (nolisten), or ended
  local port=8080 a prev= pid sd i
  for a in "$@"; do [ "$prev" = --port ] && port=$a; prev=$a; done
  "$TESTS/stubs/llama-server" "$@" >> "$STUB_ENGINE_DIR/output" 2>&1 &
  pid=$!
  for i in $(seq 100); do
    kill -0 "$pid" 2>/dev/null || break
    grep -qx "pid=$pid" "$STUB_ENGINE_DIR/ports/$port" 2>/dev/null && break
    sd=$(cat "$STUB_ENGINE_DIR/pids/$pid" 2>/dev/null)
    [ -n "$sd" ] && [ "$(cat "$sd/behaviour" 2>/dev/null)" = nolisten ] && break
    sleep 0.05
  done
  echo "$pid"
}

engine_live() { # PORT KEY VALUE -> changes a running stub engine's setting (what the stub curl reads)
  local pf="$STUB_ENGINE_DIR/ports/$1"
  awk -v k="$2" -v v="$3" 'index($0, k "=") == 1 { print k "=" v; next } { print }' "$pf" > "$pf.new" && mv "$pf.new" "$pf"
}

engine_program() { # DIR -> DIR/llama-server, a regular file that runs the stub engine with its state
  # folder and log passed as options, since the engine job starts it with an empty environment
  mkdir -p "$1"
  printf '#!/bin/bash\nexec %q --stub-dir %q --stub-log %q --stub-program "$0" "$@"\n' \
    "$TESTS/stubs/llama-server" "$STUB_ENGINE_DIR" "$STUB_LOG" > "$1/llama-server"
  chmod 755 "$1/llama-server"
}

make_home() { # PARENT [--zprofile-link] [--data-root-link] -> makes and prints a home folder whose
  # path holds a space, an apostrophe and &, with Library and a two-line ~/.zprofile.
  # --zprofile-link: ~/.zprofile is a link to PARENT/zprofile-elsewhere.
  # --data-root-link: the data root (B1) is a link to PARENT/data-root-elsewhere, which holds the
  # data root's marker and a file named sentinel.
  local parent=$1 h; shift
  h="$parent/the home's & more"
  mkdir -p "$h/Library/Application Support" "$h/Library/LaunchAgents"
  local zp=$'# a line the household wrote\nexport EXAMPLE_SETTING=1\n'
  while [ $# -gt 0 ]; do
    case "$1" in
      --zprofile-link) printf '%s' "$zp" > "$parent/zprofile-elsewhere"; ln -s "$parent/zprofile-elsewhere" "$h/.zprofile" ;;
      --data-root-link)
        mkdir -p "$parent/data-root-elsewhere"
        : > "$parent/data-root-elsewhere/.auster-data-root"; echo keep > "$parent/data-root-elsewhere/sentinel"
        ln -s "$parent/data-root-elsewhere" "$h/Library/Application Support/Auster" ;;
      *) echo "make_home: $1?" >&2; return 2 ;;
    esac
    shift
  done
  [ -e "$h/.zprofile" ] || [ -L "$h/.zprofile" ] || printf '%s' "$zp" > "$h/.zprofile"
  printf '%s\n' "$h"
}

snapshot() { # DIR -> every path under it, sorted, one a line: mode (octal, with the file type), then
  # the sha256 (- for a folder, "-> target" for a link, "unreadable"), then the path from DIR.
  # Paths with a newline in their name are not supported.
  local root=$1 p h list=()
  while IFS= read -r -d '' p; do list+=("$p"); done < <(cd "$root" && find . -print0)
  (
    cd "$root" || exit 1
    for p in "${list[@]}"; do
      if [ -L "$p" ]; then h="-> $(readlink "$p")"
      elif [ -f "$p" ]; then h=$(shasum -a 256 < "$p" 2>/dev/null | cut -c1-64); [ -n "$h" ] || h=unreadable
      else h=-; fi
      printf '%s\t%s\t%s\n' "$(stat -f %p "$p")" "$h" "${p#./}"
    done
  ) | LC_ALL=C sort -t $'\t' -k3
}

# The model stand-ins: name, size, sha256. Their content is made below; the hashes are fixed here so
# that a registry fixture can name them, and model_standins refuses if what it made differs.
STANDINS="standin-a.gguf	3400	ab0f65eb5bf514fb809bbd19bffccfb65766c77e480d1651b6f35cc3c17135d7
standin-b.gguf	2040	e5cb32f318ff6f9b2ff9ae5762be574abe6c3bccfedfe76a15d51ecdfac86590
standin-a-wrong.gguf	3400	07081b3b4c85550947564d52caeb8561eadba7105e9c10192b731580e69674a3
standin-a-short.gguf	1700	12c3529cb3ab88892f6dfb676e10e8b1221ac8c9e018af79c39e388233df9b2a"

model_standins() { # DIR -> makes the stand-ins in DIR and prints their names, sizes and sha256s:
  # two models, one of A's size with other content (its last byte changed), and A cut short (half)
  local d=$1 i name size sha got
  mkdir -p "$d"
  for i in $(seq 100); do printf 'Auster model stand-in A, line %03d\n' "$i"; done > "$d/standin-a.gguf"
  for i in $(seq 60); do printf 'Auster model stand-in B, line %03d\n' "$i"; done > "$d/standin-b.gguf"
  { head -c 3399 "$d/standin-a.gguf"; printf 'X'; } > "$d/standin-a-wrong.gguf"
  head -c 1700 "$d/standin-a.gguf" > "$d/standin-a-short.gguf"
  while IFS=$'\t' read -r name size sha; do
    got=$(shasum -a 256 < "$d/$name" | cut -c1-64)
    if [ "$(stat -f %z "$d/$name")" != "$size" ] || [ "$got" != "$sha" ]; then
      echo "model_standins: $name came out as $(stat -f %z "$d/$name") bytes, $got" >&2; return 1
    fi
    printf '%s\t%s\t%s\n' "$name" "$size" "$sha"
  done <<< "$STANDINS"
}

stale_lock() { # FILE [PID [BOOT [START]]] -> a lock in the form D3.1 gives `updating`, by default left
  # by a process that is gone, in this boot (sysctl -n kern.bootsessionuuid), started at 08:00
  local pid=${2:-} boot=${3:-} start=${4:-Thu Nov 26 08:00:00 2026}
  if [ -z "$pid" ]; then /usr/bin/true & pid=$!; wait "$pid"; fi
  [ -n "$boot" ] || boot=$(sysctl -n kern.bootsessionuuid)
  printf 'auster-record 1\t%s\t%s\t%s\n' "$pid" "$boot" "$start" > "$1"
}

registry_sized() { # SRC BYTES OUT -> SRC with comment lines added (each at most 1,000 bytes) so that
  # OUT is exactly BYTES long: the 512 KiB, 512 KiB + 1 and over-1-MiB registries
  local need full last fill i
  need=$(( $2 - $(stat -f %z "$1") ))
  [ "$need" -ge 2 ] || { echo "registry_sized: $1 is already too large" >&2; return 1; }
  cp "$1" "$3"
  fill=$(printf '%0999d' 0 | tr 0 x)
  full=$(( (need - 2) / 1001 )); last=$(( need - full * 1001 ))
  for ((i = 0; i < full; i++)); do printf "#%s\n" "$fill"; done >> "$3"
  if [ "$last" -gt 1001 ]; then printf "#%s\n" "${fill:0:499}" >> "$3"; last=$((last - 501)); fi
  printf '#%s\n' "${fill:0:$((last - 2))}" >> "$3"
}

records_fixture() { # two|three DEST -> the records of two or three recipes (tests/fixtures/records/README) copied to
  # DEST, a data root's records, with the modes Auster gives them: every folder 0700 (and each recipe its kept/ and
  # failed/, which git does not keep when empty), every file 0600, every file in store/ 0444
  local src="$TESTS/fixtures/records/$1" r
  [ -d "$src" ] && mkdir -p "$2" && cp -R "$src/." "$2/" || return 1
  for r in "$2"/builds/r*; do mkdir -p "$r/kept" "$r/failed"; done
  find "$2" -type d -exec chmod 700 {} + && find "$2" -type f -exec chmod 600 {} + && chmod 444 "$2"/store/*
}
