#!/bin/bash
# The driver (docs/plans/v0.1.md, B3): one procedure for installing and updating, run by install.sh from
# the tree of the commit it fixed, never from anywhere else (install.sh's header gives the contract):
#
#   /bin/bash <tree>/common/driver.sh install|check <recipe id> --commit C --line release|tag --version V [--withdrawals FILE]
#   /bin/bash <tree>/common/driver.sh update|remove --commit C --line release --version V
#   /bin/bash <tree>/common/driver.sh people <n> --commit C --line release --version V   (U5: `auster people <n>`)
#
# It lives in common/ beside the programs it runs from the same tree (registry.js, capability.js,
# recipe-test.js, and tools/mint-id one folder up), and loads common/auster, the `auster` command, for the
# functions the two share (the data root, the lock, the questions, the jobs, the server check).
#
# Built by V5 (2026-11-26): a first install, B3 steps 1 to 15. Step 1 is install.sh's, which runs before
# anything is fetched; step 2 is install.sh's too. V6 built the jobs' programs, common/auster-engine and
# common/auster-check, which step 3 copies with the check job's section C into jobs/. V7 added the question
# about ~/.zprofile (B6), asked with the question; the keys made by common/auster's functions, which
# `auster key add` uses too (step 11, with tools/mint-id copied to jobs/mint-id at step 3); and the QR code
# of step 14. U1 (2026-11-27): step 15 copies common/updates.sh, the rule file, to _update/updates.sh
# before the stamp (D3.1, T43). U2 (2026-11-27): the records written here are read back by common/auster's
# readers (its header lists them); step 3 refuses when any record of D3.1 is of a newer format, and when any folder
# in the data root is not this account's alone; the stamp is read by the one-line reader; builds/local-name is
# written with builds/mac (T6, T33, T36, T54, T55, T95, T116). U3 (2026-11-27): step 3 also copies registry.js into
# jobs/, which the rule file runs for each recipe's line; and au_bytes and its kin moved to common/auster.
# U4 (2026-11-27): `update`, and a second paste on a Mac that serves the recipe, run the update (D3.6, below "the
# update"): step 3 takes the lock and writes no program, step 4 measures with the engine in engines/, each recipe is
# judged and printed OK, held, passed over or withdrawn, and a change of build or setting goes to the question; with
# nothing to change, steps 13 to 15 (T5, T7, T26, T35, T38, T44, T46, T54, T65, T84, T91). U5, its first half
# (2026-11-27): what follows a yes when no build changes (below "the update"): Auster's own programs first, with their
# trial run, jobs/previous/ and their server check (B3 step 6, BD18); `mac` once they pass; a change of setting, switched
# as D3.6 says (kept/ first, then serving by rename with a speed of 0, the engine restarted, the server check, exit 4
# naming `auster rollback`); an update that finds jobs/previous/ checks the server before anything else; and `people`,
# the same switch for `auster people <n>` (T94, T100, T107, T109, T111, T112). What later steps complete is marked TODO:
#   U5  a yes to a change of build: the publisher's HEAD, the download, the isolated test, side by side or in turn,
#       paused, failed/, and the switch to the new build (D3.6 steps 1 and 3 to 5).
#
# jobs/previous/ (B3 step 6): the programs in use before an update changed them, each of AU_PROGRAMS under the last part
# of its path in the data root (auster, auster-engine, auster-check, registry-lib.js, capability-lib.js, capability.js,
# registry.js, mint-id) with its mode; a folder of mode 0700, made whole under another name and renamed. It exists from
# just before the new programs are renamed into place until a server check passes (au_server_check deletes it), and
# `auster rollback` (U6) puts them back from it.
#
# Exit codes (B3): 0 done; 1 refused or answered no, and nothing of this run is left; 2 usage; 3 not
# everything was updated (D3.6: a recipe passed over; a new bin/auster that does not answer `status`; and, until U5's
# second half, a yes to a change of build); 4 the server is down; 5 stopped after writing: what is left is listed, and
# `auster remove` removes it. Before the yes every stop is 1 and removes what this run created; after it every stop but
# 4 is 5 and keeps what was written, so that pasting the line again goes on from there.
#
# Test variables: those of section C (AU_GPU_MIB, AU_RAM_BYTES, AU_DISK_FREE_BYTES, AU_DISK_TOTAL_BYTES,
# which common/capability.js reads), and common/auster's: AU_TTY, the file a test answers the questions in;
# AU_SCREEN, the file the QR code is drawn on; AU_SERVER_CHECK_SECS, the server check's limit.
set -u
export LC_ALL=C
AU_TREE=$(cd "$(dirname "$0")/.." && pwd -P) || exit 1
. "$AU_TREE/common/auster"
AU_MINT="$AU_TREE/tools/mint-id"               # A2: ids are minted by the tree's program

AU_ENGINE_HOST=https://github.com/ggml-org/llama.cpp/releases/download
AU_MODEL_HOST=https://huggingface.co
AU_ENGINE_PATH=/usr/bin:/bin:/usr/sbin:/sbin   # B4: the only variable the engine is given
AU_PORT_FIRST=8484                             # B4: the port, chosen at install by a connection test
AU_TEST_PORT_FIRST=18484                       # B3 step 10: the candidate's free port on 127.0.0.1
AU_RE_COMMIT='^[0-9a-f]{40}$'
AU_RE_ENTRY='^[A-Za-z0-9._+@-]+(/[A-Za-z0-9._+@-]+)*/?$'

AU_AWAKE=no AU_DEVICE= AU_LOCKED=0 AU_ROOT_NEW=0 AU_MADE_ROOT=0 AU_CANDIDATE= AU_CREATED=()
AU_FETCH_SECS=0 AU_FETCH_BYTES=0 AU_WITHDRAWALS=
AU_PROGRAMS_CHANGE=0 AU_PROGRAMS_DONE=0 AU_MAC_DONE=0 AU_CHANGED=0 AU_JGPUL= AU_JGPUFROM=

au_usage() {
  { au_say "usage: driver.sh install|check <recipe id> --commit C --line release|tag --version V [--withdrawals FILE]"
    au_say "       driver.sh update|remove --commit C --line release --version V"
    au_say "       driver.sh people <n> --commit C --line release --version V"; } >&2
  exit 2
}

# --- how a run ends -----------------------------------------------------------------------------------

au_undo() { # -> before the yes: whatever this run created is removed (B3 step 6)
  local i p
  au_candidate_stop
  if [ "$AU_MADE_ROOT" = 1 ]; then
    au_lock_release
    if [ ! -L "$AU_DATA" ] && [ -f "$AU_DATA/$AU_ROOT_MARKER" ]; then rm -rf "$AU_DATA"; fi
    AU_MADE_ROOT=0
    return 0
  fi
  for ((i = ${#AU_CREATED[@]} - 1; i >= 0; i--)); do
    p=${AU_CREATED[$i]}
    case "$p" in "$AU_DATA"/*) rm -rf "$p" ;; esac
  done
  AU_CREATED=()
}

au_refuse() { # SENTENCE... -> exit 1, leaving nothing of this run
  local s
  for s in "$@"; do au_say "$s"; done
  au_undo
  exit 1
}

au_stop() { # SENTENCE... -> exit 5: what is left is listed, and how to remove it
  local s
  for s in "$@"; do au_say "$s"; done
  au_candidate_stop
  au_left
  au_say "Paste the installer line again to go on from here, or remove all of it with: \"$AU_DATA/bin/auster\" remove"
  exit 5
}

au_cleanup() {
  au_qr_leave
  au_candidate_stop
  au_lock_release
  rm -rf "$AU_RUN"
}

au_made() { AU_CREATED+=("$1"); }

# --- small things -------------------------------------------------------------------------------------
# (au_commas, au_tenths, au_bytes and au_memory are common/auster's since U3: `auster status` uses them too)

au_duration() { # SECONDS -> roughly how long
  local m=$((($1 + 30) / 60))
  if [ "$1" -lt 60 ]; then printf 'under a minute'
  elif [ "$m" -lt 60 ]; then printf 'about %s minutes' "$m"
  else printf 'about %s h %s min' $((m / 60)) $((m % 60)); fi
}

au_limited() { # SECONDS OUT COMMAND... -> COMMAND's exit code, its output in OUT; stopped after SECONDS
  local secs=$1 out=$2 pid i=0
  shift 2
  "$@" > "$out" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$i" -ge $((secs * 10)) ]; then kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; return 124; fi
    sleep 0.1
    i=$((i + 1))
  done
  wait "$pid"
}

au_fetch() { # URL FILE MAX [resume] -> curl's exit code; AU_CODE the HTTP code. HTTPS only, the person's
  # curl settings ignored, only HTTPS redirects followed, stopped below 10 KB/s for 120 s (B3 step 7)
  local resume=()
  [ "${4:-}" != resume ] || resume=(-C -)
  AU_CODE=$(curl -q --proto =https --proto-redir =https --tlsv1.2 -sS -L --speed-limit 10240 --speed-time 120 \
    --max-filesize "$3" ${resume[@]+"${resume[@]}"} -o "$2" -w '%{http_code}' "$1" 2>/dev/null)
}

# --- the registry (A3), read by common/registry.js ----------------------------------------------------

au_registry() { # -> AU_REG and AU_REGOUT; the recipe's limits; a refusal when it cannot be installed
  local rc l
  AU_REG="$AU_TREE/registry.tsv"
  if [ -n "$AU_WITHDRAWALS" ]; then
    # A named version (B2): its own registry, with the withdrawals of the registry release holds now
    # added for the builds it defines; the reader passes over any that do not apply.
    osascript -l JavaScript "$AU_TREE/common/registry.js" "$AU_WITHDRAWALS" > /dev/null 2>&1 ||
      au_refuse "The withdrawals in the registry the release holds now cannot be read, so nothing was installed."
    AU_REG="$AU_RUN/registry.tsv"
    cp "$AU_TREE/registry.tsv" "$AU_REG" || exit 1
    awk -F'\t' 'NR == FNR { if ($1 == "build") b[$2] = 1; next } $1 == "withdraw" && ($2 in b) { print }' \
      "$AU_TREE/registry.tsv" "$AU_WITHDRAWALS" >> "$AU_REG"
  fi
  AU_REGOUT="$AU_RUN/registry.out"
  osascript -l JavaScript "$AU_TREE/common/registry.js" "$AU_REG" "$AU_RECIPE" > "$AU_REGOUT" 2>/dev/null; rc=$?
  [ "$rc" = 0 ] || au_refuse "The registry of this version of Auster cannot be read, so nothing was installed."
  l=$(awk -F'\t' '$1 == "recipe"' "$AU_REGOUT")
  au_split "$l"
  case "${AU_F[2]:-}" in
    ok) ;;
    absent) au_refuse "This version of Auster has no recipe $AU_RECIPE. Check the line against the guide." ;;
    none) au_refuse "None of the builds of recipe $AU_RECIPE can be installed: the registry withdraws them, or allows none of their sources." ;;
    *) au_refuse "Recipe $AU_RECIPE cannot be read from this version's registry, so nothing was installed." ;;
  esac
  AU_LABEL=${AU_F[4]} AU_DEFAULT_PEOPLE=${AU_F[6]}
}

au_build_field() { # BUILD N -> field N of the build's line in registry.js's report (its header numbers them)
  awk -F'\t' -v b="$1" -v n="$2" '$1 == "build" && $5 == b { print $n; exit }' "$AU_REGOUT"
}

au_raw() { # BUILD KIND -> that registry line, byte for byte (A5), without its newline
  local l
  while IFS= read -r l; do
    case "$l" in "raw$AU_T$1$AU_T$2$AU_T"*) printf '%s' "${l#raw"$AU_T$1$AU_T$2$AU_T"}"; return 0 ;; esac
  done < "$AU_REGOUT"
  return 1
}

au_bd14() { # -> refuses when the Mac already serves another recipe (BD14), before anything is written
  local s r
  for s in "$AU_HOME_DATA"/builds/r*/serving; do
    [ -e "$s" ] || [ -L "$s" ] || continue
    r=${s%/serving}; r=${r##*/}
    [ "$r" = "$AU_RECIPE" ] && continue
    au_refuse "This Mac already serves another recipe ($r), and this version of Auster serves one recipe on a Mac." \
      "Nothing was changed. To serve this one instead, remove Auster first: \"$AU_HOME_DATA/bin/auster\" remove"
  done
}

# --- step 3: the lock and the data root ---------------------------------------------------------------

# Auster's own programs (B3 steps 3 and 6), each `tree path:data-root path:mode`: bin/auster, the two jobs'
# programs, the check job's section C (capability.js and the two files it loads from its own folder, B5 step 4),
# registry.js, which _update/updates.sh runs from jobs/ for each recipe's line (U3, D3.3), and the id minter for
# `auster key add` (B7, A2). An update compares them (au_programs_differ) and changes none before its yes.
AU_PROGRAMS="common/auster:bin/auster:755 common/auster-engine:jobs/auster-engine:644
common/auster-check:jobs/auster-check:644 common/registry-lib.js:jobs/registry-lib.js:644
common/capability-lib.js:jobs/capability-lib.js:644 common/capability.js:jobs/capability.js:644
common/registry.js:jobs/registry.js:644 tools/mint-id:jobs/mint-id:644"

au_step3_root() { # -> the data root (made at a first install), its folders, the lock, and no record of a newer format;
  # the same for an install and an update, which writes no program here (au_step3_programs is a first install's)
  local sub
  au_root_check "$AU_DATA" || exit 1
  if [ "$AU_ROOT_NEW" = 1 ]; then
    mkdir -m 700 "$AU_DATA" || au_refuse "$AU_DATA could not be made."
    AU_MADE_ROOT=1
    : > "$AU_DATA/$AU_ROOT_MARKER"
  fi
  for sub in builds store engines keys logs bin jobs; do
    if [ ! -e "$AU_DATA/$sub" ]; then au_mkdir "$AU_DATA/$sub" || au_refuse "$AU_DATA/$sub could not be made."; au_made "$AU_DATA/$sub"; fi
  done
  au_lock_take || au_refuse
  if au_newer_records; then   # T95: every record of D3.1, the format first, and none rewritten
    au_refuse "${AU_NEWER[0]} was written by a newer version of Auster, so this one leaves it as it is." \
      "Paste the installer line from the guide to update, or remove Auster with: \"$AU_DATA/bin/auster\" remove"
  fi
}

au_step3_programs() { # -> Auster's own programs written into the data root (B3 step 3, a first install)
  local p
  for p in $AU_PROGRAMS; do
    au_program "$AU_TREE/${p%%:*}" "$AU_DATA/$(printf '%s' "$p" | cut -d: -f2)" "${p##*:}"
  done
}

au_programs_differ() { # -> 0 when one of Auster's own programs in this tree is not, byte for byte, the one in the data root
  local p
  for p in $AU_PROGRAMS; do
    cmp -s "$AU_TREE/${p%%:*}" "$AU_DATA/$(printf '%s' "$p" | cut -d: -f2)" || return 0
  done
  return 1
}

au_program() { # SOURCE DEST MODE -> written by rename, unless already equal byte for byte
  [ -e "$2" ] || au_made "$2"
  au_put "$1" "$2" "$3" || au_refuse "$2 could not be written."
}

# --- the engine: unpacked and listed (B3 step 9) -------------------------------------------------------

au_link_inside() { # ROOT LINK -> 0 when LINK's target, resolved from its own folder, stays inside ROOT
  local t rel dir seg segs out=()
  t=$(readlink "$2") || return 1
  case "$t" in ''|/*) return 1 ;; esac
  rel=${2#"$1"/}
  dir=${rel%/*}; [ "$dir" != "$rel" ] || dir=
  IFS=/ read -r -a segs <<< "$dir/$t"
  for seg in ${segs[@]+"${segs[@]}"}; do
    case "$seg" in
      ''|.) ;;
      ..) [ ${#out[@]} -gt 0 ] || return 1; unset "out[$((${#out[@]} - 1))]" ;;
      *) out+=("$seg") ;;
    esac
  done
}

# au_list ROOT, the engine's file list, is common/auster's, which `auster verify` uses too.

au_unpack() { # ARCHIVE DIR -> DIR, made fresh with mode 0700, holds the archive in root/ and its file list
  # in files. Says why and returns 1 for any link that points outside it, any absolute or .. name, any
  # setuid or setgid bit, any entry that is not a file, a folder or a link, and any name Auster does not
  # accept (B3 step 9, T97).
  local a=$1 d=$2 name m rest f ino nl cnt
  rm -rf "$d"
  mkdir -m 700 "$d" && mkdir -m 700 "$d/root" || return 1
  if ! tar -tzf "$a" > "$d/.names" 2>/dev/null || ! tar -tvzf "$a" > "$d/.long" 2>/dev/null ||
     [ "$(wc -l < "$d/.names")" != "$(wc -l < "$d/.long")" ]; then
    au_say "The engine archive cannot be read."; return 1
  fi
  while IFS= read -r name; do
    case "$name" in /*) au_say "The engine archive holds an absolute name, so it is refused."; return 1 ;; esac
    name=${name#./}
    [ -n "$name" ] || continue
    case "/$name/" in */../*|*/./*) au_say "The engine archive holds a name with .. in it, so it is refused."; return 1 ;; esac
    [[ $name =~ $AU_RE_ENTRY ]] || { au_say "The engine archive holds a name Auster does not accept, so it is refused."; return 1; }
  done < "$d/.names"
  while read -r m rest; do
    case "${m:0:1}" in -|d|l|h) ;; *) au_say "The engine archive holds something that is not a file, a folder or a link, so it is refused."; return 1 ;; esac
    case "${m:3:1}${m:6:1}" in *[sS]*) au_say "The engine archive holds a program with its setuid or setgid bit, so it is refused."; return 1 ;; esac
  done < "$d/.long"
  tar -xzf "$a" -C "$d/root" 2>/dev/null || { au_say "The engine archive cannot be unpacked, so it is refused."; return 1; }
  while IFS= read -r f; do
    au_link_inside "$d/root" "$f" || { au_say "The engine archive holds a link that points outside it, so it is refused."; return 1; }
  done < <(find "$d/root" -type l -print)
  while IFS= read -r f; do
    ino=$(stat -f %i "$f"); nl=$(stat -f %l "$f")
    cnt=$(find "$d/root" -inum "$ino" -print | wc -l | tr -d ' ')
    [ "$cnt" = "$nl" ] || { au_say "The engine archive holds a link that points outside it, so it is refused."; return 1; }
  done < <(find "$d/root" -type f -links +1 -print)
  if [ -n "$(find "$d/root" ! -type f ! -type d ! -type l -print)" ]; then
    au_say "The engine archive holds something that is not a file, a folder or a link, so it is refused."; return 1
  fi
  rm -f "$d/.names" "$d/.long"
  au_list "$d/root" > "$d/files" || return 1
}

au_program_in() { # ENGINE-DIR -> the one file named llama-server in its list, relative to root/
  local p
  p=$(awk -F'\t' '$2 != "link" && ($1 == "llama-server" || $1 ~ /\/llama-server$/) { print $1 }' "$1/files")
  [ -n "$p" ] && [ "$(printf '%s\n' "$p" | wc -l | tr -d ' ')" = 1 ] && [ -x "$1/root/$p" ] || return 1
  printf '%s' "$p"
}

au_engine_intact() { # ENGINE-DIR -> 0 when its files are still those its list names
  [ -d "$1/root" ] && [ ! -L "$1/root" ] && [ -f "$1/files" ] && [ ! -L "$1/files" ] && au_list "$1/root" | cmp -s - "$1/files"
}

# --- step 4: measuring the Mac ------------------------------------------------------------------------

au_step4_measure() {
  local first e_nb e_file e_size e_sha e_mac major got secs dir prog
  first=$(awk -F'\t' '$1 == "build" { print $5; exit }' "$AU_REGOUT")
  e_nb=$(au_build_field "$first" 20); e_file=$(au_build_field "$first" 21)
  e_size=$(au_build_field "$first" 22); e_sha=$(au_build_field "$first" 23); e_mac=$(au_build_field "$first" 24)
  AU_MACOS=$(sw_vers -productVersion 2>/dev/null)
  major=${AU_MACOS%%.*}
  [[ $major =~ ^[1-9][0-9]?$ ]] && [ "$major" -ge "$e_mac" ] ||
    au_refuse "This Mac has macOS $AU_MACOS; the engine this recipe uses needs macOS $e_mac or later, so nothing was installed."
  AU_MEASURED_ENGINE=$e_sha
  dir="$AU_DATA/engines/$e_sha"
  if au_engine_intact "$dir"; then
    au_say "Measuring this Mac with the engine already on it."
  else
    # A first install: the engine named by the first build in the order (17 MB), before anything is asked
    au_say "Fetching the engine ($(au_bytes "$e_size")) to measure this Mac..."
    secs=$(date +%s)
    au_fetch "$AU_ENGINE_HOST/$e_nb/$e_file" "$AU_RUN/engine.archive" "$e_size"; got=$?
    secs=$(( $(date +%s) - secs ))
    [ "$got" = 0 ] && [ "$AU_CODE" = 200 ] ||
      au_refuse "The engine could not be fetched from GitHub (curl exit $got, answer ${AU_CODE:-none}). Check the network, then paste the line again."
    [ "$(au_size "$AU_RUN/engine.archive")" = "$e_size" ] && [ "$(au_sha "$AU_RUN/engine.archive")" = "$e_sha" ] ||
      au_refuse "The engine GitHub sent is not the one the registry names (its size or sha256 differs), so nothing was installed."
    [ "$secs" -ge 1 ] || secs=1
    AU_FETCH_SECS=$secs AU_FETCH_BYTES=$e_size
    dir="$AU_RUN/engine"
    au_unpack "$AU_RUN/engine.archive" "$dir" || au_refuse "Nothing was installed."
  fi
  prog=$(au_program_in "$dir") || au_refuse "The engine archive holds no single program named llama-server, so nothing was installed."
  au_limited 120 "$AU_RUN/list-devices.txt" /bin/bash -c 'cd "$1" && exec env -i PATH="$2" "$3" --list-devices' _ "$AU_RUN" "$AU_ENGINE_PATH" "$dir/root/$prog"
  AU_RAM=$(sysctl -n hw.memsize 2>/dev/null)
  [[ $AU_RAM =~ ^[1-9][0-9]{0,14}$ ]] || au_refuse "This Mac's memory cannot be read (sysctl hw.memsize), so nothing was installed."
  df -k "$AU_DATA" > "$AU_RUN/df.txt" 2>/dev/null
  AU_SLEEP=$(pmset -g 2>/dev/null | awk '$1 == "sleep" { print $2; exit }')
  AU_BATTERY=no
  pmset -g batt 2>/dev/null | grep -q InternalBattery && AU_BATTERY=yes
  case "$(PATH="$PATH:/usr/libexec/ApplicationFirewall" socketfilterfw --getglobalstate 2>/dev/null)" in
    *'(State = 0)'*) AU_FIREWALL=off ;;
    *'(State = 1)'*|*'(State = 2)'*) AU_FIREWALL=on ;;
    *) AU_FIREWALL=unknown ;;
  esac
  au_home_network
  au_port || au_refuse "No port from $AU_PORT_FIRST to $((AU_PORT_FIRST + 99)) is free on this Mac, so nothing was installed."
}

au_home_network() { # -> AU_ADDR, AU_ROUTER and AU_HOSTNAME, the home network (BD9, B4 step 5); recorded at
  # a first install only. A refusal when the Mac is not on a home network now.
  local r if_ gw mac p parts
  r=$(route -n get default 2>/dev/null) ||
    au_refuse "This Mac has no network connection now. Auster serves only on the home network it is installed on: connect to it, then paste the line again."
  if_=$(printf '%s\n' "$r" | awk '$1 == "interface:" { print $2; exit }')
  gw=$(printf '%s\n' "$r" | awk '$1 == "gateway:" { print $2; exit }')
  [[ $if_ =~ ^[a-z][a-z0-9]{0,15}$ ]] && [[ $gw =~ $AU_RE_IPV4 ]] ||
    au_refuse "This Mac's connection does not go through a router Auster can see. Auster serves only on a home network: connect to it, then paste the line again."
  networksetup -listallhardwareports 2>/dev/null | grep -qx "Device: $if_" ||
    au_refuse "This Mac's connection goes through $if_, which is not a Wi-Fi or wired port (a VPN?). Auster serves only on the home network itself: turn the VPN off, then paste the line again."
  AU_ADDR=$(ipconfig getifaddr "$if_" 2>/dev/null)
  case "$AU_ADDR" in
    10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) [[ $AU_ADDR =~ $AU_RE_IPV4 ]] || AU_ADDR= ;;
    *) AU_ADDR= ;;
  esac
  [ -n "$AU_ADDR" ] ||
    au_refuse "This Mac's address on $if_ is not a home network's (a private address). Auster serves only on a home network, so nothing was installed."
  mac=$(arp -n "$gw" 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "at") { print $(i + 1); exit } }')
  IFS=: read -r -a parts <<< "$mac"
  AU_ROUTER=
  [ "${#parts[@]}" -eq 6 ] || au_refuse "This Mac cannot see its router's hardware address, which Auster records to know the home network. Nothing was installed."
  for p in "${parts[@]}"; do
    [[ $p =~ ^[0-9a-fA-F]{1,2}$ ]] || au_refuse "This Mac cannot see its router's hardware address, which Auster records to know the home network. Nothing was installed."
    p=0$p
    AU_ROUTER+=${AU_ROUTER:+:}$(printf '%s' "${p: -2}" | tr 'A-F' 'a-f')
  done
  AU_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null)
  [[ $AU_HOSTNAME =~ ^[A-Za-z0-9-]{1,63}$ ]] || AU_HOSTNAME=
}

au_port() { # -> AU_PORT: 8484 when nothing answers there, otherwise the next port nothing answers on
  local p
  for ((p = AU_PORT_FIRST; p < AU_PORT_FIRST + 100; p++)); do
    nc -z -w 1 127.0.0.1 "$p" > /dev/null 2>&1 && continue
    nc -z -w 1 "$AU_ADDR" "$p" > /dev/null 2>&1 && continue
    AU_PORT=$p
    return 0
  done
  return 1
}

# --- step 5: choosing (section C, common/capability.js) ----------------------------------------------

au_step5_choose() { # [PEOPLE] -> AU_CH_BUILD, AU_PEOPLE, AU_CONTEXT, AU_GPU, AU_TOTAL; or a refusal in this Mac's figures
  local rc l opts=()
  [ -z "${1:-}" ] || opts=(--people "$1")
  osascript -l JavaScript "$AU_TREE/common/capability.js" "$AU_REG" "$AU_RECIPE" ${opts[@]+"${opts[@]}"} \
    --list-devices "$AU_RUN/list-devices.txt" --ram "$AU_RAM" --df "$AU_RUN/df.txt" > "$AU_RUN/choice.out" 2>/dev/null
  rc=$?
  case "$rc" in 0|3) ;; *) au_refuse "Auster could not work out what fits this Mac, so nothing was installed." ;; esac
  l=$(awk -F'\t' '$1 == "figures"' "$AU_RUN/choice.out"); au_split "$l"
  AU_GPU_LIMIT=${AU_F[1]:--} AU_MEMORY=${AU_F[2]:--} AU_FREE=${AU_F[3]:--}   # the figures section C used (C1)
  if [ "$rc" = 3 ]; then au_refusal; fi
  l=$(awk -F'\t' '$1 == "choice"' "$AU_RUN/choice.out"); au_split "$l"
  AU_CH_BUILD=${AU_F[1]} AU_PEOPLE=${AU_F[2]} AU_CONTEXT=${AU_F[3]} AU_GPU=${AU_F[4]} AU_TOTAL=${AU_F[5]}
  [[ $AU_CH_BUILD =~ $AU_RE_BUILD ]] && [[ $AU_PEOPLE =~ ^[1-9][0-9]?$ ]] && [[ $AU_CONTEXT =~ ^[1-9][0-9]{0,6}$ ]] ||
    au_refuse "Auster could not work out what fits this Mac, so nothing was installed."
}

au_refusal() { # -> section C's refusal, in this Mac's figures; exit 1
  local l why detail
  l=$(awk -F'\t' '$1 == "refused"' "$AU_RUN/choice.out"); au_split "$l"
  why=${AU_F[1]:-} detail=${AU_F[2]:-}
  case "$why" in
    fit)
      l=$(awk -F'\t' '$1 == "needs"' "$AU_RUN/choice.out"); au_split "$l"
      au_refuse "This Mac has a GPU limit of $(au_memory "$AU_GPU_LIMIT") and $(au_memory $((AU_MEMORY / 1048576))) of memory." \
        "The smallest build of this recipe, for ${AU_F[2]} people at $(au_commas "${AU_F[3]}") tokens each, needs a GPU limit of $(au_memory "${AU_F[6]}") and $(au_memory "${AU_F[7]}") of memory, so nothing was installed." ;;
    room)
      l=$(awk -F'\t' '$1 == "room"' "$AU_RUN/choice.out" | tail -n 1); au_split "$l"
      au_refuse "There is not room on this Mac's disk: it has $(au_bytes "$AU_FREE") free, and the smallest download that fits, $(au_bytes "${AU_F[2]}"), needs $(au_bytes "${AU_F[3]}") free (Auster keeps the larger of 20 GB and 5% of the disk free). Nothing was fetched." ;;
    figures)
      case "$detail" in
        gpu,*) au_refuse "The engine's report of this Mac's GPU (llama-server --list-devices) is not in the form Auster reads (${detail#gpu,}). No limit is guessed, so nothing was installed." ;;
        mac,*) au_refuse "This Mac's figures were written by a newer version of Auster. Paste the installer line from the guide, or remove Auster first." ;;
        *) au_refuse "This Mac's figures cannot be read ($detail), so nothing was installed." ;;
      esac ;;
    none) au_refuse "None of this recipe's builds can be used on this Mac ($detail), so nothing was installed." ;;
    *) au_refuse "The registry of this version cannot be read for this recipe, so nothing was installed." ;;
  esac
}

# --- step 6: the question -----------------------------------------------------------------------------

au_download_bytes() { # -> what is still to download for the chosen build: its model, and its engine when
  # neither store/ nor step 4's fetch holds it
  local n=0 m_sha e_sha
  m_sha=$(au_build_field "$AU_CH_BUILD" 30); e_sha=$(au_build_field "$AU_CH_BUILD" 23)
  [ -f "$AU_DATA/store/$m_sha" ] || n=$((n + $(au_build_field "$AU_CH_BUILD" 29)))
  if [ ! -f "$AU_DATA/store/$e_sha" ] && [ "$e_sha" != "$AU_MEASURED_ENGINE" -o ! -f "$AU_RUN/engine.archive" ]; then
    n=$((n + $(au_build_field "$AU_CH_BUILD" 22)))
  fi
  printf '%s' "$n"
}

au_facts() { # -> what the question says (B3 step 6), in fixed words with this Mac's figures
  local dl file repo l rb
  dl=$(au_download_bytes)
  file=$(au_build_field "$AU_CH_BUILD" 28); repo=$(au_build_field "$AU_CH_BUILD" 26)
  au_say ""
  au_say "Auster is ready to install $AU_LABEL on this Mac."
  au_say ""
  if [ "$dl" = 0 ]; then
    au_say "  Download    Nothing: the files it needs are already on this Mac."
  else
    au_say "  Download    $file from Hugging Face ($repo): $(au_bytes "$dl") in all."
    if [ "$AU_FETCH_BYTES" -gt 0 ]; then
      au_say "              At the speed this Mac fetched the engine, that takes $(au_duration $((dl * AU_FETCH_SECS / AU_FETCH_BYTES)))."
    else
      au_say "              How long that takes depends on the network."
    fi
  fi
  au_say "  Memory      The engine will hold $(au_memory "$AU_TOTAL") of this Mac's $(au_memory $((AU_MEMORY / 1048576))) of memory, $(au_memory "$AU_GPU") of it on the GPU."
  au_say "  People      $AU_PEOPLE people at a time, each with a context of $(au_commas "$AU_CONTEXT") tokens."
  if [ -n "$AU_HOSTNAME" ]; then
    au_say "  Address     http://$AU_HOSTNAME.local:$AU_PORT/ and http://$AU_ADDR:$AU_PORT/, on the home network"
  else
    au_say "  Address     http://$AU_ADDR:$AU_PORT/, on the home network"
  fi
  au_say "              whose router is $AU_ROUTER. It listens nowhere else: not on another network, not through a VPN."
  au_say "  Plain HTTP  Anyone on that Wi-Fi who sets out to can read what is sent, the devices' keys included."
  au_say "  Account     The engine runs as $AU_USER, with that account's files, and with no sandbox."
  case "$AU_SLEEP" in
    0) au_say "  Sleep       This Mac is set never to sleep." ;;
    1) au_say "  Sleep       This Mac sleeps after 1 minute idle, and a sleeping Mac does not answer." ;;
    *[!0-9]*|'') au_say "  Sleep       This Mac's sleep setting cannot be read." ;;
    *) au_say "  Sleep       This Mac sleeps after $AU_SLEEP minutes idle, and a sleeping Mac does not answer." ;;
  esac
  case "$AU_FIREWALL" in
    unknown) au_say "  Firewall    Its state cannot be read." ;;
    *) au_say "  Firewall    $AU_FIREWALL." ;;
  esac
  [ "$AU_BATTERY" = no ] || au_say "  Laptop      This Mac has a battery: with its lid closed it sleeps, whatever Auster does, so it is not always on."
  while IFS= read -r l; do
    au_split "$l"
    rb=$(au_build_field "${AU_F[1]}" 28)
    au_say "  Room        The first choice for this Mac, $rb, would need $(au_bytes "${AU_F[3]}") free (a download of $(au_bytes "${AU_F[2]}"));"
    au_say "              this Mac has $(au_bytes "$AU_FREE") free, so the next build that fits is offered."
  done < <(awk -F'\t' '$1 == "room"' "$AU_RUN/choice.out")
  au_say ""
}

au_step6_question() { # -> on a yes, AU_AWAKE and the choice are settled; a no removes this run's files, exit 1
  local i n
  au_facts
  if au_yes "Keep this Mac awake while the engine runs and while it downloads?"; then AU_AWAKE=yes; else AU_AWAKE=no; fi
  for i in 1 2 3 4 5 6 7 8 9 10; do
    au_ask "Install for $AU_PEOPLE people? Type yes, another number of people (1 to $AU_DEFAULT_PEOPLE), or no:" ||
      au_refuse "Nothing was installed."
    case "$AU_REPLY" in
      yes|YES|Yes) au_mac_record; au_device_name; au_zprofile_question; return 0 ;;
      no|NO|No) au_refuse "Nothing was installed, and nothing of this run is left." ;;
    esac
    n=$AU_REPLY
    if [[ $n =~ ^[1-9][0-9]?$ ]] && [ "$n" -le "$AU_DEFAULT_PEOPLE" ]; then
      au_step5_choose "$n"
      au_facts
    else
      au_say "Please type yes, no, or a number of people from 1 to $AU_DEFAULT_PEOPLE."
    fi
  done
  au_refuse "Nothing was installed."
}

au_device_name() { # -> AU_DEVICE: the name of the first device, asked with the question so that nothing is
  # asked after it (B3 step 11 makes its key); empty when a device already has a key
  local i
  AU_DEVICE=
  ! ls "$AU_DATA"/keys/k*.name > /dev/null 2>&1 || return 0
  for i in 1 2 3 4 5; do
    au_ask "Name the first device that will use Auster (lower-case letters, digits and -, such as ipad):" || break
    if [[ $AU_REPLY =~ $AU_RE_DEVICE ]]; then AU_DEVICE=$AU_REPLY; return 0; fi
    au_say "That name is not one Auster takes."
  done
  AU_DEVICE=device-1
}

au_zprofile_question() { # -> on a yes, the line that lets Terminal find `auster` added to ~/.zprofile (B6): asked
  # with the question, so that nothing is asked after the downloads, and written at once; no answer is a no
  au_zprofile_has && return 0
  au_yes "Add one line to the end of ~/.zprofile, so that Terminal finds the command auster?" || return 0
  au_zprofile_add || au_say "~/.zprofile could not be changed. For Terminal to find auster, add this line to it yourself: $AU_ZPROFILE_LINE"
}

au_mac_record() { # -> builds/mac (au_mac_write); and builds/local-name, the `.local` name the question gave the household's
  # devices (common/auster's header; B6, T116). A first install's only: an update records neither the router nor the name
  # again, so that only `auster network` changes them (T100); it writes no `mac` before its yes, and after it, once
  # Auster's programs pass, writes `mac` with the router and keep-awake of the record it replaces (au_update_mac)
  [ -e "$AU_DATA/builds/mac" ] || au_made "$AU_DATA/builds/mac"
  au_mac_write || au_stop "This Mac's figures could not be written."
  [ -e "$AU_DATA/builds/local-name" ] || au_made "$AU_DATA/builds/local-name"
  au_localname_write "$AU_HOSTNAME" || au_stop "This Mac's name on the home network could not be recorded."
}

au_mac_write() { # -> builds/mac (C1, capability-lib.js's header gives its form) from AU_GPU_LIMIT, AU_MEMORY, AU_MACOS,
  # AU_ROUTER and AU_AWAKE, measured now, by rename
  local t="$AU_DATA/builds/.mac.new.$$"
  printf 'auster-record 1\ngpu-mib\t%s\nmemory-bytes\t%s\nmacos\t%s\nmeasured\t%s\nrouter\t%s\nkeep-awake\t%s\n' \
    "$AU_GPU_LIMIT" "$AU_MEMORY" "$AU_MACOS" "$(au_now)" "$AU_ROUTER" "$AU_AWAKE" > "$t" &&
    chmod 600 "$t" && mv -f "$t" "$AU_DATA/builds/mac" || { rm -f "$t"; return 1; }
}

# --- steps 7 to 9: the files ---------------------------------------------------------------------------

au_store_has() { # SHA SIZE -> 0 when store/ holds that file whole, checked again (AD13)
  local f="$AU_DATA/store/$1"
  [ -f "$f" ] && [ ! -L "$f" ] || return 1
  if [ -n "${2:-}" ] && [ "$(au_size "$f")" != "$2" ]; then return 1; fi
  [ "$(au_sha "$f")" = "$1" ]
}

au_store_put() { # FILE SHA -> FILE renamed into store/<sha>, read-only
  chmod 444 "$1" && mv -f "$1" "$AU_DATA/store/$2"
}

au_step7_model() { # the model: the publisher asked first, then fetched, resumable, and checked (B3 step 7)
  local sha size repo commit file url out code hsize etag pid got
  repo=$(au_build_field "$AU_CH_BUILD" 26); commit=$(au_build_field "$AU_CH_BUILD" 27)
  file=$(au_build_field "$AU_CH_BUILD" 28); size=$(au_build_field "$AU_CH_BUILD" 29); sha=$(au_build_field "$AU_CH_BUILD" 30)
  if [ -e "$AU_DATA/store/$sha" ]; then
    au_store_has "$sha" "$size" && { au_say "The model is already on this Mac, and still the file the registry names."; return 0; }
    chmod 644 "$AU_DATA/store/$sha" 2>/dev/null; rm -f "$AU_DATA/store/$sha"
    au_say "The model on this Mac had changed, so it is fetched again."
  fi
  url="$AU_MODEL_HOST/$repo/resolve/$commit/$file"
  out=$(curl -q --proto =https --tlsv1.2 -sS -I --max-time 60 -o /dev/null \
    -w '%{http_code}\t%header{x-linked-size}\t%header{x-linked-etag}' "$url" 2>/dev/null) ||
    au_stop "Hugging Face could not be reached to ask about the model. Check the network."
  au_split "$out"
  code=${AU_F[0]:-} hsize=${AU_F[1]:-} etag=${AU_F[2]:-}
  case "$code" in
    404) au_stop "The publisher no longer offers this model file ($file), so nothing more was installed." ;;
    200|301|302|303|307|308) ;;
    *) au_stop "Hugging Face answered $code when asked about the model, so nothing more was installed." ;;
  esac
  if [ -n "$hsize" ] && [ "$hsize" != "$size" ]; then au_stop "The publisher reports a size for $file other than the registry's, so it was not fetched."; fi
  etag=${etag#W/}; etag=${etag//\"/}; etag=$(printf '%s' "$etag" | tr 'A-F' 'a-f')
  if [[ $etag =~ $AU_RE_SHA ]] && [ "$etag" != "$sha" ]; then au_stop "The publisher reports a sha256 for $file other than the registry's, so it was not fetched."; fi
  au_say "Fetching $file ($(au_bytes "$size"))..."
  curl -q --proto =https --proto-redir =https --tlsv1.2 -sS -L -C - --speed-limit 10240 --speed-time 120 \
    --max-filesize "$size" -o "$AU_DATA/store/$sha.part" -w '%{http_code}' "$url" > "$AU_RUN/code" 2>/dev/null &
  pid=$!
  if [ "$AU_AWAKE" = yes ]; then caffeinate -i -w "$pid" > /dev/null 2>&1 & fi
  wait "$pid"; got=$?
  code=$(cat "$AU_RUN/code" 2>/dev/null)
  if [ "$got" != 0 ] || { [ "$code" != 200 ] && [ "$code" != 206 ] && [ "$code" != 416 ]; }; then
    au_stop "The model's download stopped (curl exit $got, answer ${code:-none}) at $(au_bytes "$(au_size "$AU_DATA/store/$sha.part" || echo 0)") of $(au_bytes "$size"). Pasting the line again resumes it."
  fi
  got=$(au_size "$AU_DATA/store/$sha.part")
  if [ "$got" != "$size" ]; then
    [ "$got" -lt "$size" ] || rm -f "$AU_DATA/store/$sha.part"
    au_stop "The model's download is $(au_bytes "${got:-0}"), not the $(au_bytes "$size") the registry names. Pasting the line again resumes it."
  fi
  if [ "$(au_sha "$AU_DATA/store/$sha.part")" != "$sha" ]; then
    rm -f "$AU_DATA/store/$sha.part"
    au_stop "The model that arrived is not the file the registry names (its sha256 differs), so it was deleted."
  fi
  au_store_put "$AU_DATA/store/$sha.part" "$sha" || au_stop "The model could not be put in place."
}

au_step8_assets() { # the template, the system prompt and the test, from the tree by sha256 (B3 step 8, A4)
  local what sha f found t
  for what in 8:template 9:system-prompt 10:test; do
    sha=$(au_build_field "$AU_CH_BUILD" "${what%%:*}")
    au_store_has "$sha" && continue
    found=
    for f in "$AU_TREE"/assets/*; do
      [ -f "$f" ] && [ ! -L "$f" ] || continue
      if [ "$(au_sha "$f")" = "$sha" ]; then found=$f; break; fi
    done
    [ -n "$found" ] || au_stop "This version of Auster holds no ${what#*:} with the sha256 the build names, so nothing more was installed."
    t="$AU_DATA/store/.$sha.new.$$"
    cp "$found" "$t" && [ "$(au_sha "$t")" = "$sha" ] && au_store_put "$t" "$sha" ||
      au_stop "The ${what#*:} could not be put in place."
  done
}

au_step9_engine() { # the engine, in store/ and unpacked into engines/<sha256>/ with its file list (B3 step 9)
  local sha size nb file d t got
  nb=$(au_build_field "$AU_CH_BUILD" 20); file=$(au_build_field "$AU_CH_BUILD" 21)
  size=$(au_build_field "$AU_CH_BUILD" 22); sha=$(au_build_field "$AU_CH_BUILD" 23)
  if ! au_store_has "$sha" "$size"; then
    t="$AU_DATA/store/.$sha.new.$$"
    if [ "$sha" = "$AU_MEASURED_ENGINE" ] && [ -f "$AU_RUN/engine.archive" ]; then
      cp "$AU_RUN/engine.archive" "$t" || au_stop "The engine could not be put in place."
    else
      au_say "Fetching the engine ($(au_bytes "$size"))..."
      au_fetch "$AU_ENGINE_HOST/$nb/$file" "$t" "$size"; got=$?
      [ "$got" = 0 ] && [ "$AU_CODE" = 200 ] || { rm -f "$t"; au_stop "The engine could not be fetched from GitHub (curl exit $got)."; }
    fi
    [ "$(au_size "$t")" = "$size" ] && [ "$(au_sha "$t")" = "$sha" ] || { rm -f "$t"; au_stop "The engine is not the one the registry names, so it was deleted."; }
    au_store_put "$t" "$sha" || au_stop "The engine could not be put in place."
  fi
  d="$AU_DATA/engines/$sha"
  if ! au_engine_intact "$d"; then
    t="$AU_DATA/engines/.$sha.new.$$"
    au_unpack "$AU_DATA/store/$sha" "$t" || { rm -rf "$t"; au_stop "Nothing more was installed."; }
    rm -rf "$d"
    mv "$t" "$d" || au_stop "The engine could not be put in place."
  fi
  AU_ENGINE_DIR=$d
  AU_LISTSHA=$(au_sha "$d/files")
  AU_PROGRAM=$(au_program_in "$d") || au_stop "The engine holds no single program named llama-server."
}

# --- step 10: the test, in isolation (B3 step 10, D3.6 step 4) -----------------------------------------

au_descriptor() { # FILE SPEED -> the chosen build's descriptor (A5), by rename: the format line, the build,
  # engine and model lines of the registry byte for byte, and the launch line
  local t="${1%/*}/.${1##*/}.new.$$"
  { printf 'auster-descriptor 1\n'
    au_raw "$AU_CH_BUILD" build; printf '\n'
    au_raw "$AU_CH_BUILD" engine; printf '\n'
    au_raw "$AU_CH_BUILD" model; printf '\n'
    printf 'launch\t%s\t%s\t%s\t%s\t%s\n' "$AU_PEOPLE" "$AU_CONTEXT" "$AU_PORT" "$AU_LISTSHA" "$2"; } > "$t" &&
    chmod 600 "$t" && mv -f "$t" "$1"
}

au_candidate_stop() { # -> the candidate engine of step 10 stopped, if it runs
  local i
  [ -n "$AU_CANDIDATE" ] || return 0
  kill "$AU_CANDIDATE" 2>/dev/null
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do kill -0 "$AU_CANDIDATE" 2>/dev/null || break; sleep 0.5; done
  kill -9 "$AU_CANDIDATE" 2>/dev/null
  wait "$AU_CANDIDATE" 2>/dev/null
  AU_CANDIDATE=
}

au_step10_test() { # -> 0 on a pass; on a fail the descriptor goes to failed/ and the run stops with exit 5
  local port k i code rc r="$AU_DATA/builds/$AU_RECIPE" tsha ssha f
  for ((port = AU_TEST_PORT_FIRST; port < AU_TEST_PORT_FIRST + 100; port++)); do
    nc -z -w 1 127.0.0.1 "$port" > /dev/null 2>&1 || break
  done
  k="$AU_RUN/test-key"
  ( umask 077; mkdir "$k" && openssl rand -hex 16 > "$k/key" ) && [[ $(head -n 1 "$k/key") =~ $AU_RE_KEY ]] ||
    au_stop "A key for the test could not be made."
  tsha=$(au_build_field "$AU_CH_BUILD" 8); ssha=$(au_build_field "$AU_CH_BUILD" 9)
  au_say "Testing the build on this Mac, for $AU_PEOPLE people at $(au_commas "$AU_CONTEXT") tokens each..."
  ( cd "$AU_DATA/store" && exec env -i PATH="$AU_ENGINE_PATH" "$AU_ENGINE_DIR/root/$AU_PROGRAM" \
      -m "$(au_build_field "$AU_CH_BUILD" 30)" --alias "$AU_CH_BUILD" -c $((AU_PEOPLE * AU_CONTEXT)) -np "$AU_PEOPLE" \
      --host 127.0.0.1 --port "$port" --api-key-file "$k/key" --offline --no-slots --no-webui-mcp-proxy \
      --jinja --chat-template-file "$tsha" --temp "$(au_build_field "$AU_CH_BUILD" 15)" \
      --top-p "$(au_build_field "$AU_CH_BUILD" 16)" --fit off -ngl all ) > "$AU_RUN/candidate.log" 2>&1 &
  AU_CANDIDATE=$!
  code=
  for ((i = 0; i < 600; i++)); do
    kill -0 "$AU_CANDIDATE" 2>/dev/null || break
    code=$(curl -q -s --max-time 5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/health" 2>/dev/null)
    [ "$code" = 200 ] && break
    sleep 0.5
  done
  rc=1
  if [ "$code" = 200 ]; then
    osascript -l JavaScript "$AU_TREE/common/recipe-test.js" "$AU_DATA/store/$(au_build_field "$AU_CH_BUILD" 10)" \
      "http://127.0.0.1:$port" "$k/key" "$AU_DATA/store/$ssha" > "$AU_RUN/test.out" 2>&1
    rc=$?
    sed 's/^/  /' "$AU_RUN/test.out"
    case "$(tail -n 1 "$AU_RUN/test.out")" in "result pass"*) ;; *) [ "$rc" != 0 ] || rc=1 ;; esac
  else
    au_say "  The engine did not start."
  fi
  au_candidate_stop
  rm -rf "$k"
  if [ "$rc" = 0 ]; then
    for f in "$r"/failed/*-"$AU_CH_BUILD"; do [ -f "$f" ] && rm -f "$f"; done   # tried again, and it passed
    return 0
  fi
  au_mkdir "$r" && au_mkdir "$r/failed" || au_stop "The build failed its test, and its record could not be written."
  au_descriptor "$r/failed/$(au_now)-$AU_CH_BUILD" 0
  au_stop "The build did not pass the recipe's test on this Mac, so nothing is serving and nothing is loaded."
}

# --- steps 11 to 15 ------------------------------------------------------------------------------------

au_step11_keys() { # one key for each device, named by the household, and Auster's own for the probe (B7), by
  # common/auster's functions, which `auster key add` uses too; then the engine's key file, written and checked
  AU_NEW_DEVICES=() AU_NEW_KEYS=()
  au_key_list
  if [ "${#AU_KEY_IDS[@]}" = 0 ]; then
    au_key_mint "${AU_DEVICE:-device-1}" || au_stop "A device key could not be made."
    AU_NEW_DEVICES+=("${AU_DEVICE:-device-1}")
    AU_NEW_KEYS+=("$AU_KEY_ID")
  fi
  [ -f "$AU_DATA/keys/probe" ] || au_key_new "$AU_DATA/keys/probe" || au_stop "Auster's own key could not be made."
  au_keys_write || au_stop "The engine's key file is not as written, so the engine is not started."
}

au_xml() { local s=$1; s=${s//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}; printf '%s' "$s"; }

au_plist() { # LABEL -> the job file (B4, B5), with every path escaped for XML
  local data logs
  data=$(au_xml "$AU_DATA")
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
    '<plist version="1.0">' '<dict>' "	<key>Label</key>" "	<string>$1</string>" "	<key>ProgramArguments</key>" "	<array>" \
    "		<string>/bin/bash</string>"
  if [ "$1" = "$AU_LABEL_ENGINE" ]; then
    logs="$data/logs/engine.log"
    printf '%s\n' "		<string>$data/jobs/auster-engine</string>" "	</array>" "	<key>KeepAlive</key>" "	<true/>" \
      "	<key>ProcessType</key>" "	<string>Interactive</string>" "	<key>ThrottleInterval</key>" "	<integer>30</integer>"
  else
    logs="$data/logs/check.log"
    printf '%s\n' "		<string>$data/jobs/auster-check</string>" "	</array>" "	<key>RunAtLoad</key>" "	<true/>" \
      "	<key>StartCalendarInterval</key>" "	<array>"
    for h in 0 4 8 12 16 20; do
      printf '%s\n' "		<dict>" "			<key>Hour</key>" "			<integer>$h</integer>" "			<key>Minute</key>" "			<integer>7</integer>" "		</dict>"
    done
    printf '%s\n' "	</array>" "	<key>ProcessType</key>" "	<string>Background</string>"
  fi
  printf '%s\n' "	<key>StandardOutPath</key>" "	<string>$logs</string>" "	<key>StandardErrorPath</key>" "	<string>$logs</string>" \
    "	<key>EnvironmentVariables</key>" "	<dict>" "		<key>PATH</key>" "		<string>$AU_ENGINE_PATH</string>" "	</dict>" '</dict>' '</plist>'
}

au_jobs_write() { # -> both job files in ~/Library/LaunchAgents, written by rename when they differ
  local l f t
  [ -d "$HOME/Library/LaunchAgents" ] || mkdir -p "$HOME/Library/LaunchAgents" || au_stop "$HOME/Library/LaunchAgents could not be made."
  [ ! -L "$HOME/Library/LaunchAgents" ] || au_stop "$HOME/Library/LaunchAgents is a link, so no job was written."
  for l in "$AU_LABEL_ENGINE" "$AU_LABEL_CHECK"; do
    f=$(au_job_file "$l") t="$HOME/Library/LaunchAgents/.$l.plist.new.$$"
    au_plist "$l" > "$t" && plutil -lint "$t" > /dev/null 2>&1 || { rm -f "$t"; au_stop "The job file for $l could not be written."; }
    if [ -f "$f" ] && [ ! -L "$f" ] && cmp -s "$t" "$f"; then rm -f "$t"; else mv -f "$t" "$f"; fi
  done
}

au_step12_switch() { # the switch: serving written by rename with a speed of 0, then the jobs (B3 step 12)
  local r="$AU_DATA/builds/$AU_RECIPE"
  au_mkdir "$r" && au_mkdir "$r/kept" || au_stop "$r could not be made."
  au_descriptor "$r/serving" 0 || au_stop "The record of what serves could not be written."
  au_jobs_write
  rm -rf "$AU_DATA/builds/stopped"   # whatever it is: a stopped that cannot be read means stopped (D3.1)
  AU_T0=$(date +%s)
  au_job_load "$AU_LABEL_ENGINE" && au_job_load "$AU_LABEL_CHECK" || au_stop "launchd did not load Auster's jobs."
}

au_step13_check() { # the server check (B3 step 13): passed goes on; open and not answered end with exit 4
  au_say "Checking the server on the home network..."
  au_server_check "$AU_RECIPE" "$AU_T0"
  case "$AU_CHECK" in
    passed) au_say "The server answered, at $AU_CHECK_SPEED tokens a second, and refused a request with no key." ;;
    open)
      au_say "The server did not refuse a request that carried no key, so Auster stopped it. It stays stopped until \`auster start\`."
      au_say "The device keys are made but not shown, and the install is not finished. Remove it with: \"$AU_DATA/bin/auster\" remove"
      exit 4 ;;
    *)
      au_say "The server did not answer its check within $AU_CHECK_SECS s: $AU_CHECK_WHY."
      au_say "Its jobs stay loaded, so the engine job keeps trying; \`auster status\` says how its last start went."
      au_say "The device keys are made but not shown, and the install is not finished: paste the line again to check again and finish, or remove it with: \"$AU_DATA/bin/auster\" remove"
      exit 4 ;;
  esac
}

au_step14_show() { # each new device's key as a QR code (B7), only after a passed server check (step 13). With no
  # terminal to draw it on, it says how to show it later, and the install goes on
  local i
  for ((i = 0; i < ${#AU_NEW_KEYS[@]}; i++)); do
    au_say "A key is made for the device ${AU_NEW_DEVICES[$i]}."
    au_qr_show "${AU_NEW_DEVICES[$i]}" "${AU_NEW_KEYS[$i]}" || true
  done
}

au_step15_stamp() { # the stamp (D3.1): the line followed, the version, the commit and the time, by rename;
  # left as it is when the line, the version and the commit are the same. The rule file that reads it is
  # copied into _update first (D3.2, T43), so that the two are of one version once a run has finished. AU_STAMP_NEW
  # says whether the stamp was written (1) or left as it was (0)
  local f="$AU_DATA/_update/scripts" t
  AU_STAMP_NEW=0
  au_mkdir "$AU_DATA/_update" || au_stop "$AU_DATA/_update could not be made."
  au_put "$AU_TREE/common/updates.sh" "$AU_DATA/_update/updates.sh" 644 || au_stop "$AU_DATA/_update/updates.sh could not be written."
  if au_line_read "$f" 4 && [ "${AU_LF[0]}" = "$AU_LINE" ] && [ "${AU_LF[1]}" = "$AU_VERSION" ] &&
     [ "${AU_LF[2]}" = "$AU_COMMIT" ] && [[ ${AU_LF[3]} =~ $AU_RE_UTC ]]; then
    return 0
  fi
  t="$AU_DATA/_update/.scripts.new.$$"
  printf 'auster-record 1\t%s\t%s\t%s\t%s\n' "$AU_LINE" "$AU_VERSION" "$AU_COMMIT" "$(au_now)" > "$t" && mv -f "$t" "$f" ||
    au_stop "The stamp could not be written."
  AU_STAMP_NEW=1
}

# --- the update (D3.6; U4) -------------------------------------------------------------------------------
# `update` (install.sh update, which `auster update` runs) and a second paste of the installer line on a Mac that serves
# the recipe (T65) run B3's steps for recipes already installed. Step 3 takes the lock and writes no program: Auster's
# own programs change only after the yes (B3 step 6, BD18). Step 4 measures with the engine already in engines/ and
# fetches nothing; it records neither the router nor the `.local` name, chooses no port and writes no `mac` (T65,
# T100). Every size and sha256 comes from the registry in this tree (AU_REG), never from _update/registry. Each recipe
# that has `serving` is judged by section C with the household's number of people carried over (C4) and is OK (its
# build and setting are the ones served), held, passed over (and why) or withdrawn, one line each; or its build or
# setting would change, and it goes to the question (D3.6 step 2), after its template, system prompt and test are
# found in store/ or this tree's assets/ (step 8's lookup, made before the question so that no yes is asked for a
# build this tree cannot install: T54). A no leaves everything as it was and the build waiting (T7, T35). A yes (U5,
# au_update_yes) changes Auster's own programs first when they differ, or checks the server first when jobs/previous/
# shows an earlier change never checked (au_update_programs: B3 step 6, BD18, T94); then writes `mac` (au_update_mac);
# then switches a change of setting (au_switch_setting); a change of build ends at TODO(U5) with exit 3, nothing changed.
# Then, and with nothing to change, the run makes the server check when a `serving` has a speed of 0 or jobs/previous/
# is there (B3 step 13), shows the devices' keys when the Mac had no stamp (an install that never finished,
# T65), and writes step 15, with _update's registry, notes and offer when the stamp moved (U4: so that each recipe's
# line is not `unknown` until the next check). No record is written before the question but the lock, nor after the
# yes before the programs have passed their check, and step 15 is reached only when Auster's programs are byte for
# byte this tree's, so no record of a format the programs in use do not read is ever written by a run that has not
# changed them and seen them pass (D3.1; the row "a record's format and rollback").
# `people` (au_people, below the update) is the same procedure for the build each recipe serves, at the number of
# people asked: no other build, no download, no test, no program changed and no stamp (B6).

au_later() { # X Y -> 0 when version X is later than version Y, both matched to AU_RE_VERSION, compared as numbers (D3.2)
  local x=${1#v} y=${2#v} i a b
  for i in 1 2 3; do
    a=${x%%.*} b=${y%%.*}; x=${x#*.} y=${y#*.}
    [ "$a" -gt "$b" ] && return 0
    [ "$a" -lt "$b" ] && return 1
  done
  return 1
}

au_update_measure() { # -> B3 step 4 on an update (D3.6): AU_FIGURES, AU_DISKARGS and AU_NODISK, what section C is given.
  # The GPU limit from --list-devices of the engine already in engines/ that serving names, or, when that engine is not
  # the one its list names, the `mac` record's; the memory measured; the disk holdings as the rule file makes them, and
  # no disk figures at all when a descriptor cannot be read (D3.3)
  local r dir prog=
  AU_RAM=$(sysctl -n hw.memsize 2>/dev/null)
  [[ $AU_RAM =~ ^[1-9][0-9]{0,14}$ ]] || au_refuse "This Mac's memory cannot be read (sysctl hw.memsize), so nothing was changed."
  AU_FIGURES=(--mac "$AU_DATA/builds/mac" --ram "$AU_RAM")
  AU_SV_ENGINE=
  for r in "${AU_URECIPES[@]}"; do au_serving_read "$r" && break; AU_SV_ENGINE=; done
  dir="$AU_DATA/engines/${AU_SV_ENGINE:-none}"
  if [ -n "$AU_SV_ENGINE" ] && au_engine_intact "$dir" && prog=$(au_program_in "$dir"); then
    au_say "Measuring this Mac with the engine already on it; nothing is fetched before the question."
    au_limited 120 "$AU_RUN/list-devices.txt" /bin/bash -c 'cd "$1" && exec env -i PATH="$2" "$3" --list-devices' _ "$AU_RUN" "$AU_ENGINE_PATH" "$dir/root/$prog"
    AU_FIGURES+=(--list-devices "$AU_RUN/list-devices.txt")
  else
    au_say "The engine this Mac serves with is not the one its list names, so the figures recorded at install (builds/mac) are used."
  fi
  AU_DISKARGS=() AU_NODISK=()
  if df -k "$AU_DATA" > "$AU_RUN/df.txt" 2>/dev/null &&
     ( AU_UPDATE_DIR="$AU_DATA/_update"; . "$AU_TREE/common/updates.sh"; _auu_holdings "$AU_RUN/disk" ) > /dev/null 2>&1; then
    AU_DISKARGS=(--df "$AU_RUN/df.txt" --disk "$AU_RUN/disk")
  else
    AU_NODISK=(-u AU_DISK_FREE_BYTES -u AU_DISK_TOTAL_BYTES)
  fi
}

au_reason_words() { # CODES -> D3.3's reasons, comma-separated codes, in words
  local c x words=
  for c in ${1//,/ }; do
    case "$c" in
      fit) x='does not fit' ;; room) x='no room on disk' ;; held) x=held ;; failed) x='failed here' ;;
      unreadable) x='cannot be read' ;; tier) x='above its trust tiers' ;; withdrawn) x=withdrawn ;;
      serving) x='what it serves cannot be read' ;; figures) x="this Mac's figures cannot be read" ;; *) continue ;;
    esac
    words+="${words:+, }$x"
  done
  printf '%s' "${words:-no build can be used}"
}

au_update_assets() { # BUILD -> 0 when store/ or this tree's assets/ hold the template, the system prompt and the test the build
  # names, each by its sha256, as step 8 finds them; otherwise AU_MISSING names the first that neither holds
  local what sha f found
  for what in 8:template 9:system-prompt 10:test; do
    sha=$(au_build_field "$1" "${what%%:*}")
    au_store_has "$sha" && continue
    found=
    for f in "$AU_TREE"/assets/*; do
      [ -f "$f" ] && [ ! -L "$f" ] || continue
      if [ "$(au_sha "$f")" = "$sha" ]; then found=$f; break; fi
    done
    [ -n "$found" ] || { AU_MISSING=${what#*:}; return 1; }
  done
}

au_update_judge() { # RECIPE -> AU_J: ok, held, passed, withdrawn or change, with AU_J_SAY, its line; for a change, AU_JK
  # (build or setting) and the figures the question gives. Section C (capability.js) is given this tree's registry, the
  # build served, the household's number of people from its launch line (C4), its `hold` (unreadable: every build held,
  # D3.1) and failed/, the build loaded when the engine's job is loaded (C5), and the figures of step 4
  local r=$1 l f id seen=0 held= lf=() cf=() opts=()
  AU_J=passed AU_J_SAY= AU_JK= AU_JREMOVE=() AU_JNAME="This Mac's recipe" AU_JLABEL=
  AU_REGOUT="$AU_RUN/registry-$r.out"
  osascript -l JavaScript "$AU_TREE/common/registry.js" "$AU_REG" "$r" > "$AU_REGOUT" 2>/dev/null
  l=$(awk -F'\t' '$1 == "recipe"' "$AU_REGOUT"); au_split "$l"
  if [[ ${AU_F[4]:-} =~ ^[a-z][a-z0-9-]{1,40}$ ]]; then AU_JLABEL=${AU_F[4]} AU_JNAME="The recipe ${AU_F[4]}"; fi
  if ! au_serving_read "$r"; then
    AU_J_SAY="$AU_JNAME: what it serves (builds/$r/serving) cannot be read, so it is not updated."
    return 0
  fi
  AU_JNOW=$AU_SV_BUILD AU_JNOWFILE=$AU_SV_MODEL_FILE AU_JP0=$AU_SV_PEOPLE AU_JC0=$AU_SV_CONTEXT
  opts=(--serving "$AU_JNOW" --people "$AU_JP0")
  au_hold_read "$r"
  case "$AU_HOLD" in
    absent) ;;
    ok) for id in ${AU_HOLD_IDS[@]+"${AU_HOLD_IDS[@]}"}; do opts+=(--held "$id"); done ;;
    *) opts+=(--hold-unreadable) ;;
  esac
  for f in "$AU_DATA/builds/$r"/failed/*; do
    { [ -e "$f" ] || [ -L "$f" ]; } && au_entry_read "$f" && opts+=(--failed "$AU_SV_BUILD")
  done
  if au_job_loaded "$AU_LABEL_ENGINE"; then opts+=(--loaded "$AU_JNOW" "$AU_JP0" "$AU_JC0"); fi
  env ${AU_NODISK[@]+"${AU_NODISK[@]}"} osascript -l JavaScript "$AU_TREE/common/capability.js" "$AU_REG" "$r" "${opts[@]}" \
    "${AU_FIGURES[@]}" ${AU_DISKARGS[@]+"${AU_DISKARGS[@]}"} > "$AU_RUN/choice-$r.out" 2>/dev/null
  while IFS= read -r l; do
    au_split "$l"
    case "${AU_F[0]}" in
      figures) AU_JMEM=${AU_F[2]:--} AU_JGPUL=${AU_F[1]:--} AU_JGPUFROM=${AU_F[5]:--} ;;
      line) lf=("${AU_F[@]}") ;;
      choice) cf=("${AU_F[@]}") ;;
      remove) AU_JREMOVE+=("$l") ;;
      build)   # a build earlier in the order than the one served, ruled out by its hold alone
        if [ "${AU_F[2]:-}" = "$AU_JNOW" ]; then seen=1
        elif [ "$seen" = 0 ] && [ -z "$held" ] && [ "${AU_F[3]:-}" = held ]; then held=${AU_F[2]}; fi ;;
    esac
  done < "$AU_RUN/choice-$r.out"
  [[ ${AU_JMEM:-} =~ ^[1-9][0-9]{0,14}$ ]] || AU_JMEM=$AU_RAM
  AU_JWD=${lf[3]:--}
  if [ "${#cf[@]}" -ge 8 ]; then AU_JP=${cf[2]} AU_JC=${cf[3]} AU_JGPU=${cf[4]} AU_JALL=${cf[5]} AU_JWAY=${cf[6]}; fi
  case "${lf[1]:-}" in
    same)
      if [ "${#cf[@]}" -ge 8 ] && [ "${cf[1]}" = "$AU_JNOW" ] && { [ "$AU_JP" != "$AU_JP0" ] || [ "$AU_JC" != "$AU_JC0" ]; }; then
        AU_J=change AU_JK=setting AU_JPICK=$AU_JNOW AU_JDL=0
      elif [ -n "$held" ]; then
        AU_J=held AU_J_SAY="$AU_JNAME: build $held is held on this Mac, so it stays on build $AU_JNOW, and nothing changes."
      else
        AU_J=ok AU_J_SAY="$AU_JNAME: OK. Build $AU_JNOW serves it, for $AU_JP0 people at $(au_commas "$AU_JC0") tokens each."
      fi ;;
    waiting)
      if [[ ${lf[2]} =~ $AU_RE_BUILD ]] && [ "${#cf[@]}" -ge 8 ] && [ "${cf[1]}" = "${lf[2]}" ]; then
        AU_J=change AU_JK=build AU_JPICK=${lf[2]} AU_JDL=${lf[5]}
        [[ $AU_JDL =~ ^(0|[1-9][0-9]{0,14})$ ]] || AU_JDL=0
        if ! au_update_assets "$AU_JPICK"; then
          AU_J=passed AU_J_SAY="This version of Auster holds no $AU_MISSING with the sha256 build $AU_JPICK names. $AU_JNAME is not updated: it keeps serving build $AU_JNOW."
        fi
      else
        AU_J_SAY="$AU_JNAME: what an update would change cannot be worked out, so it is not updated: it keeps serving build $AU_JNOW."
      fi ;;
    withdrawn)   # TODO(U8): the words of the reason, calm for superseded and corrected (D3.8)
      AU_J=withdrawn AU_J_SAY="$AU_JNAME: the build it serves, $AU_JNOW, has been withdrawn, and no other build is offered for this Mac; it keeps serving." ;;
    passed-over) AU_J_SAY="$AU_JNAME: passed over ($(au_reason_words "${lf[4]:-}")), so it is not updated: it keeps serving build $AU_JNOW." ;;
    unreadable) AU_J_SAY="$AU_JNAME: passed over (cannot be read), so it is not updated: it keeps serving build $AU_JNOW." ;;
    *) AU_J_SAY="$AU_JNAME: section C gave no answer for it, so it is not updated: it keeps serving build $AU_JNOW." ;;
  esac
}

au_update_question() { # -> 0 on a yes, 1 on a no (D3.6 step 2), for the recipe au_update_judge judged a change: what will
  # change, in figures, with the household's number of people carried over (C4); the download; the earlier builds the
  # disk rule would remove; which way the switch goes on this Mac and how long the server will not answer; and whether
  # Auster's own programs change. Nothing has been fetched, and nothing is written whatever the answer
  local file= repo= parts= l n=0 m_sha e_sha
  au_say ""
  if [ "$AU_JK" = build ]; then
    au_say "$AU_JNAME: an update is waiting. Nothing has been fetched, and nothing changes without a yes."
    file=$(au_build_field "$AU_JPICK" 28) repo=$(au_build_field "$AU_JPICK" 26)
  else
    au_say "$AU_JNAME: its setting would change, on the build it serves. Nothing changes without a yes."
  fi
  au_say ""
  au_say "  Now         build $AU_JNOW${AU_JNOWFILE:+ ($AU_JNOWFILE)}, $AU_JP0 people at a time, each with a context of $(au_commas "$AU_JC0") tokens."
  if [ "$AU_JK" = build ]; then
    au_say "  After       build $AU_JPICK${file:+ ($file)}, $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens,"
  else
    au_say "  After       the same build, $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens,"
  fi
  au_say "              holding $(au_memory "$AU_JALL") of this Mac's $(au_memory $((AU_JMEM / 1048576))) of memory, $(au_memory "$AU_JGPU") of it on the GPU."
  if [ "$AU_MODE" = people ]; then au_say "  People      $AU_JP people at a time, as asked, in place of $AU_JP0."
  elif [ "$AU_JP" = "$AU_JP0" ]; then au_say "  People      The household's number of people, $AU_JP, is kept."
  else au_say "  People      The recipe now allows at most $AU_JP people at a time, so the household's $AU_JP0 is lowered to $AU_JP."; fi
  if [ "$AU_JK" = setting ]; then
    au_say "  Download    Nothing: it is the build this Mac serves, with its files already here."
  elif [ "$AU_JDL" = 0 ]; then
    au_say "  Download    Nothing: the files it needs are already on this Mac."
  else
    m_sha=$(au_build_field "$AU_JPICK" 30) e_sha=$(au_build_field "$AU_JPICK" 23)
    [ -f "$AU_DATA/store/$m_sha" ] || parts="$file from Hugging Face ($repo)"
    [ -f "$AU_DATA/store/$e_sha" ] || parts+="${parts:+, and }the engine $(au_build_field "$AU_JPICK" 20) from GitHub"
    au_say "  Download    $(au_bytes "$AU_JDL")${parts:+: $parts}."
  fi
  for l in ${AU_JREMOVE[@]+"${AU_JREMOVE[@]}"}; do
    au_split "$l"
    n=$((n + 1))
    [ "$n" != 1 ] || au_say "  Removed     To make room, these earlier builds are removed, and they stay removed if the download then fails:"
    case "${AU_F[2]:-}" in
      failed) au_say "              build ${AU_F[4]:-}, which failed its test here on ${AU_F[3]%%T*};" ;;
      *) if [ "${AU_F[5]:-}" = yes ]; then
           au_say "              build ${AU_F[4]:-}, kept since ${AU_F[3]%%T*}: the one before the build in use, so \`auster rollback\` could no longer go back to it;"
         else au_say "              build ${AU_F[4]:-}, kept since ${AU_F[3]%%T*};"; fi ;;
    esac
  done
  if [ "$AU_JK" = setting ]; then
    au_say "  Switch      Nothing is fetched or tested: the server restarts once on the new setting, and does not answer for a few seconds."
  elif [ "$AU_JWAY" = side-by-side ]; then
    au_say "  Switch      This Mac can hold both builds at once: the new one is tested beside the one serving, which keeps answering"
    au_say "              (a test that fails restarts it: a few seconds without answers). The server then restarts once on the new"
    au_say "              build and does not answer for a few seconds, up to about 15 s when the model is read from disk."
  else
    au_say "  Switch      This Mac cannot hold both builds at once: the server does not answer while the new build is tested,"
    au_say "              up to about 3 minutes, and then restarts on it."
  fi
  [ "$AU_JWD" = - ] || au_say "  Withdrawn   The build it serves now has been withdrawn."
  if [ "$AU_PROGRAMS_CHANGE" = 1 ]; then
    au_say "  Programs    Auster's own programs change too (${AU_FROM:+from $AU_FROM }to $AU_VERSION): they are put in place first, before"
    au_say "              anything is downloaded, and the server restarts once to check them."
  elif [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; then
    au_say "  Programs    Auster's own programs were changed by an earlier update and never checked: the server restarts"
    au_say "              once to check them first."
  fi
  au_say ""
  if [ "$AU_MODE" = people ]; then
    au_yes "Change ${AU_JLABEL:-this recipe} to $AU_JP people at a time now?" && return 0
    au_say "Nothing was changed."
    return 1
  fi
  au_yes "Update ${AU_JLABEL:-this recipe} now?" && return 0
  if [ "$AU_JK" = build ]; then
    au_say "Nothing was changed: build $AU_JPICK stays waiting, and \`auster update\` offers it again."
  else
    au_say "Nothing was changed: the setting stays as it is, and \`auster update\` offers the change again."
  fi
  return 1
}

au_update_programs_question() { # -> 0 on a yes, 1 on a no: Auster's own programs change and no recipe does (B3 step 6)
  au_say ""
  au_say "Auster's own programs change (${AU_FROM:+from $AU_FROM }to $AU_VERSION), and every recipe on this Mac serves what it should."
  au_say "  Programs    They are put in place, and the server restarts once to check them: a few seconds without answers."
  au_say ""
  au_yes "Update Auster's programs now?" && return 0
  au_say "Nothing was changed, and \`auster update\` offers this again."
  return 1
}

au_update_yes() { # [RECIPE] -> what follows a yes (B3 steps 6 to 13, D3.6), for the recipe au_update_judge judged a change,
  # or with none for Auster's programs alone: the programs first (au_update_programs), then `mac` (au_update_mac), then a
  # change of setting switched (au_switch_setting). It returns once all of that has passed; the run then goes on to the
  # server check of every recipe that needs one and to step 15. Open or not answered end the run with exit 4 on the way
  if [ -n "${1:-}" ] && [ "$AU_JK" = build ]; then   # TODO(U5): the second half: D3.6 steps 1 and 3 to 5 for a new build
    au_undo
    if [ "$AU_CHANGED" = 0 ]; then au_say "Making this change comes with a later version of Auster (U5), so nothing was changed."
    else au_say "Moving to another build comes with a later version of Auster (U5), so $AU_JNAME keeps serving build $AU_JNOW."; fi
    exit 3
  fi
  au_update_programs
  au_update_mac
  [ -z "${1:-}" ] || au_switch_setting "$1"
}

au_update_programs() { # -> B3 step 6 after the yes (BD18, T94), once a run, before anything else changes or is fetched, on the
  # build already serving. When Auster's own programs change: the new bin/auster answers `status` once from its temporary
  # name, or nothing is renamed and the run ends with exit 3; the programs in use are copied into jobs/previous/, unless it
  # exists (an earlier change never checked: nothing is copied over it); the new ones are put in place by rename. Then,
  # and also when jobs/previous/ is there with the programs unchanged, the engine is restarted and the server checked
  # (step 13): passed deletes jobs/previous/ and the update goes on; open and not answered end the run with exit 4,
  # naming `auster rollback`, which puts the previous programs back. Nothing is put back by itself
  local p d t prev="$AU_DATA/jobs/previous" r
  [ "$AU_PROGRAMS_DONE" = 0 ] || return 0
  AU_PROGRAMS_DONE=1
  if [ "$AU_PROGRAMS_CHANGE" = 1 ]; then
    au_say "Putting Auster's own programs of $AU_VERSION in place, on the build this Mac serves..."
    t="$AU_DATA/bin/.auster.new.$$"
    rm -f "$t"
    cp "$AU_TREE/common/auster" "$t" && chmod 755 "$t" ||
      { rm -f "$t"; au_stop "The new auster command could not be written, so none of Auster's programs was changed."; }
    if ! au_limited 60 "$AU_RUN/trial.out" /bin/bash "$t" status; then
      rm -f "$t"
      au_say "The auster command of $AU_VERSION did not answer \`auster status\` on this Mac, so none of Auster's programs was changed, and nothing else was either."
      exit 3
    fi
    if [ ! -e "$prev" ] && [ ! -L "$prev" ]; then
      d="$AU_DATA/jobs/.previous.new.$$"
      rm -rf "$d"
      au_mkdir "$d" || au_stop "The programs in use could not be kept (jobs/previous), so none was changed."
      for p in $AU_PROGRAMS; do
        p=$(printf '%s' "$p" | cut -d: -f2)
        [ -f "$AU_DATA/$p" ] && [ ! -L "$AU_DATA/$p" ] || continue
        cp -p "$AU_DATA/$p" "$d/${p##*/}" || { rm -rf "$d"; au_stop "The programs in use could not be kept (jobs/previous), so none was changed."; }
      done
      mv "$d" "$prev" || { rm -rf "$d"; au_stop "The programs in use could not be kept (jobs/previous), so none was changed."; }
    else
      au_say "jobs/previous already holds the programs from before an earlier change that was never checked, so nothing is copied over it."
    fi
    AU_CHANGED=1
    mv -f "$t" "$AU_DATA/bin/auster" || au_stop "bin/auster could not be put in place. \`auster rollback\` puts the previous programs back."
    for p in $AU_PROGRAMS; do
      d=$(printf '%s' "$p" | cut -d: -f2)
      [ "$d" != bin/auster ] || continue
      au_put "$AU_TREE/${p%%:*}" "$AU_DATA/$d" "${p##*:}" ||
        au_stop "$d could not be put in place. \`auster rollback\` puts the previous programs back."
    done
    au_say "Auster's programs of $AU_VERSION are in place. The server restarts once on the build it serves, to check them..."
  elif [ -e "$prev" ] || [ -L "$prev" ]; then
    au_say "Auster's own programs were changed by an earlier update whose server check never passed (jobs/previous holds the ones before)."
    au_say "The server restarts once to check them, before anything else changes..."
  else
    return 0
  fi
  if ! au_engine_start; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_programs_failed
  fi
  for r in "${AU_URECIPES[@]}"; do
    au_serving_read "$r" || continue
    au_server_check "$r" "$AU_T0"
    case "$AU_CHECK" in
      passed) au_say "The server answered, at $AU_CHECK_SPEED tokens a second, and refused a request with no key: Auster's programs pass." ;;
      open)
        au_say "The server did not refuse a request that carried no key, so Auster stopped it. It stays stopped until \`auster rollback\` or \`auster start\`."
        au_programs_failed ;;
      *)
        au_say "The server did not answer its check within $AU_CHECK_SECS s: $AU_CHECK_WHY."
        au_programs_failed ;;
    esac
  done
}

au_programs_failed() { # -> after Auster's programs failed their server check (B3 step 6): the way back, then exit 4 with no stamp
  au_say "Only Auster's own programs changed, on the build it served, so the fault is theirs. Nothing is put back by itself:"
  au_say "\`auster rollback\` puts the previous programs back and starts the server again, with no download."
  exit 4
}

au_update_mac() { # -> builds/mac written once, after the yes and once Auster's programs pass (C1, U2's row of the as-built
  # table): the GPU limit and memory section C used at step 4, the macOS version and the time, with the router and
  # keep-awake of the record it replaces, since only a first install and `auster network` record the router (T100). Left
  # as it is when it cannot be read (there is no router to keep) or when its own GPU limit was used (the engine in
  # engines/ was not intact, so nothing was measured)
  local v
  [ "$AU_MAC_DONE" = 0 ] || return 0
  AU_MAC_DONE=1
  au_mac_read
  [ "$AU_MAC" = ok ] && [ "$AU_JGPUFROM" != mac ] && [[ $AU_JGPUL =~ ^[1-9][0-9]{0,6}$ ]] && [ "$AU_JGPUL" -le 1048576 ] &&
    [[ ${AU_JMEM:-} =~ ^[1-9][0-9]{0,14}$ ]] || return 0
  v=$(sw_vers -productVersion 2>/dev/null)
  [[ $v =~ ^[1-9][0-9]?\.(0|[1-9][0-9]?)(\.(0|[1-9][0-9]?))?$ ]] || return 0
  AU_GPU_LIMIT=$AU_JGPUL AU_MEMORY=$AU_JMEM AU_MACOS=$v AU_ROUTER=$AU_MAC_ROUTER AU_AWAKE=${AU_MAC_LINES[6]#keep-awake"$AU_T"}
  au_mac_write || au_stop "This Mac's figures could not be written."
  AU_CHANGED=1
}

au_switch_setting() { # RECIPE -> D3.6, a change of setting, the update's and `auster people`'s alike (B6): nothing fetched or
  # tested; the old descriptor copied into kept/ first (au_kept_add), then serving replaced by rename (au_descriptor, as
  # step 12 writes it) for the same build at AU_JP people and AU_JC tokens each, with a speed of 0 (A5), so that a run
  # killed between the two writes leaves the old setting a descriptor; then the engine restarted on it as `auster start`
  # starts it, and the server check (B3 step 13). Passed returns; open and not answered end the run with exit 4, naming
  # `auster rollback`, which goes back with no download. Nothing switches back by itself, and nothing goes in failed/
  local r=$1
  au_say "Switching to $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens, on build $AU_JPICK..."
  au_kept_add "$r" || au_stop "What it serves now could not be kept (builds/$r/kept), so the setting was not changed."
  AU_CHANGED=1
  AU_CH_BUILD=$AU_JPICK AU_PEOPLE=$AU_JP AU_CONTEXT=$AU_JC AU_PORT=$AU_SV_PORT AU_LISTSHA=$AU_SV_LIST
  au_descriptor "$AU_DATA/builds/$r/serving" 0 || au_stop "The record of what serves (builds/$r/serving) could not be written."
  if ! au_engine_start; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_say "Nothing switches back by itself: \`auster rollback\` goes back to what it served before, with no download."
    exit 4
  fi
  au_say "Checking the server on the home network..."
  au_server_check "$r" "$AU_T0"
  case "$AU_CHECK" in
    passed) au_say "The server answered, at $AU_CHECK_SPEED tokens a second, and refused a request with no key." ;;
    open)
      au_say "The server did not refuse a request that carried no key, so Auster stopped it. It stays stopped until \`auster rollback\` or \`auster start\`."
      au_say "Nothing switches back by itself: \`auster rollback\` goes back to what it served before and starts it, with no download."
      exit 4 ;;
    *)
      au_say "The server did not answer its check within $AU_CHECK_SECS s: $AU_CHECK_WHY. \`auster status\` says how the engine's last start went."
      au_say "Nothing switches back by itself: \`auster rollback\` goes back to what it served before, with no download."
      exit 4 ;;
  esac
}

au_update_check() { # B3 step 13 before step 15, on a run that changed nothing or after its changes passed: a recipe whose serving
  # has a speed of 0 has not passed a server check since its switch (A5), and jobs/previous/ means that Auster's programs
  # have not passed one since an update changed them (B3 step 6, T94); either way the engine is started again, as `auster
  # start` starts it, and checked before step 15 writes the stamp. Passed goes on (and deletes jobs/previous/); open and
  # not answered end the run with exit 4 and no stamp
  local r need=() prev=0
  if [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; then prev=1; fi
  for r in "${AU_URECIPES[@]}"; do au_serving_read "$r" && { [ "$AU_SV_SPEED" = 0 ] || [ "$prev" = 1 ]; } && need+=("$r"); done
  [ "${#need[@]}" -gt 0 ] || return 0
  if [ "$prev" = 1 ]; then
    au_say "Auster's own programs were changed by an earlier update whose server check never passed (jobs/previous holds the ones before), so the server is started again and checked on the home network before anything else..."
  else
    au_say "The server has not passed a check since its build was last switched, so it is started again and checked on the home network..."
  fi
  if ! au_engine_start; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_update_unfinished "${need[0]}"
    exit 4
  fi
  for r in "${need[@]}"; do
    au_server_check "$r" "$AU_T0"
    case "$AU_CHECK" in
      passed) au_say "The server answered, at $AU_CHECK_SPEED tokens a second, and refused a request with no key." ;;
      open)
        au_say "The server did not refuse a request that carried no key, so Auster stopped it. It stays stopped until \`auster start\`."
        au_update_unfinished "$r"
        exit 4 ;;
      *)
        au_say "The server did not answer its check within $AU_CHECK_SECS s: $AU_CHECK_WHY. \`auster status\` says how the engine's last start went."
        au_update_unfinished "$r"
        exit 4 ;;
    esac
  done
}

au_update_unfinished() { # RECIPE -> after a server check that failed, what is not done and the way on (B3 step 13)
  if [ "$AU_HAD_STAMP" = 0 ]; then
    au_say "The device keys are made but not shown, and the install is not finished: paste the line again to check again and finish, or remove it with: \"$AU_DATA/bin/auster\" remove"
  elif [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; then
    au_say "\`auster rollback\` puts Auster's previous programs back, with no download; pasting the line again checks again."
  elif [ -n "$(ls -A "$AU_DATA/builds/$1/kept" 2>/dev/null)" ]; then
    au_say "\`auster rollback\` goes back to what it served before, with no download; pasting the line again checks again."
  else
    au_say "Pasting the line again checks again."
  fi
}

au_update_keys() { # B3 step 14 for a run that finishes an install: with no stamp when the run began, the install that made the
  # devices' keys did not finish, and step 14 shows a key only after a passed check, just before the stamp; so each device's
  # key is shown now, after the check above (T65). A Mac whose _update was moved to the Trash shows them again
  local i
  au_key_list
  for ((i = 0; i < ${#AU_KEY_IDS[@]}; i++)); do
    au_say "The install is finished: the key for the device ${AU_KEY_NAMES[$i]} is shown now."
    au_qr_show "${AU_KEY_NAMES[$i]}" "${AU_KEY_IDS[$i]}" || true
  done
}

au_update_known() { # -> after a run that wrote a new stamp on the release line: _update/registry, notes.md and offer from this
  # tree, as a check that found this version writes them (D3.3: the registry, then notes.md, then offer, each by rename,
  # and only when the tree's changelog names the version its registry does), so that each recipe's line is judged at once
  # rather than `unknown` until the next check (the rule file uses no registry older than the scripts). An offer of a
  # later version is never lowered, and nothing is written for a named version, which is offered nothing
  local u="$AU_DATA/_update" cl="$AU_TREE/CHANGELOG.md" v t="$AU_DATA/_update/.offer.new.$$"
  [ "$AU_LINE" = release ] || return 0
  [ -f "$cl" ] && [ ! -L "$cl" ] && [ "$(au_size "$cl")" -le 1048576 ] || return 0
  v=$(sed -n -E 's/^## (v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})) \(.*/\1/p' "$cl" | head -n 1)
  [ "$v" = "$AU_VERSION" ] || return 0
  if au_line_read "$u/offer" 2 && [[ ${AU_LF[0]} =~ $AU_RE_VERSION ]] && au_later "${AU_LF[0]}" "$AU_VERSION"; then return 0; fi
  rm -f "$t"
  if ! { au_put "$AU_TREE/registry.tsv" "$u/registry" 600 && au_put "$cl" "$u/notes.md" 600 &&
         printf 'auster-record 1\t%s\t%s\n' "$AU_VERSION" "$(date +%s)" > "$t" && chmod 600 "$t" && mv -f "$t" "$u/offer"; }; then
    rm -f "$t"
    au_say "_update's registry and offer could not be written, so each recipe's line in \`auster status\` waits for the next check."
  fi
}

au_update() { # -> the update (D3.6; the comment above): exits. 0 done, or nothing needed changing; 1 refused or answered no,
  # and nothing changed; 3 a recipe passed over, a new bin/auster that does not answer `status`, or, until U5's second half,
  # a yes to a change of build; 4 the server check failed
  local s r no=0 short=0 asked=0 did=0
  au_refuse_stopped || au_refuse   # B6: while builds/stopped exists, whatever it holds, the update refuses
  AU_URECIPES=()
  for s in "$AU_DATA"/builds/r*/serving; do
    [ -e "$s" ] || [ -L "$s" ] || continue
    r=${s%/serving}; r=${r##*/}
    [[ $r =~ $AU_RE_RECIPE ]] && AU_URECIPES+=("$r")
  done
  [ "${#AU_URECIPES[@]}" -gt 0 ] ||
    au_refuse "Nothing serves on this Mac yet: its install stopped before its server. Paste the installer line from the guide to go on, or remove it with: \"$AU_DATA/bin/auster\" remove"
  AU_HAD_STAMP=0 AU_FROM=
  if au_line_read "$AU_DATA/_update/scripts" 4; then
    AU_HAD_STAMP=1
    [[ ${AU_LF[1]} =~ $AU_RE_VERSION ]] && AU_FROM=${AU_LF[1]}
  fi
  au_update_measure
  AU_PROGRAMS_CHANGE=0
  if au_programs_differ; then AU_PROGRAMS_CHANGE=1; fi
  for r in "${AU_URECIPES[@]}"; do
    au_update_judge "$r"
    case "$AU_J" in
      ok|held) au_say "$AU_J_SAY" ;;
      change) asked=1; if au_update_question; then au_update_yes "$r"; did=1; else no=1; fi ;;
      *) au_say "$AU_J_SAY"; short=1 ;;
    esac
  done
  if [ "$asked" = 0 ] && [ "$AU_PROGRAMS_CHANGE" = 1 ]; then
    if au_update_programs_question; then au_update_yes; did=1; else no=1; fi
  fi
  if [ "$no" = 1 ]; then
    if [ "$did" = 0 ]; then au_undo; exit 1; fi
    short=1   # another recipe's no: not everything was updated
  fi
  au_update_check
  [ "$AU_HAD_STAMP" = 1 ] || au_update_keys
  au_step15_stamp
  [ "$AU_STAMP_NEW" = 0 ] || au_update_known
  au_say ""
  if [ "$short" = 1 ]; then
    au_say "Auster $AU_VERSION is on this Mac, but not everything was updated: the lines above say why."
    exit 3
  fi
  if [ "$did" = 1 ]; then au_say "Auster $AU_VERSION is on this Mac, and the update is finished."; exit 0; fi
  au_say "Auster $AU_VERSION is on this Mac, and nothing else needed changing."
  exit 0
}

# --- `auster people <n>` (B6, C4; U5) -------------------------------------------------------------------------------------

au_people_judge() { # RECIPE -> AU_J: ok (its setting at AU_PEOPLE_N people is the one it serves), change (AU_JK setting, with
  # AU_JPICK the build served and the figures the question gives) or refused, with AU_J_SAY. Section C (capability.js) is
  # given this tree's registry for the recipe's limits, the build served only (--keep-build) at AU_PEOPLE_N people, the
  # figures of step 4, and no disk figures, since nothing is fetched (C6)
  local r=$1 l rc st def cf=()
  AU_J=refused AU_J_SAY= AU_JK= AU_JREMOVE=() AU_JNAME="This Mac's recipe" AU_JLABEL= AU_JWD=- AU_JDL=0
  AU_REGOUT="$AU_RUN/registry-$r.out"
  osascript -l JavaScript "$AU_TREE/common/registry.js" "$AU_REG" "$r" > "$AU_REGOUT" 2>/dev/null
  l=$(awk -F'\t' '$1 == "recipe"' "$AU_REGOUT"); au_split "$l"
  if [[ ${AU_F[4]:-} =~ ^[a-z][a-z0-9-]{1,40}$ ]]; then AU_JLABEL=${AU_F[4]} AU_JNAME="The recipe ${AU_F[4]}"; fi
  st=${AU_F[2]:-} def=${AU_F[6]:-}
  if ! au_serving_read "$r"; then
    AU_J_SAY="$AU_JNAME: what it serves (builds/$r/serving) cannot be read, so nothing was changed."
    return 0
  fi
  AU_JNOW=$AU_SV_BUILD AU_JNOWFILE=$AU_SV_MODEL_FILE AU_JP0=$AU_SV_PEOPLE AU_JC0=$AU_SV_CONTEXT
  if ! [[ $st =~ ^(ok|none)$ ]] || ! [[ $def =~ ^[1-9][0-9]?$ ]]; then
    AU_J_SAY="$AU_JNAME cannot be read from the registry of Auster $AU_VERSION, so nothing was changed."
    return 0
  fi
  if [ "$AU_PEOPLE_N" -gt "$def" ]; then
    AU_J_SAY="$AU_JNAME serves from 1 to $def people at a time, so nothing was changed."
    return 0
  fi
  env -u AU_DISK_FREE_BYTES -u AU_DISK_TOTAL_BYTES osascript -l JavaScript "$AU_TREE/common/capability.js" "$AU_REG" "$r" \
    --serving "$AU_JNOW" --keep-build --people "$AU_PEOPLE_N" "${AU_FIGURES[@]}" > "$AU_RUN/choice-$r.out" 2>/dev/null
  rc=$?
  while IFS= read -r l; do
    au_split "$l"
    case "${AU_F[0]}" in
      figures) AU_JMEM=${AU_F[2]:--} ;;
      choice) cf=("${AU_F[@]}") ;;
      refused) AU_J_SAY=${AU_F[1]:-} ;;
    esac
  done < "$AU_RUN/choice-$r.out"
  [[ ${AU_JMEM:-} =~ ^[1-9][0-9]{0,14}$ ]] || AU_JMEM=$AU_RAM
  if [ "$rc" != 0 ] || [ "${#cf[@]}" -lt 8 ]; then
    case "$AU_J_SAY" in
      fit) AU_J_SAY="$AU_JNAME: build $AU_JNOW does not fit this Mac for $AU_PEOPLE_N people at a time, so nothing was changed." ;;
      serving) AU_J_SAY="$AU_JNAME: build $AU_JNOW is not in the registry of Auster $AU_VERSION, so nothing was changed." ;;
      *) AU_J_SAY="$AU_JNAME: section C gave no setting for $AU_PEOPLE_N people at a time, so nothing was changed." ;;
    esac
    return 0
  fi
  AU_JPICK=${cf[1]} AU_JP=${cf[2]} AU_JC=${cf[3]} AU_JGPU=${cf[4]} AU_JALL=${cf[5]} AU_JWAY=${cf[6]}
  if [ "$AU_JPICK" = "$AU_JNOW" ] && [ "$AU_JP" = "$AU_JP0" ] && [ "$AU_JC" = "$AU_JC0" ]; then
    AU_J=ok AU_J_SAY="$AU_JNAME: OK. Build $AU_JNOW already serves it for $AU_JP0 people at $(au_commas "$AU_JC0") tokens each, so nothing changes."
    return 0
  fi
  AU_J=change AU_JK=setting
}

au_people() { # -> `auster people <n>` (B6, C4; T112), run by release's install.sh with `people <n>` and so from release's newest
  # tree: the update's procedure for the build each recipe serves, at AU_PEOPLE_N people. This tree's registry gives the
  # recipe's limits (1 to its default), and section C the largest context per person that fits (C4), for the build served
  # only. A setting that would change goes to the question (au_update_question), and on a yes it is the update's switch
  # (au_switch_setting), after the server check that jobs/previous/ calls for, made first as an update makes it
  # (au_update_programs, which changes no program here). No other build is chosen, nothing is downloaded or tested, none
  # of Auster's programs is changed, and no stamp and no `mac` are written, even when this tree is of a newer version
  # (B6). Exits: 0 done, or nothing to
  # change; 1 refused or answered no, and nothing changed; 3 a recipe not changed while another was; 4 the server check
  local s r no=0 short=0 did=0
  au_refuse_stopped || au_refuse
  AU_URECIPES=()
  for s in "$AU_DATA"/builds/r*/serving; do
    [ -e "$s" ] || [ -L "$s" ] || continue
    r=${s%/serving}; r=${r##*/}
    [[ $r =~ $AU_RE_RECIPE ]] && AU_URECIPES+=("$r")
  done
  [ "${#AU_URECIPES[@]}" -gt 0 ] ||
    au_refuse "Nothing serves on this Mac yet: its install stopped before its server. Paste the installer line from the guide to go on."
  au_update_measure
  for r in "${AU_URECIPES[@]}"; do
    au_people_judge "$r"
    case "$AU_J" in
      ok) au_say "$AU_J_SAY" ;;
      change) if au_update_question; then au_update_programs; au_switch_setting "$r"; did=1; else no=1; fi ;;
      *) au_say "$AU_J_SAY"; short=1 ;;
    esac
  done
  if [ "$did" = 0 ]; then
    [ "$no" = 0 ] && [ "$short" = 0 ] && exit 0
    au_undo
    exit 1
  fi
  [ "$no" = 0 ] && [ "$short" = 0 ] || exit 3
  au_say ""
  au_say "This Mac now serves $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens."
  exit 0
}

# --- the run ---------------------------------------------------------------------------------------------

au_args() {
  AU_MODE=${1:-}
  [ $# -gt 0 ] && shift
  case "$AU_MODE" in
    install|check) AU_RECIPE=${1:-}; [[ $AU_RECIPE =~ $AU_RE_RECIPE ]] || au_usage; shift ;;
    update|remove) AU_RECIPE= ;;
    people) AU_RECIPE= AU_PEOPLE_N=${1:-}; [[ $AU_PEOPLE_N =~ ^[1-9][0-9]?$ ]] || au_usage; shift ;;
    *) au_usage ;;
  esac
  AU_COMMIT= AU_LINE= AU_VERSION=
  while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || au_usage
    case "$1" in
      --commit) [[ $2 =~ $AU_RE_COMMIT ]] || au_usage; AU_COMMIT=$2 ;;
      --line) case "$2" in release|tag) AU_LINE=$2 ;; *) au_usage ;; esac ;;
      --version) [[ $2 =~ $AU_RE_VERSION ]] || au_usage; AU_VERSION=$2 ;;
      --withdrawals) [ -f "$2" ] && [ "$AU_MODE" != update ] || au_usage; AU_WITHDRAWALS=$2 ;;
      *) au_usage ;;
    esac
    shift 2
  done
  [ -n "$AU_COMMIT" ] && [ -n "$AU_LINE" ] && [ -n "$AU_VERSION" ] || au_usage
  [ "$AU_LINE" = tag ] || [ -z "$AU_WITHDRAWALS" ] || au_usage
  [ "$AU_MODE" != update ] || [ "$AU_LINE" = release ] || au_usage   # an update follows release (D3.6)
  [ "$AU_MODE" != people ] || [ "$AU_LINE" = release ] || au_usage   # and so does `people` (B6)
}

au_main() {
  au_args "$@"
  au_identity || exit 1
  AU_HOME_DATA=$AU_DATA
  case "$AU_MODE" in
    remove) au_remove; exit $? ;;   # B8, for an install that stopped before bin/auster was written
  esac
  AU_RUN=$(mktemp -d "${TMPDIR:-/tmp}/auster-run.XXXXXX") || exit 1
  trap au_cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  [ "$AU_MODE" != check ] || AU_DATA="$AU_RUN/data"   # --check: every step in a temporary folder (B2)
  au_root_check "$AU_HOME_DATA" || exit 1   # before anything is read from it or written (D3.1)
  if [ "$AU_MODE" = update ]; then   # D3.6, from `auster update` (install.sh update)
    [ "$AU_ROOT_NEW" = 0 ] || au_refuse "Auster is not installed on this Mac, so there is nothing to update. To install it, paste the installer line from the guide."
    AU_REG="$AU_TREE/registry.tsv"   # D3.6: every size and sha256 from this tree's registry, never _update's copy
    au_step3_root
    au_update
  fi
  if [ "$AU_MODE" = people ]; then   # B6, from `auster people <n>` (install.sh people <n>)
    [ "$AU_ROOT_NEW" = 0 ] || au_refuse "Auster is not installed on this Mac, so there is no number of people to change."
    AU_REG="$AU_TREE/registry.tsv"   # the recipe's limits from this tree's registry (B6)
    au_step3_root
    au_people
  fi
  au_registry
  au_bd14
  au_step3_root
  if [ -e "$AU_DATA/builds/$AU_RECIPE/serving" ] || [ -L "$AU_DATA/builds/$AU_RECIPE/serving" ]; then
    au_update   # a second paste on a Mac that serves the recipe is the update (B3, T65)
  fi
  au_step3_programs
  au_step4_measure
  au_step5_choose
  if [ "$AU_MODE" = check ]; then
    au_say "With --check nothing is asked and nothing is installed. The question would say:"
    au_facts
    au_say "--check: this Mac can install $AU_LABEL. Nothing was changed."
    exit 0
  fi
  au_step6_question
  au_step7_model
  au_step8_assets
  au_step9_engine
  au_step10_test
  au_step11_keys
  au_step12_switch
  au_step13_check
  au_step14_show
  au_step15_stamp
  au_say ""
  if [ -n "$AU_HOSTNAME" ]; then
    au_say "Auster is installed. On a device on the home network, open http://$AU_HOSTNAME.local:$AU_PORT/"
  else
    au_say "Auster is installed. On a device on the home network, open http://$AU_ADDR:$AU_PORT/"
  fi
  exit 0
}

au_main "$@"
