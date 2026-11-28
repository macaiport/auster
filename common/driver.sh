#!/bin/bash
# The driver (docs/plans/v0.1.md, B3): one procedure for installing and updating, run by install.sh from
# the tree of the commit it fixed, never from anywhere else (install.sh's header gives the contract):
#
#   /bin/bash <tree>/common/driver.sh install|check <recipe id> --commit C --line release|tag --version V [--withdrawals FILE]
#   /bin/bash <tree>/common/driver.sh update|remove --commit C --line release --version V
#   /bin/bash <tree>/common/driver.sh people <n> --commit C --line release --version V   (U5: `auster people <n>`)
#   /bin/bash <tree>/common/driver.sh update --retry --commit C --line release --version V   (U5: `auster update --retry`)
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
# the same switch for `auster people <n>` (T94, T100, T107, T109, T111, T112). U5, its middle part (2026-11-27): a change
# of build's pre-checks before the question, the candidate engine's macOS floor and the publisher's HEAD for each file
# store/ does not hold (au_update_ask); and after the yes, once the programs and `mac` are done, the download
# (au_update_build): room worked out again, the earlier builds the question named removed, then the first install's
# steps 7 to 9, which on an update stop the recipe (exit 3) rather than the run (au_fail); and `update --retry`, which
# offers a build in failed/ again (D3.7, BD12; T8, T10, T15, T29, T52, T99, T103, T110). U5, its last part (2026-11-27):
# the isolated test and both ways of switching (au_update_test, D3.6 steps 4 and 5): fit worked out again, the candidate
# started by the update itself (au_candidate_test, which step 10 shares), side by side or in turn with builds/paused,
# failed/, the switch to the new build, the engine run again after a pass and after a fail alike, and the server check
# (au_switch_check, which a change of setting shares); a retried build leaves failed/ on a pass (T9, T16, T24, T25, T28,
# T31 to T33, T55, T60, T94, T99, T109, T115).
# U6, its second part (2026-11-27): the disk holdings and the removal of the earlier builds the disk rule names are
# common/auster's (au_holdings, au_builds_remove), which `auster cleanup` shares; the update no longer sources the rule file
# (T7, T10, T17, T30).
# U6, its third part (2026-11-28): a changed file of the build in use is fetched again (D3.6, "A changed file of the
# build in use is fetched again"; BD18). Before the question every run checks the files of the build its one recipe
# serves (au_update_files); one that is changed or missing makes the recipe a repair, whatever else the run does with
# it, taken from serving's own lines (au_repair_report) and checked before the question as any download is
# (au_repair_ask). After the yes the repair comes first (au_repair: steps 7 to 9, no test, serving not rewritten), then
# Auster's programs, then `mac`, then a change of setting or of build; its server check is the first the run makes after
# it. A repair passed over, declined or failed restarts nothing, checks nothing, changes no program and ends the run
# with no step 15 (au_repair_end). A second paste checks the server while the engine job's last start is engine-hash;
# `auster people` refuses while a file the engine job checks has changed (T117, T118; T33, T94 and T112 point there).
# Backups (2026-11-28, docs/plans/backup.md): at the end of step 3, after the lock and after the refusal of a newer
# version's records, every run that reaches it asks Time Machine to leave out store/ and engines/, which can be fetched
# again, in one call to tmutil whose output, which names the data root, is never shown; `--check`, whose data root is a
# temporary one, asks nothing. AU_TM records ok or failed and nothing stops on it: the install's question says which in
# its Backups line, and an update, a second paste or `people` says it once, straight after step 3, when it failed. A Mac
# restored from a backup lacks both folders; step 3 makes them again and the repair above fetches their files (T135).
# The conventions' audit (2026-11-28, docs/conventions.md sections 1 and 2): au_cleanup also deletes the server check's
# folder, which holds a household key (common/auster's au_tmp; T136); curl's numbers in plain words (au_fetch_said, and the
# publisher's code matched; T138, T139); macOS's version, the engine's oldest macOS, section C's codes and the name of a folder
# in builds/ each matched or put in fixed words before a sentence names them (T102, T140, T141).
#
# builds/paused (D3.1, B4 step 1): one line, `auster-record 1`, the process, the boot session and the process's start time,
# as the lock names this run; written by rename just before an update in turn stops the engine for its test, and removed
# once the switch is written (au_paused_take, au_paused_release, and au_cleanup when the run ends otherwise).
#
# jobs/previous/ (B3 step 6): the programs in use before an update changed them, each of AU_PROGRAMS under the last part
# of its path in the data root (auster, auster-engine, auster-check, registry-lib.js, capability-lib.js, capability.js,
# registry.js, mint-id) with its mode; a folder of mode 0700, made whole under another name and renamed. It exists from
# just before the new programs are renamed into place until a server check passes (au_server_check deletes it), or until
# `auster rollback` puts them back from it and deletes it (common/auster, au_rollback_programs).
#
# Exit codes (B3): 0 done; 1 refused or answered no, and nothing of this run is left; 2 usage; 3 not
# everything was updated (D3.6: a recipe passed over, before its question, at its download or before its test; a new
# build that failed its test; a new bin/auster that does not answer `status`); 4 the server is down; 5 stopped after
# writing: what is left is listed, and `auster remove` removes it. Before the yes every stop is 1 and removes what this run
# created; after it, at an install, every stop but 4 is 5 and keeps what was written, so that pasting the line again goes
# on from there; on an update a download that fails stops its recipe only (3), and keeps a model cut short
# (store/<sha256>.part) for a resume.
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

AU_AWAKE=no AU_DEVICE= AU_LOCKED=0 AU_ROOT_NEW=0 AU_MADE_ROOT=0 AU_CANDIDATE= AU_CANDIDATE_WATCH= AU_CREATED=()
AU_FETCH_SECS=0 AU_FETCH_BYTES=0 AU_WITHDRAWALS= AU_MEASURED_ENGINE=
AU_PROGRAMS_CHANGE=0 AU_PROGRAMS_DONE=0 AU_MAC_DONE=0 AU_CHANGED=0 AU_JGPUL= AU_JGPUFROM=
AU_UPDATING=0 AU_RETRY=0 AU_JFAILED= AU_PAUSED=0
AU_RP= AU_RP_RECIPE= AU_RP_BAD=0 AU_RP_DONE=0 AU_RP_WAIT= AU_REPAIRING=0 AU_PROGRAMS_IN=0 AU_JMOVEOFF=0   # the repair (D3.6; U6)
AU_TM=   # ok or failed: whether Time Machine was told to leave out store/ and engines/ (step 3; docs/plans/backup.md)

au_usage() {
  { au_say "usage: driver.sh install|check <recipe id> --commit C --line release|tag --version V [--withdrawals FILE]"
    au_say "       driver.sh update [--retry] --commit C --line release --version V"
    au_say "       driver.sh remove --commit C --line release --version V"
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

au_fail() { # SENTENCE -> after the yes, a step of the files (B3 steps 7 to 9) that failed: at an install, exit 5 with what
  # is left (au_stop); on an update, the sentence said and 1, so that this recipe stops and keeps serving its build, and
  # the other recipes go on (D3.6 step 3: exit 3 at the end)
  if [ "$AU_UPDATING" = 1 ]; then au_say "$1"; return 1; fi
  au_stop "$1"
}

au_cleanup() {
  au_qr_leave
  au_candidate_stop
  au_paused_release
  au_lock_release
  rm -rf "$AU_RUN"
  au_tmp_clean   # the server check's folder, which holds a household key (common/auster's au_tmp; T136)
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

au_bd14() { # -> refuses when the Mac already serves another recipe (BD14), before anything is written. A folder whose
  # name is not a recipe id (AU_RE_RECIPE, as au_recipe_pick matches it) serves no recipe, and is never named (T140)
  local s r
  for s in "$AU_HOME_DATA"/builds/r*/serving; do
    [ -e "$s" ] || [ -L "$s" ] || continue
    r=${s%/serving}; r=${r##*/}
    [[ $r =~ $AU_RE_RECIPE ]] || continue
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
  # the same for an install and an update, which writes no program here (au_step3_programs is a first install's). Last,
  # AU_TM: Time Machine asked to leave out store/ and engines/ (docs/plans/backup.md, sections 1 and 4; T135), after the
  # lock and the refusal of newer records, so that a run refused for either changes nothing, and once both folders
  # exist, whether this run made them or not (tmutil refuses a folder that does not exist, exit 162). Asked at every
  # run, since asking again for a folder already left out is harmless, so a Mac installed before this, and a Mac
  # restored from a backup, which has neither folder, get it at their next run. tmutil's own output names the data root
  # and is never shown; a failure stops nothing (au_facts and au_tm_said say it). `--check` asks nothing, its data root
  # being a temporary one, and its question says what an install would
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
  if [ "$AU_MODE" = check ]; then AU_TM=ok
  elif tmutil addexclusion "$AU_DATA/store" "$AU_DATA/engines" > /dev/null 2>&1; then AU_TM=ok
  else AU_TM=failed; fi
}

au_tm_said() { # -> section 4's sentence of docs/plans/backup.md, once, straight after step 3 at an update, a second paste
  # or `people`, when Time Machine could not be told to leave out store/ and engines/ (AU_TM); an install's question says
  # it in its Backups line instead (au_facts), and an update's question does not repeat it (T135)
  [ "$AU_TM" != failed ] || au_say "Time Machine could not be told to leave out the model and the engine, so it may back them up."
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

au_engine_whole() { # ENGINE-DIR LIST-SHA -> 0 when its files pass the check the engine job makes at every start (B4
  # step 4, common/auster-engine): their list, made again, has the sha256 LIST-SHA (serving's launch line), and its one
  # program named llama-server is executable; whatever engines/<sha256>/files says (D3.6, "The check")
  local l p out
  [ -d "$1/root" ] && [ ! -L "$1/root" ] || return 1
  l=$(au_list "$1/root") && [ -n "$l" ] || return 1
  out=$(printf '%s\n' "$l" | openssl dgst -sha256 2>/dev/null); out=${out##*= }
  [ "$out" = "$2" ] || return 1
  p=$(printf '%s\n' "$l" | awk -F'\t' '$2 != "link" && ($1 == "llama-server" || $1 ~ /\/llama-server$/) { print $1 }')
  [ -n "$p" ] && [ "$(printf '%s\n' "$p" | wc -l | tr -d ' ')" = 1 ] && [ -x "$1/root/$p" ]
}

# --- step 4: measuring the Mac ------------------------------------------------------------------------

au_step4_measure() {
  local first e_nb e_file e_size e_sha e_mac major got secs dir prog
  first=$(awk -F'\t' '$1 == "build" { print $5; exit }' "$AU_REGOUT")
  e_nb=$(au_build_field "$first" 20); e_file=$(au_build_field "$first" 21)
  e_size=$(au_build_field "$first" 22); e_sha=$(au_build_field "$first" 23); e_mac=$(au_build_field "$first" 24)
  AU_MACOS=$(sw_vers -productVersion 2>/dev/null)
  [[ $AU_MACOS =~ $AU_RE_MACOS ]] ||   # matched whole before a sentence names it, as install.sh does (T140)
    au_refuse "Auster cannot tell which version of macOS this Mac has, so nothing was installed."
  [[ $e_mac =~ ^[1-9]?[0-9]$ ]] ||
    au_refuse "The registry of this version does not say which macOS the recipe's engine needs, so nothing was installed."
  major=${AU_MACOS%%.*}
  [ "$major" -ge "$e_mac" ] ||
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
      au_refuse "The engine could not be fetched from GitHub ($(au_fetch_said "$got" "$AU_CODE")). Check the network, then paste the line again."
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
  local l why detail say
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
    figures)   # capability.js's codes, each in fixed words, never printed as they came (T102)
      case "$detail" in
        gpu,*)
          case "${detail#gpu,}" in
            no-mtl0) say=": it names no GPU (MTL0)" ;;
            mtl0-form) say=": its line for the GPU (MTL0) is in another form" ;;
            mtl0-twice) say=": it names the GPU (MTL0) twice" ;;
            mtl0-figure) say=": its figure for the GPU's memory is out of range" ;;
            not-list-devices) say=": it is not a list of devices" ;;
            too-large) say=": it is longer than Auster reads" ;;
            *) say= ;;
          esac
          au_refuse "The engine's report of this Mac's GPU (llama-server --list-devices) is not in the form Auster reads$say. No limit is guessed, so nothing was installed." ;;
        mac,*) au_refuse "This Mac's figures were written by a newer version of Auster. Paste the installer line from the guide, or remove Auster first." ;;
        memory,*) au_refuse "This Mac's memory cannot be read, so nothing was installed." ;;
        disk,*) au_refuse "The free space on this Mac's disk cannot be read (df -k), so nothing was installed." ;;
        *) au_refuse "This Mac's figures cannot be read, so nothing was installed." ;;
      esac ;;
    none) au_refuse "None of this recipe's builds can be used on this Mac ($(au_reason_words "$detail")), so nothing was installed." ;;
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

au_facts() { # -> what the question says (B3 step 6), in fixed words with this Mac's figures. Its Backups line says what
  # step 3 recorded (AU_TM; docs/plans/backup.md, sections 4 and 5): that Time Machine leaves out the model and the
  # engine, or that it could not be told to, with the chosen build's model and archive sizes (fields 29 and 22), "about"
  # since the unpacked engine is not in the registry; never the first after a failure (T135)
  local dl file repo l rb tm
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
  tm=$(au_bytes $(($(au_build_field "$AU_CH_BUILD" 29) + $(au_build_field "$AU_CH_BUILD" 22))))
  if [ "$AU_TM" = ok ]; then
    au_say "  Backups     Time Machine leaves out the model and the engine ($tm): a Mac restored from a backup"
    au_say "              fetches them again when the installer line is pasted."
  else
    au_say "  Backups     Time Machine could not be told to leave out the model and the engine, so it may back them up"
    au_say "              (about $tm)."
  fi
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

au_publisher_ask() { # URL SIZE SHA -> 0 when the publisher still offers that file as the registry names it (B3 step 7, D3.6
  # step 1): a HEAD with no login, the person's curl settings ignored and no redirect followed, whose size and sha256, when
  # it reports them (Hugging Face's x-linked-size and x-linked-etag), are the registry's; a publisher that reports neither
  # is no failure (T29). Otherwise 1, with AU_PUB_WHY: unreached, gone (404), size, sha, or the code it answered
  local out code hsize etag
  AU_PUB_WHY=
  out=$(curl -q --proto =https --tlsv1.2 -sS -I --max-time 60 -o /dev/null \
    -w '%{http_code}\t%header{x-linked-size}\t%header{x-linked-etag}' "$1" 2>/dev/null) || { AU_PUB_WHY=unreached; return 1; }
  au_split "$out"
  code=${AU_F[0]:-} hsize=${AU_F[1]:-} etag=${AU_F[2]:-}
  case "$code" in
    404) AU_PUB_WHY=gone; return 1 ;;
    200|301|302|303|307|308) ;;
    *)   # the code it answered, once matched as one (000 is none: au_fetch_said; T138)
      if [[ $code =~ ^[0-9]{1,3}$ ]] && [[ $code =~ [1-9] ]]; then AU_PUB_WHY=$code; else AU_PUB_WHY=none; fi
      return 1 ;;
  esac
  if [ -n "$hsize" ] && [ "$hsize" != "$2" ]; then AU_PUB_WHY=size; return 1; fi
  etag=${etag#W/}; etag=${etag//\"/}; etag=$(printf '%s' "$etag" | tr 'A-F' 'a-f')
  if [[ $etag =~ $AU_RE_SHA ]] && [ "$etag" != "$3" ]; then AU_PUB_WHY=sha; return 1; fi
}

au_publisher_said() { # FILE HOST -> AU_PUB_WHY in words, with no full stop: why the publisher's answer stops FILE's download
  case "$AU_PUB_WHY" in
    unreached) printf '%s could not be reached to ask about %s' "$2" "$1" ;;
    gone) printf 'The publisher no longer offers %s' "$1" ;;
    size) printf "The publisher reports a size for %s other than the registry's" "$1" ;;
    sha) printf "The publisher reports a sha256 for %s other than the registry's" "$1" ;;
    none) printf '%s gave no answer Auster can read when asked about %s' "$2" "$1" ;;
    *) printf '%s answered %s when asked about %s' "$2" "$AU_PUB_WHY" "$1" ;;   # a code au_publisher_ask matched
  esac
}

au_step7_model() { # the model: the publisher asked first, then fetched, resumable, and checked (B3 step 7). A failure is
  # au_fail's: exit 5 at an install; on an update, 1 and this recipe stopped. A download cut short is kept for a resume
  local sha size repo commit file url code pid got again="Pasting the line again resumes it."
  [ "$AU_UPDATING" = 0 ] || again="Updating again (\`auster update\`, or pasting the line) resumes it."
  [ "$AU_REPAIRING" = 0 ] || again="Pasting the installer line again resumes it."   # a repair's way in (D3.6, "The words")
  repo=$(au_build_field "$AU_CH_BUILD" 26); commit=$(au_build_field "$AU_CH_BUILD" 27)
  file=$(au_build_field "$AU_CH_BUILD" 28); size=$(au_build_field "$AU_CH_BUILD" 29); sha=$(au_build_field "$AU_CH_BUILD" 30)
  if [ -e "$AU_DATA/store/$sha" ]; then
    au_store_has "$sha" "$size" && { au_say "The model is already on this Mac, and still the file the registry names."; return 0; }
    chmod 644 "$AU_DATA/store/$sha" 2>/dev/null; rm -f "$AU_DATA/store/$sha"
    au_say "The model on this Mac had changed, so it is fetched again."
  fi
  url="$AU_MODEL_HOST/$repo/resolve/$commit/$file"
  au_publisher_ask "$url" "$size" "$sha" || { au_fail "$(au_publisher_said "$file" "Hugging Face"), so it was not fetched."; return 1; }
  au_say "Fetching $file ($(au_bytes "$size"))..."
  curl -q --proto =https --proto-redir =https --tlsv1.2 -sS -L -C - --speed-limit 10240 --speed-time 120 \
    --max-filesize "$size" -o "$AU_DATA/store/$sha.part" -w '%{http_code}' "$url" > "$AU_RUN/code" 2>/dev/null &
  pid=$!
  if [ "$AU_AWAKE" = yes ]; then caffeinate -i -w "$pid" > /dev/null 2>&1 & fi
  wait "$pid"; got=$?
  code=$(cat "$AU_RUN/code" 2>/dev/null)
  if [ "$got" != 0 ] || { [ "$code" != 200 ] && [ "$code" != 206 ] && [ "$code" != 416 ]; }; then
    au_fail "The model's download stopped ($(au_fetch_said "$got" "$code")) at $(au_bytes "$(au_size "$AU_DATA/store/$sha.part" || echo 0)") of $(au_bytes "$size"). $again"
    return 1
  fi
  got=$(au_size "$AU_DATA/store/$sha.part")
  if [ "$got" != "$size" ]; then
    [ "$got" -lt "$size" ] || rm -f "$AU_DATA/store/$sha.part"
    au_fail "The model's download is $(au_bytes "${got:-0}"), not the $(au_bytes "$size") the registry names. $again"
    return 1
  fi
  if [ "$(au_sha "$AU_DATA/store/$sha.part")" != "$sha" ]; then
    rm -f "$AU_DATA/store/$sha.part"
    au_fail "The model that arrived is not the file the registry names (its sha256 differs), so it was deleted."
    return 1
  fi
  au_store_put "$AU_DATA/store/$sha.part" "$sha" || { au_fail "The model could not be put in place."; return 1; }
}

au_step8_assets() { # the template, the system prompt and the test, from the tree by sha256 (B3 step 8, A4); a failure is
  # au_fail's, as at step 7
  local what sha f found t
  for what in 8:template 9:system-prompt 10:test; do
    sha=$(au_build_field "$AU_CH_BUILD" "${what%%:*}")
    au_store_has "$sha" && continue
    found=
    for f in "$AU_TREE"/assets/*; do
      [ -f "$f" ] && [ ! -L "$f" ] || continue
      if [ "$(au_sha "$f")" = "$sha" ]; then found=$f; break; fi
    done
    [ -n "$found" ] || { au_fail "This version of Auster holds no ${what#*:} with the sha256 the build names, so nothing more was installed."; return 1; }
    t="$AU_DATA/store/.$sha.new.$$"
    cp "$found" "$t" && [ "$(au_sha "$t")" = "$sha" ] && au_store_put "$t" "$sha" ||
      { rm -f "$t"; au_fail "The ${what#*:} could not be put in place."; return 1; }
  done
}

au_step9_engine() { # the engine, in store/ and unpacked into engines/<sha256>/ with its file list (B3 step 9); a
  # failure is au_fail's, as at step 7. For a repair of the build in use (AU_REPAIRING, D3.6), the engine is unpacked
  # again when its files fail the engine job's check at every start (au_engine_whole, against serving's list sha256,
  # AU_RP_LIST), not only when they differ from engines/<sha256>/files, and the list it then writes must have serving's
  # sha256, or the repair stops
  local sha size nb file d t got
  nb=$(au_build_field "$AU_CH_BUILD" 20); file=$(au_build_field "$AU_CH_BUILD" 21)
  size=$(au_build_field "$AU_CH_BUILD" 22); sha=$(au_build_field "$AU_CH_BUILD" 23)
  if ! au_store_has "$sha" "$size"; then
    t="$AU_DATA/store/.$sha.new.$$"
    if [ "$sha" = "$AU_MEASURED_ENGINE" ] && [ -f "$AU_RUN/engine.archive" ]; then
      cp "$AU_RUN/engine.archive" "$t" || { rm -f "$t"; au_fail "The engine could not be put in place."; return 1; }
    else
      au_say "Fetching the engine ($(au_bytes "$size"))..."
      au_fetch "$AU_ENGINE_HOST/$nb/$file" "$t" "$size"; got=$?
      [ "$got" = 0 ] && [ "$AU_CODE" = 200 ] || { rm -f "$t"; au_fail "The engine could not be fetched from GitHub ($(au_fetch_said "$got" "$AU_CODE"))."; return 1; }
    fi
    [ "$(au_size "$t")" = "$size" ] && [ "$(au_sha "$t")" = "$sha" ] || { rm -f "$t"; au_fail "The engine is not the one the registry names, so it was deleted."; return 1; }
    au_store_put "$t" "$sha" || { au_fail "The engine could not be put in place."; return 1; }
  fi
  d="$AU_DATA/engines/$sha"
  if { [ "$AU_REPAIRING" = 0 ] && ! au_engine_intact "$d"; } || { [ "$AU_REPAIRING" = 1 ] && ! au_engine_whole "$d" "$AU_RP_LIST"; }; then
    t="$AU_DATA/engines/.$sha.new.$$"
    au_unpack "$AU_DATA/store/$sha" "$t" || { rm -rf "$t"; au_fail "The engine was not unpacked, so it is not used."; return 1; }
    if [ "$AU_REPAIRING" = 1 ] && [ "$(au_sha "$t/files")" != "$AU_RP_LIST" ]; then
      rm -rf "$t"; au_fail "The engine unpacked again does not give the file list the build in use was installed with, so it is not used."; return 1
    fi
    rm -rf "$d"
    mv "$t" "$d" || { au_fail "The engine could not be put in place."; return 1; }
  fi
  AU_ENGINE_DIR=$d
  AU_LISTSHA=$(au_sha "$d/files")
  AU_PROGRAM=$(au_program_in "$d") || { au_fail "The engine holds no single program named llama-server."; return 1; }
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

au_candidate_stop() { # -> the candidate engine of step 10 stopped, if it runs, and its watch (au_candidate_test) first
  local i
  [ -n "$AU_CANDIDATE" ] || return 0
  if [ -n "$AU_CANDIDATE_WATCH" ]; then kill "$AU_CANDIDATE_WATCH" 2>/dev/null; wait "$AU_CANDIDATE_WATCH" 2>/dev/null; AU_CANDIDATE_WATCH=; fi
  kill "$AU_CANDIDATE" 2>/dev/null
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do kill -0 "$AU_CANDIDATE" 2>/dev/null || break; sleep 0.5; done
  kill -9 "$AU_CANDIDATE" 2>/dev/null
  wait "$AU_CANDIDATE" 2>/dev/null
  AU_CANDIDATE=
}

au_candidate_test() { # PEOPLE CONTEXT -> the test in isolation (B3 step 10, D3.6 step 4) of AU_CH_BUILD, whose engine step 9
  # unpacked: the candidate started by this run itself, never by the engine job, on 127.0.0.1 only, on a free port, with
  # a key made for the test in a folder of this run's and deleted after it, and with the engine's fitting off, for PEOPLE
  # at CONTEXT tokens each; then the recipe's test (A7), which checks the form of each answer and runs nothing it is
  # sent, a tool call among them (T28); and the candidate stopped, whether it passed or failed, or by its watch, a process
  # of its own, as soon as this run is gone (killed: T25). 0 on a pass, 1 on a fail, 2 when no key for the test could be
  # made (nothing was started)
  local port k i code rc tsha ssha
  for ((port = AU_TEST_PORT_FIRST; port < AU_TEST_PORT_FIRST + 100; port++)); do
    nc -z -w 1 127.0.0.1 "$port" > /dev/null 2>&1 || break
  done
  k="$AU_RUN/test-key"
  rm -rf "$k"
  ( umask 077; mkdir "$k" && openssl rand -hex 16 > "$k/key" ) && [[ $(head -n 1 "$k/key") =~ $AU_RE_KEY ]] ||
    { rm -rf "$k"; return 2; }
  tsha=$(au_build_field "$AU_CH_BUILD" 8); ssha=$(au_build_field "$AU_CH_BUILD" 9)
  au_say "Testing the build on this Mac, for $1 people at $(au_commas "$2") tokens each..."
  ( cd "$AU_DATA/store" && exec env -i PATH="$AU_ENGINE_PATH" "$AU_ENGINE_DIR/root/$AU_PROGRAM" \
      -m "$(au_build_field "$AU_CH_BUILD" 30)" --alias "$AU_CH_BUILD" -c $(($1 * $2)) -np "$1" \
      --host 127.0.0.1 --port "$port" --api-key-file "$k/key" --offline --no-slots --no-webui-mcp-proxy \
      --jinja --chat-template-file "$tsha" --temp "$(au_build_field "$AU_CH_BUILD" 15)" \
      --top-p "$(au_build_field "$AU_CH_BUILD" 16)" --fit off -ngl all ) > "$AU_RUN/candidate.log" 2>&1 &
  AU_CANDIDATE=$!
  ( while kill -0 "$$" 2>/dev/null && kill -0 "$AU_CANDIDATE" 2>/dev/null; do sleep 1; done   # a run that is killed stops it too
    kill "$AU_CANDIDATE" 2>/dev/null ) > /dev/null 2>&1 &
  AU_CANDIDATE_WATCH=$!
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
  [ "$rc" = 0 ] || return 1
}

au_step10_test() { # -> 0 on a pass; on a fail the descriptor goes to failed/ and the run stops with exit 5
  local r="$AU_DATA/builds/$AU_RECIPE" f rc=0
  au_candidate_test "$AU_PEOPLE" "$AU_CONTEXT" || rc=$?
  [ "$rc" != 2 ] || au_stop "A key for the test could not be made."
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
# fetches nothing; it records neither the router nor the `.local` name, chooses no port and writes no `mac` (T65, T100).
# Every size and sha256 comes from the registry in this tree (AU_REG), never from _update/registry. Each recipe that has
# `serving` is judged by section C with the household's number of people carried over (C4) and is OK (its build and
# setting are the ones served), held, passed over (and why) or withdrawn, one line each; or its build or setting would
# change, and it goes to the question (D3.6 step 2), after its template, system prompt and test are found in store/ or
# this tree's assets/ (step 8's lookup, made before the question so that no yes is asked for a build this tree cannot
# install: T54). A no leaves everything as it was and the build waiting (T7, T35). With one recipe, the files of the
# build it serves are checked before the question (au_update_files: the model and the engine's archive by size and
# sha256, the template, system prompt and test by sha256, the engine's unpacked files as the engine job checks them);
# one changed or missing makes the recipe a repair (D3.6, "A changed file of the build in use is fetched again"), with
# its own pre-checks (au_repair_ask) and its lines in the question, and its files fetched again from serving's own lines
# (au_repair_report). A yes (U5, au_update_yes) first repairs the build in use when it must (au_repair: steps 7 to 9 for
# it, no test, serving not rewritten), the one thing that comes before Auster's programs; then changes Auster's own
# programs when they differ, or checks the server when jobs/previous/ shows an earlier change never checked
# (au_update_programs: B3 step 6, BD18, T94), before anything else is fetched; then writes `mac` (au_update_mac); then
# switches a change of setting (au_switch_setting), or, for a change of build, fetches its files (au_update_build: room
# again, the removals the question named, B3 steps 7 to 9), then tests it in isolation and switches to it
# (au_update_test: fit and the way worked out again, side by side or in turn, D3.6 steps 4 and 5). A failed test puts
# the build in failed/ and leaves serving as it was (exit 3); a switch whose server check fails ends the run (exit 4). A
# change of build goes to the question only after its pre-checks (au_update_ask, D3.6 step 1: the engine's macOS floor,
# and the publisher's HEAD for each file store/ does not hold whole); a recipe that fails one is passed over (exit 3). A
# repair passed over, declined or failed ends the run with no restart, no server check, no program changed and no step
# 15 (au_repair_end; exit 3, or 1 for a no).
# `update --retry` (AU_RETRY) judges every recipe without its failed/, so that a build that failed its test here is
# offered again (D3.7, BD12), and its question says so.
# Then, and with nothing to change, the run makes the server check when a `serving` has a speed of 0, jobs/previous/ is
# there, a repair completed with no restart since, or the engine job's last start is engine-hash (B3 step 13, D3.6),
# shows the devices' keys when the Mac had no stamp (an install that never finished, T65), and writes step 15, with
# _update's registry, notes and offer when the stamp moved (U4: so that each recipe's line is not `unknown` until the
# next check). No record is written before the question but the lock, nor after the yes before the programs have passed
# their check (a repair writes only files of store/ and engines/ before them), and step 15 is reached only when Auster's
# programs are byte for byte this tree's, so no record of a format the programs in use do not read is ever written by a
# run that has not changed them and seen them pass (D3.1; the row "a record's format and rollback").
# `people` (au_people, below the update) is the same procedure for the build each recipe serves, at the number of
# people asked: no other build, no download, no repair, no test, no program changed and no stamp (B6).

au_later() { # X Y -> 0 when version X is later than version Y, both matched to AU_RE_VERSION, compared as numbers (D3.2)
  local x=${1#v} y=${2#v} i a b
  for i in 1 2 3; do
    a=${x%%.*} b=${y%%.*}; x=${x#*.} y=${y#*.}
    [ "$a" -gt "$b" ] && return 0
    [ "$a" -lt "$b" ] && return 1
  done
  return 1
}

au_update_measure() { # [again] -> B3 step 4 on an update (D3.6): AU_FIGURES, AU_DISKARGS and AU_NODISK, what section C is
  # given. The GPU limit from --list-devices of the engine already in engines/ that serving names, or, when that engine is
  # not the one its list names, the `mac` record's; the memory measured; the disk holdings as the rule file makes them, and
  # no disk figures at all when a descriptor cannot be read (D3.3). With again, made anew immediately before the test (C5,
  # D3.6 step 4), saying nothing, and 1 rather than a refusal when the memory cannot be read
  local r dir prog=
  AU_RAM=$(sysctl -n hw.memsize 2>/dev/null)
  if ! [[ $AU_RAM =~ ^[1-9][0-9]{0,14}$ ]]; then
    [ -z "${1:-}" ] || return 1
    au_refuse "This Mac's memory cannot be read (sysctl hw.memsize), so nothing was changed."
  fi
  AU_FIGURES=(--mac "$AU_DATA/builds/mac" --ram "$AU_RAM")
  AU_SV_ENGINE=
  for r in "${AU_URECIPES[@]}"; do au_serving_read "$r" && break; AU_SV_ENGINE=; done
  dir="$AU_DATA/engines/${AU_SV_ENGINE:-none}"
  if [ -n "$AU_SV_ENGINE" ] && au_engine_intact "$dir" && prog=$(au_program_in "$dir"); then
    [ -n "${1:-}" ] || au_say "Measuring this Mac with the engine already on it; nothing is fetched before the question."
    au_limited 120 "$AU_RUN/list-devices.txt" /bin/bash -c 'cd "$1" && exec env -i PATH="$2" "$3" --list-devices' _ "$AU_RUN" "$AU_ENGINE_PATH" "$dir/root/$prog"
    AU_FIGURES+=(--list-devices "$AU_RUN/list-devices.txt")
  else
    [ -n "${1:-}" ] || au_say "The engine this Mac serves with is not the one its list names, so the figures recorded at install (builds/mac) are used."
  fi
  au_update_disk
}

au_update_disk() { # -> AU_DISKARGS and AU_NODISK, the disk section C is given (C6): `df -k` of the data root and the disk
  # holdings (common/auster's au_holdings, as `auster cleanup` makes them; partial downloads among them), measured now; no
  # disk figures at all when a descriptor cannot be read (D3.3). Made at step 4, and again after the yes, before a download
  # starts (D3.6 step 3)
  AU_DISKARGS=() AU_NODISK=()
  if df -k "$AU_DATA" > "$AU_RUN/df.txt" 2>/dev/null && ( au_holdings ) > "$AU_RUN/disk" 2>/dev/null; then
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
  # D3.1) and failed/ (none with --retry: D3.7, BD12), the build loaded when the engine's job is loaded (C5), and the
  # figures of step 4. AU_JFAILED is the date the build a change picks last failed its test here, when it has
  local r=$1 l f id seen=0 held= lf=() cf=() opts=()
  AU_J=passed AU_J_SAY= AU_JK= AU_JREMOVE=() AU_JNAME="This Mac's recipe" AU_JLABEL= AU_JFAILED= AU_JMOVEOFF=0
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
    [ "$AU_RETRY" = 0 ] || break   # update --retry: a build that failed its test here is offered again
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
          AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="This version of Auster holds no $AU_MISSING with the sha256 build $AU_JPICK names. $AU_JNAME is not updated: it keeps serving build $AU_JNOW."
        fi
        for f in "$AU_DATA/builds/$r"/failed/*-"$AU_JPICK"; do
          au_entry_read "$f" && AU_JFAILED=${f##*/} AU_JFAILED=${AU_JFAILED%%T*}
        done
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

au_update_ask() { # -> D3.6 step 1's last pre-checks, before the question, for the build au_update_judge picked for a
  # change: the engine it names must run on this macOS (the engine line's oldest macOS against the major version now, as
  # a first install judges it, B3 step 4), and each file store/ does not hold whole (au_store_has: a file that is there
  # but has changed counts as not held, D3.6), the model and the engine archive, must still be offered by its publisher
  # as the registry names it (au_publisher_ask: a HEAD, nothing fetched; T29, T110). Otherwise the recipe is passed over
  # (AU_J passed, AU_JMOVEOFF 1) with one sentence, AU_J_SAY, and the update ends with exit 3
  local v major e_mac sha url file keep="$AU_JNAME is not updated: it keeps serving build $AU_JNOW."
  v=$(sw_vers -productVersion 2>/dev/null); major=${v%%.*}
  e_mac=$(au_build_field "$AU_JPICK" 24)
  if ! [[ $e_mac =~ ^[1-9]?[0-9]$ ]]; then   # each value matched before a sentence names it (T141)
    AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="The registry does not say which macOS the engine of build $AU_JPICK needs. $keep"
    return 0
  fi
  if ! [[ $v =~ $AU_RE_MACOS ]]; then
    AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="Build $AU_JPICK needs an engine that runs on macOS $e_mac or later, and this Mac has a version of macOS that cannot be read. $keep"
    return 0
  fi
  if [ "$major" -lt "$e_mac" ]; then
    AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="Build $AU_JPICK needs an engine that runs on macOS $e_mac or later, and this Mac has macOS $v. $keep"
    return 0
  fi
  sha=$(au_build_field "$AU_JPICK" 30) file=$(au_build_field "$AU_JPICK" 28)
  url="$AU_MODEL_HOST/$(au_build_field "$AU_JPICK" 26)/resolve/$(au_build_field "$AU_JPICK" 27)/$file"
  if ! au_store_has "$sha" "$(au_build_field "$AU_JPICK" 29)" && ! au_publisher_ask "$url" "$(au_build_field "$AU_JPICK" 29)" "$sha"; then
    AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="$(au_publisher_said "$file" "Hugging Face"), so nothing was fetched. $keep"
    return 0
  fi
  sha=$(au_build_field "$AU_JPICK" 23) file=$(au_build_field "$AU_JPICK" 21)
  url="$AU_ENGINE_HOST/$(au_build_field "$AU_JPICK" 20)/$file"
  if ! au_store_has "$sha" "$(au_build_field "$AU_JPICK" 22)" && ! au_publisher_ask "$url" "$(au_build_field "$AU_JPICK" 22)" "$sha"; then
    AU_J=passed AU_JMOVEOFF=1 AU_J_SAY="$(au_publisher_said "$file" "GitHub"), so nothing was fetched. $keep"
  fi
}

# --- the repair of the build in use (D3.6, "A changed file of the build in use is fetched again"; U6, T117, T118) -----
# One recipe at most has a repair (BD14); with several recipes no file is checked, and each is judged as before. Its
# files' addresses, sizes and sha256s are serving's own lines 2 to 4 (A5), never _update's registry, so a build the
# latest order no longer names can still be repaired. serving is read again before its check, its pre-checks, its
# question and steps 7 to 9, since the judge reads failed/ entries after it and each read replaces every AU_SV_*
# (au_entry_read). AU_RP holds what is changed or missing, AU_RP_RECIPE its recipe; AU_RP_BAD is 1 once it is passed
# over or has failed (no restart, no check, no program changed, no step 15: au_repair_end); AU_RP_WAIT names the recipe
# while its server check is still to come.

au_update_files() { # RECIPE -> AU_RP: the files of the build RECIPE serves that are changed or missing, each a word, in
  # the order the question names them: model and engine (its archive) by size and sha256 (au_store_has), unpacked (the
  # engine's unpacked files, as the engine job checks them at every start: au_engine_whole), template, system-prompt and
  # test by sha256. Empty when every one matches, or when serving cannot be read (it names no files, and the judge
  # passes the recipe over). It reads and never writes, so a run whose files all match changes nothing (T65); the
  # model's hash is its cost (AD13), so it says so first
  AU_RP=
  au_serving_read "$1" || return 0
  au_say "Checking each file of build $AU_SV_BUILD against its sha256; the model, $(au_bytes "$AU_SV_MODEL_SIZE"), takes the longest..."
  au_store_has "$AU_SV_MODEL" "$AU_SV_MODEL_SIZE" || AU_RP+=" model"
  au_store_has "$AU_SV_ENGINE" "$AU_SV_ENGINE_SIZE" || AU_RP+=" engine"
  au_engine_whole "$AU_DATA/engines/$AU_SV_ENGINE" "$AU_SV_LIST" || AU_RP+=" unpacked"
  au_store_has "$AU_SV_TEMPLATE" || AU_RP+=" template"
  au_store_has "$AU_SV_SYSTEM" || AU_RP+=" system-prompt"
  au_store_has "$AU_SV_TEST" || AU_RP+=" test"
  AU_RP=${AU_RP# }
}

au_repair_report() { # -> AU_REGOUT pointed at $AU_RUN/registry-repair.out, a one-build report in registry.js's
  # numbering (common/registry.js's header) from lines 2 to 4 of the serving read last (AU_SV_LINES): `build`, position
  # 1, ok and -, then the build line's fields 2 to 14 as fields 5 to 17, the engine's 2 to 8 as 18 to 24 and the model's
  # 2 to 10 as 25 to 33; then the three `raw` lines. So the repo, commit and numbered build of every address come from
  # serving alone. The caller points AU_REGOUT back at the tree's report
  local f="$AU_RUN/registry-repair.out" b e m
  b=$(printf '%s\n' "${AU_SV_LINES[1]}" | cut -f2-14) e=$(printf '%s\n' "${AU_SV_LINES[2]}" | cut -f2-8)
  m=$(printf '%s\n' "${AU_SV_LINES[3]}" | cut -f2-10)
  { printf 'build\t1\tok\t-\t%s\t%s\t%s\n' "$b" "$e" "$m"
    printf 'raw\t%s\tbuild\t%s\n' "$AU_SV_BUILD" "${AU_SV_LINES[1]}"
    printf 'raw\t%s\tengine\t%s\n' "$AU_SV_BUILD" "${AU_SV_LINES[2]}"
    printf 'raw\t%s\tmodel\t%s\n' "$AU_SV_BUILD" "${AU_SV_LINES[3]}"; } > "$f" || return 1
  AU_REGOUT=$f
}

au_repair_download() { # -> AU_RP_DL, the bytes the repair still fetches, from the serving read last: the model's size
  # less any part of it already down (store/<sha256>.part), when it is changed or missing, and the engine's archive when
  # it is. The changed model still counts as held: the engine maps it until it restarts, so deleting it frees nothing
  # until then
  local p=0
  AU_RP_DL=0
  case " $AU_RP " in *" model "*)
    [ ! -f "$AU_DATA/store/$AU_SV_MODEL.part" ] || p=$(au_size "$AU_DATA/store/$AU_SV_MODEL.part")
    [[ $p =~ $AU_RE_SIZE ]] || p=0
    [ "$p" -ge "$AU_SV_MODEL_SIZE" ] || AU_RP_DL=$((AU_SV_MODEL_SIZE - p)) ;;
  esac
  case " $AU_RP " in *" engine "*) AU_RP_DL=$((AU_RP_DL + AU_SV_ENGINE_SIZE)) ;; esac
}

au_repair_room() { # RECIPE -> 0 when C6's disk rule leaves room for AU_RP_DL with the disk as it is, measured last
  # (au_update_disk): free disk, less the download, at least the floor, both given by section C's own rule for these
  # figures (capability.js --cleanup, which removes nothing). With nothing to fetch, or no disk figures (a descriptor
  # that cannot be read, D3.3), no disk rule is applied, as for any download. Otherwise 1, with AU_RP_SAY naming `auster
  # cleanup`
  local l
  [ "$AU_RP_DL" -gt 0 ] && [ "${#AU_DISKARGS[@]}" -gt 0 ] || return 0
  l=$(osascript -l JavaScript "$AU_TREE/common/capability.js" --cleanup "$1" "${AU_DISKARGS[@]}" 2>/dev/null | awk -F'\t' '$1 == "disk"')
  au_split "$l"
  [[ ${AU_F[2]:-} =~ $AU_RE_SIZE ]] && [[ ${AU_F[3]:-} =~ $AU_RE_SIZE ]] || return 0
  [ $((AU_F[3] - AU_RP_DL)) -lt "${AU_F[2]}" ] || return 0
  AU_RP_SAY="There is not room on this Mac's disk to fetch it again: it has $(au_bytes "${AU_F[3]}") free, and the download, $(au_bytes "$AU_RP_DL"), needs $(au_bytes $((AU_RP_DL + AU_F[2]))) free (Auster keeps the larger of 20 GB and 5% of the disk free). \`auster cleanup\` lists what it can remove."
  return 1
}

au_repair_ask() { # RECIPE -> 0 when the repair can be asked; 1 with AU_RP_SAY, nothing deleted or fetched, when it is
  # passed over before the question, as for any download (D3.6 step 1, D3.10): the tree's report has the build on raw
  # lines other than serving's (the registry contradicts itself); a changed template, system prompt or test is in no
  # assets/ of this tree (au_update_assets); the publisher's HEAD refuses a changed model or archive (au_publisher_ask);
  # or the download fails C6's disk rule with the disk as it is (au_repair_room). serving is read again first; AU_REGOUT
  # is the tree's report on entry and on return
  local r=$1 tree=$AU_REGOUT k l keep url file
  if ! au_serving_read "$r"; then AU_RP_SAY="What $AU_JNAME serves (builds/$r/serving) cannot be read, so nothing was fetched."; return 1; fi
  keep="$AU_JNAME keeps serving build $AU_SV_BUILD, and nothing was fetched."
  if [ -n "$(au_build_field "$AU_SV_BUILD" 5)" ]; then
    for k in 1:build 2:engine 3:model; do
      l=$(au_raw "$AU_SV_BUILD" "${k#*:}")
      [ "$l" = "${AU_SV_LINES[${k%%:*}]}" ] && continue
      AU_RP_SAY="The registry of Auster $AU_VERSION names build $AU_SV_BUILD on lines other than the ones it was installed from (builds/$r/serving), so the registry contradicts itself and no file of it is fetched again. $keep"
      return 1
    done
  fi
  au_repair_report || { AU_RP_SAY="The files of build $AU_SV_BUILD could not be listed from builds/$r/serving. $keep"; return 1; }
  if ! au_update_assets "$AU_SV_BUILD"; then
    AU_REGOUT=$tree AU_RP_SAY="This version of Auster holds no $AU_MISSING with the sha256 build $AU_SV_BUILD names, so it cannot be put back. $keep"
    return 1
  fi
  case " $AU_RP " in *" model "*)
    url="$AU_MODEL_HOST/$(au_build_field "$AU_SV_BUILD" 26)/resolve/$(au_build_field "$AU_SV_BUILD" 27)/$AU_SV_MODEL_FILE"
    if ! au_publisher_ask "$url" "$AU_SV_MODEL_SIZE" "$AU_SV_MODEL"; then
      AU_REGOUT=$tree AU_RP_SAY="$(au_publisher_said "$AU_SV_MODEL_FILE" "Hugging Face"), so it cannot be fetched again. $keep"
      return 1
    fi ;;
  esac
  case " $AU_RP " in *" engine "*)
    file=$(au_build_field "$AU_SV_BUILD" 21) url="$AU_ENGINE_HOST/$(au_build_field "$AU_SV_BUILD" 20)/$(au_build_field "$AU_SV_BUILD" 21)"
    if ! au_publisher_ask "$url" "$AU_SV_ENGINE_SIZE" "$AU_SV_ENGINE"; then
      AU_REGOUT=$tree AU_RP_SAY="$(au_publisher_said "$file" "GitHub"), so it cannot be fetched again. $keep"
      return 1
    fi ;;
  esac
  AU_REGOUT=$tree
  au_repair_download
  au_repair_room "$r" || { AU_RP_SAY+=" $keep"; return 1; }
}

au_repair_lines() { # [first] -> the question's lines for a repair (D3.6, "The question"), from the serving read last:
  # each file, changed or missing, and what fetching it again takes: the model's size, from its publisher; the
  # archive's, from GitHub; the template, system prompt or test from this version of Auster; an engine whose archive
  # still matches is unpacked again with nothing fetched. With first (a change of setting or of build), they have a line
  # of their own saying why they come first
  local w how mrepo p=0
  au_split "${AU_SV_LINES[3]}"; mrepo=${AU_F[2]:-}
  if [ -n "${1:-}" ]; then
    au_say "  Repair      These files of build $AU_SV_BUILD, which it serves now, are fetched again first, so that the build this Mac"
    au_say "              serves is whole before anything restarts it:"
  else
    au_say "  Repair      These files of build $AU_SV_BUILD, which it serves, are fetched again:"
  fi
  for w in $AU_RP; do
    case "$w" in
      model)
        how="has changed"; [ -e "$AU_DATA/store/$AU_SV_MODEL" ] || how="is missing"
        [ ! -f "$AU_DATA/store/$AU_SV_MODEL.part" ] || p=$(au_size "$AU_DATA/store/$AU_SV_MODEL.part")
        if [[ $p =~ ^[1-9][0-9]*$ ]] && [ "$p" -lt "$AU_SV_MODEL_SIZE" ]; then
          au_say "              the model $AU_SV_MODEL_FILE, which $how: $(au_bytes $((AU_SV_MODEL_SIZE - p))) of its $(au_bytes "$AU_SV_MODEL_SIZE") still to fetch from Hugging Face ($mrepo)"
        else
          au_say "              the model $AU_SV_MODEL_FILE, which $how: $(au_bytes "$AU_SV_MODEL_SIZE") from Hugging Face ($mrepo)"
        fi ;;
      engine)
        how="has changed"; [ -e "$AU_DATA/store/$AU_SV_ENGINE" ] || how="is missing"
        au_say "              the engine's archive, which $how: $(au_bytes "$AU_SV_ENGINE_SIZE") from GitHub" ;;
      unpacked)
        how="have changed"; [ -e "$AU_DATA/engines/$AU_SV_ENGINE/root" ] || how="are missing"
        au_say "              the engine's unpacked files, which $how: unpacked again from its archive, with nothing fetched for them" ;;
      template|system-prompt|test)
        case "$w" in template) how=$AU_SV_TEMPLATE ;; system-prompt) how=$AU_SV_SYSTEM ;; *) how=$AU_SV_TEST ;; esac
        if [ -e "$AU_DATA/store/$how" ]; then how="has changed"; else how="is missing"; fi
        case "$w" in test) w="recipe's test" ;; system-prompt) w="system prompt" ;; esac
        au_say "              the $w, which $how: from this version of Auster" ;;
    esac
  done
}

au_repair() { # RECIPE -> D3.6, "After the yes", for a repair: steps 7 to 9 for the build in use, first of anything
  # after the yes, with AU_CH_BUILD set to it and AU_REGOUT at the one-build report of serving's lines, read again (and
  # back at the tree's report after): the room worked out again with the disk measured now, as after any yes; the model,
  # when it is changed or missing, deleted and fetched again resumably, the Mac kept awake during its download when
  # `mac` says so (BD10); a template, system prompt or test copied from the tree and renamed over the old one; the
  # archive fetched again; the engine unpacked again when its files fail the engine job's check, its list then serving's
  # (au_step9_engine). No isolated test: the files are byte for byte the ones the build passed its test with. serving is
  # not rewritten, nothing goes into kept/, and nothing restarts here: the run's next server check is the repair's
  # (AU_RP_WAIT, until a restart). 0 once every file is whole; 1, having said why, when it failed (a download cut short
  # keeps its part for a resume)
  local r=$1 tree=$AU_REGOUT rc=0
  if ! au_serving_read "$r"; then au_say "What $AU_JNAME serves (builds/$r/serving) cannot be read now, so no file of it was fetched again."; return 1; fi
  au_repair_report || { au_say "The files of build $AU_SV_BUILD could not be listed from builds/$r/serving, so none was fetched again."; return 1; }
  au_update_disk
  au_repair_download
  if ! au_repair_room "$r"; then
    AU_REGOUT=$tree
    au_say "What this Mac can hold changed since the question. $AU_RP_SAY"
    return 1
  fi
  AU_CH_BUILD=$AU_SV_BUILD AU_RP_LIST=$AU_SV_LIST AU_REPAIRING=1
  au_mac_read
  AU_AWAKE=no
  [ "$AU_MAC" != ok ] || AU_AWAKE=${AU_MAC_LINES[6]#keep-awake"$AU_T"}
  au_say "Putting back the files of build $AU_CH_BUILD, which this Mac serves..."
  case " $AU_RP " in *" model "*) au_step7_model || rc=1 ;; esac
  [ "$rc" = 1 ] || au_step8_assets || rc=1
  [ "$rc" = 1 ] || au_step9_engine || rc=1
  AU_REPAIRING=0 AU_REGOUT=$tree
  if [ "$rc" = 1 ]; then
    au_say "So the files of build $AU_CH_BUILD are not whole: nothing restarts the server, which serves on from what it has loaded."
    return 1
  fi
  AU_RP_DONE=1 AU_RP_WAIT=$r
  au_say "The files of build $AU_CH_BUILD are whole again, byte for byte the ones it passed its test with, so it is not tested again."
}

au_repair_end() { # -> after a repair passed over or failed (D3.6, "Order against B3 step 6"): this run restarts
  # nothing, makes no server check (au_update_check's included, whatever jobs/previous/ or the engine job's last start
  # say), changes none of Auster's programs and shows no device key, and has no step 15, so _update/updates.sh and the
  # stamp are left as they were; then the words by state, as au_update_unfinished's are, and the closing line. Exit 3
  local s="Pasting the installer line again fetches it again."
  au_say ""
  [ "$AU_PROGRAMS_CHANGE" = 0 ] ||
    au_say "Auster's own programs of $AU_VERSION are not put in place while a file of the build this Mac serves cannot be fetched again."
  if [ "$AU_HAD_STAMP" = 0 ]; then
    au_say "The install is not finished: paste the line again to fetch it again and finish, or remove it with: \"$AU_DATA/bin/auster\" remove"
  else
    if [ -n "$(ls -A "$AU_DATA/builds/$AU_RP_RECIPE/kept" 2>/dev/null)" ]; then
      s+=" \`auster rollback\` goes back to what it served before, with no download"
      if [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; then
        s+=" (run it twice: the first time puts Auster's previous programs back)"
      fi
      s+="."
    fi
    au_say "$s"
  fi
  au_say ""
  if [ "$AU_PROGRAMS_CHANGE" = 1 ] && [ "$AU_PROGRAMS_IN" = 0 ]; then
    au_say "Auster $AU_VERSION is not in place on this Mac yet: the lines above say why."
  else
    au_say "Auster $AU_VERSION is on this Mac, but not everything was updated: the lines above say why."
  fi
  exit 3
}

au_update_question() { # -> 0 on a yes, 1 on a no (D3.6 step 2), for the recipe au_update_judge judged a change: what
  # will change, in figures, with the household's number of people carried over (C4); the download; the earlier builds
  # the disk rule would remove; which way the switch goes on this Mac and how long the server will not answer; and
  # whether Auster's own programs change. With a repair of the build in use (AU_RP, D3.6 "The question"), serving is
  # read again and each of its files to fetch again has a line (au_repair_lines): the question's own when the repair is
  # all that changes (AU_JK repair), and in a change of setting or of build a line of their own, with what comes first;
  # a changed file the chosen build shares is fetched once, so the build's download leaves it out. Nothing has been
  # fetched, and nothing is written whatever the answer
  local file= repo= parts= l n=0 m_sha e_sha dl=${AU_JDL:-0}
  [ -z "$AU_RP" ] || au_serving_read "$AU_RP_RECIPE"
  au_say ""
  if [ "$AU_JK" = build ]; then
    au_say "$AU_JNAME: an update is waiting. Nothing has been fetched, and nothing changes without a yes."
    file=$(au_build_field "$AU_JPICK" 28) repo=$(au_build_field "$AU_JPICK" 26)
  elif [ "$AU_JK" = repair ]; then
    au_say "$AU_JNAME: a file of the build it serves has changed or is missing, and is fetched again. Nothing has been fetched, and nothing changes without a yes."
  else
    au_say "$AU_JNAME: its setting would change, on the build it serves. Nothing changes without a yes."
  fi
  au_say ""
  au_say "  Now         build $AU_JNOW${AU_JNOWFILE:+ ($AU_JNOWFILE)}, $AU_JP0 people at a time, each with a context of $(au_commas "$AU_JC0") tokens."
  if [ "$AU_JK" = repair ]; then
    au_repair_lines
    [ "$AU_PROGRAMS_CHANGE" = 1 ] || [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ] ||
      au_say "  Restart     The server restarts once on the files put back, to check them, and does not answer for a few seconds."
  else
    if [ "$AU_JK" = build ]; then
      au_say "  After       build $AU_JPICK${file:+ ($file)}, $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens,"
    else
      au_say "  After       the same build, $AU_JP people at a time, each with a context of $(au_commas "$AU_JC") tokens,"
    fi
    au_say "              holding $(au_memory "$AU_JALL") of this Mac's $(au_memory $((AU_JMEM / 1048576))) of memory, $(au_memory "$AU_JGPU") of it on the GPU."
    if [ "$AU_MODE" = people ]; then au_say "  People      $AU_JP people at a time, as asked, in place of $AU_JP0."
    elif [ "$AU_JP" = "$AU_JP0" ]; then au_say "  People      The household's number of people, $AU_JP, is kept."
    else au_say "  People      The recipe now allows at most $AU_JP people at a time, so the household's $AU_JP0 is lowered to $AU_JP."; fi
    if [ "$AU_JK" = setting ] && [ -n "$AU_RP" ]; then
      au_say "  Download    Only the files of the build it serves named below: it is the build this Mac serves."
    elif [ "$AU_JK" = setting ]; then
      au_say "  Download    Nothing: it is the build this Mac serves, with its files already here."
    else
      m_sha=$(au_build_field "$AU_JPICK" 30) e_sha=$(au_build_field "$AU_JPICK" 23)
      if [ -n "$AU_RP" ]; then   # what the repair fetches first is fetched once (D3.6, "When the run moves the recipe")
        case " $AU_RP " in *" model "*) if [ "$m_sha" = "$AU_SV_MODEL" ]; then [ -f "$AU_DATA/store/$m_sha" ] || dl=$((dl - AU_SV_MODEL_SIZE)); m_sha=; fi ;; esac
        case " $AU_RP " in *" engine "*) if [ "$e_sha" = "$AU_SV_ENGINE" ]; then [ -f "$AU_DATA/store/$e_sha" ] || dl=$((dl - AU_SV_ENGINE_SIZE)); e_sha=; fi ;; esac
        [ "$dl" -ge 0 ] || dl=0
      fi
      if [ "$dl" = 0 ]; then
        au_say "  Download    Nothing: the files it needs are already on this Mac."
      else
        [ -z "$m_sha" ] || [ -f "$AU_DATA/store/$m_sha" ] || parts="$file from Hugging Face ($repo)"
        [ -z "$e_sha" ] || [ -f "$AU_DATA/store/$e_sha" ] || parts+="${parts:+, and }the engine $(au_build_field "$AU_JPICK" 20) from GitHub"
        au_say "  Download    $(au_bytes "$dl")${parts:+: $parts}."
      fi
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
    [ -z "$AU_RP" ] || au_repair_lines first
    if [ "$AU_JK" = setting ] && [ -n "$AU_RP" ]; then
      au_say "  Switch      The server restarts once on the new setting, and does not answer for a few seconds."
    elif [ "$AU_JK" = setting ]; then
      au_say "  Switch      Nothing is fetched or tested: the server restarts once on the new setting, and does not answer for a few seconds."
    elif [ "$AU_JWAY" = side-by-side ]; then
      au_say "  Switch      This Mac can hold both builds at once: the new one is tested beside the one serving, which keeps answering"
      au_say "              (a test that fails restarts it: a few seconds without answers). The server then restarts once on the new"
      au_say "              build and does not answer for a few seconds, up to about 15 s when the model is read from disk."
    else
      au_say "  Switch      This Mac cannot hold both builds at once: the server does not answer while the new build is tested,"
      au_say "              up to about 3 minutes, and then restarts on it."
    fi
  fi
  [ "$AU_JWD" = - ] || au_say "  Withdrawn   The build it serves now has been withdrawn."
  [ "$AU_JK" != build ] || [ -z "$AU_JFAILED" ] || au_say "  Tried again Build $AU_JPICK failed its test on this Mac on $AU_JFAILED; it is tested again before it serves."
  if [ "$AU_PROGRAMS_CHANGE" = 1 ] && [ -n "$AU_RP" ]; then
    au_say "  Programs    Auster's own programs change too (${AU_FROM:+from $AU_FROM }to $AU_VERSION): they are put in place once the files"
    au_say "              above are whole, before anything else is downloaded, and the server restarts once to check them."
  elif [ "$AU_PROGRAMS_CHANGE" = 1 ]; then
    au_say "  Programs    Auster's own programs change too (${AU_FROM:+from $AU_FROM }to $AU_VERSION): they are put in place first, before"
    au_say "              anything is downloaded, and the server restarts once to check them."
  elif { [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; } && [ -n "$AU_RP" ]; then
    au_say "  Programs    Auster's own programs were changed by an earlier update and never checked: the server restarts"
    au_say "              once to check them, once the files above are whole."
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
  if [ "$AU_JK" = repair ]; then
    au_yes "Fetch the files of ${AU_JLABEL:-this recipe} again now?" && return 0
    au_say "Nothing was changed: pasting the installer line again offers this again."
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

au_update_yes() { # [RECIPE] -> what follows a yes (B3 steps 6 to 13, D3.6), for the recipe au_update_judge judged a
  # change, or with none for Auster's programs alone: a repair of the build in use first, when it has one (au_repair,
  # D3.6: the one thing before Auster's programs, BD18), then the programs (au_update_programs), then `mac`
  # (au_update_mac), then a change of setting switched (au_switch_setting) or a change of build fetched, tested and
  # switched (au_update_build); a repair alone (AU_JK repair) has nothing after `mac`. 0 once all of that has passed; 1
  # when the recipe stopped (a change of build passed over after the yes, cut short in its download, or failing its
  # test: it keeps serving its build), having said why. A repair that fails is a 1 with AU_RP_BAD set: nothing after it
  # runs, and the run ends with au_repair_end. Otherwise the run then goes on to the server check of every recipe that
  # needs one and to step 15, and ends with exit 3 after a 1. Open or not answered end the run with exit 4 on the way
  if [ -n "$AU_RP" ] && [ -n "${1:-}" ] && ! au_repair "$1"; then AU_RP_BAD=1; return 1; fi
  au_update_programs
  au_update_mac
  [ -n "${1:-}" ] || return 0
  if [ "$AU_JK" = build ]; then au_update_build "$1"; return $?; fi
  [ "$AU_JK" != repair ] || return 0
  au_switch_setting "$1"
}

au_update_build() { # RECIPE -> D3.6 step 3 for the build au_update_judge picked (AU_JPICK), after the yes and once
  # Auster's programs and `mac` are done: room worked out again (section C, with the disk measured now); the earlier
  # builds the disk rule names removed now that the room is needed, only if the question named each of them (so the one
  # before the build in use goes only on the person's yes); then the first install's steps 7 to 9, which skip a file
  # store/ holds by its sha256, ask the publisher, fetch from the address that names its commit with no login and the
  # person's curl settings ignored, resume from that same address, check the size then the sha256, delete a mismatch,
  # and keep the Mac awake during the model's download when `mac` says so (BD10); then the test in isolation and the
  # switch (au_update_test, D3.6 steps 4 and 5). 0 once switched and checked; 1 when this recipe stops, having said why:
  # its serving is the build it was, and the files fetched stay in store/, a cache the disk rule counts. A server check
  # that fails ends the run (4). After a repair of the build in use (AU_RP_DONE), section C judges again with the disk
  # as the repair left it: a move that no longer fits, or is no longer the one asked, stops here, and the repair's own
  # check follows (D3.6, "When the run moves the recipe to another build")
  local r=$1 pick=$AU_JPICK p=$AU_JP c=$AU_JC way=$AU_JWAY named=() l n ok jn
  named=(${AU_JREMOVE[@]+"${AU_JREMOVE[@]}"})
  au_update_disk
  au_update_judge "$r"
  if [ "$AU_RP_DONE" = 1 ] && { [ "$AU_J" != change ] || [ "$AU_JK" != build ] || [ "$AU_JPICK" != "$pick" ] ||
       [ "$AU_JP" != "$p" ] || [ "$AU_JC" != "$c" ]; }; then
    jn="$(printf '%s' "${AU_JNAME:0:1}" | tr 'A-Z' 'a-z')${AU_JNAME:1}"
    au_say "The build this Mac serves is whole again, but what this Mac can hold changed since the question: $jn is not moved, and keeps serving build $AU_JNOW."
    return 1
  fi
  if [ "$AU_J" != change ]; then
    au_say "$AU_J_SAY"
    return 1
  fi
  if [ "$AU_JK" != build ] || [ "$AU_JPICK" != "$pick" ] || [ "$AU_JP" != "$p" ] || [ "$AU_JC" != "$c" ]; then
    au_say "What this Mac can hold changed since the question. $AU_JNAME is not updated: it keeps serving build $AU_JNOW. \`auster update\` asks again."
    return 1
  fi
  for l in ${AU_JREMOVE[@]+"${AU_JREMOVE[@]}"}; do
    ok=0
    for n in ${named[@]+"${named[@]}"}; do [ "$n" != "$l" ] || ok=1; done
    if [ "$ok" = 0 ]; then
      au_split "$l"
      au_say "To make room now, build ${AU_F[4]:-} would have to be removed, which the question did not name. $AU_JNAME is not updated: it keeps serving build $AU_JNOW. \`auster update\` asks again."
      return 1
    fi
  done
  au_update_remove || {
    au_say "The earlier builds to remove could not all be read, so nothing more was removed. $AU_JNAME is not updated: it keeps serving build $AU_JNOW."
    return 1
  }
  AU_CH_BUILD=$pick
  au_mac_read
  AU_AWAKE=no
  [ "$AU_MAC" != ok ] || AU_AWAKE=${AU_MAC_LINES[6]#keep-awake"$AU_T"}
  au_step7_model || { au_say "$AU_JNAME is not updated: it keeps serving build $AU_JNOW."; return 1; }
  au_step8_assets || { au_say "$AU_JNAME is not updated: it keeps serving build $AU_JNOW."; return 1; }
  au_step9_engine || { au_say "$AU_JNAME is not updated: it keeps serving build $AU_JNOW."; return 1; }
  au_update_test "$r" "$way"
}

au_paused_take() { # -> builds/paused naming this run, by rename (D3.1: `auster-record 1`, the process, the boot session and the
  # process's start time, as the lock names it), so that the engine job, which launchd starts again, waits while this run
  # lives (B4 step 1, D3.6 step 4); AU_PAUSED=1 until au_paused_release, which au_cleanup calls too
  local t="$AU_DATA/builds/.paused.new.$$"
  rm -f "$t"
  printf 'auster-record 1\t%s\t%s\t%s\n' "$$" "$AU_BOOT" "$AU_SELF_START" > "$t" && chmod 600 "$t" &&
    mv -f "$t" "$AU_DATA/builds/paused" || { rm -f "$t"; return 1; }
  AU_PAUSED=1
}

au_paused_release() { # -> builds/paused removed, when this run wrote it
  [ "$AU_PAUSED" = 1 ] || return 0
  rm -f "$AU_DATA/builds/paused"
  AU_PAUSED=0
}

au_update_test() { # RECIPE WAY -> D3.6 steps 4 and 5 for the build au_update_build fetched (AU_CH_BUILD, with AU_ENGINE_DIR,
  # AU_PROGRAM and AU_LISTSHA from step 9) at AU_JP people and AU_JC tokens each, WAY being the way the question said (C5).
  # Fit is worked out again first, with the memory and the GPU limit measured anew: a build, setting or way other than the
  # question's stops the recipe, which never changes way silently (T31). The test (au_candidate_test): side by side for one
  # person at 8,192, while the engine job keeps serving (T16); in turn at the household's setting, once builds/paused names
  # this run and the engine is stopped by kickstart -k, so that launchd starts the job again and it waits while this run
  # lives (B4 step 1; a run that is killed ends the wait by itself, T25). The switch (step 5): on a pass the old descriptor
  # copied into kept/ first, then serving replaced in one rename, the registry's lines byte for byte with this tree's and
  # a speed of 0 (A5, T33, T55), and the build out of failed/ (`update --retry`, T99); on a fail the candidate's descriptor
  # into failed/, serving untouched (T9). Then the engine runs again, after a pass and after a fail alike (T115): in turn
  # by removing paused, side by side by kickstart -k (au_engine_start). Then the server check (B3 step 13): after a pass,
  # au_switch_check, whose speed becomes this Mac's baseline for the build (T60) and which ends the run with exit 4 naming
  # `auster rollback` when it fails (T109); after a fail, passed says the test failed, and not answered ends the run with
  # exit 4 naming `auster restart`, since serving is the build it was (T32, T115). 0 once switched and checked; 1 when the
  # recipe stopped, having said why (exit 3 at the end)
  local r=$1 way=$2 pick=$AU_JPICK p=$AU_JP c=$AU_JC rc=0 tp=1 tc=8192 up=1 i now f
  if ! au_update_measure again; then
    au_say "This Mac's memory cannot be read now (sysctl hw.memsize), so build $pick was not tested. $AU_JNAME keeps serving build $AU_JNOW."
    return 1
  fi
  au_update_judge "$r"
  if [ "$AU_J" != change ]; then
    au_say "$AU_J_SAY"
    return 1
  fi
  if [ "$AU_JK" != build ] || [ "$AU_JPICK" != "$pick" ] || [ "$AU_JP" != "$p" ] || [ "$AU_JC" != "$c" ]; then
    au_say "What this Mac can hold changed since the question. $AU_JNAME is not updated: it keeps serving build $AU_JNOW. \`auster update\` asks again."
    return 1
  fi
  if [ "$AU_JWAY" != "$way" ]; then
    if [ "$way" = side-by-side ]; then
      au_say "Worked out again before the test, this Mac can no longer hold both builds at once, as the question said it could."
    else
      au_say "Worked out again before the test, this Mac can now hold both builds at once, which the question did not say."
    fi
    au_say "$AU_JNAME is not updated: it keeps serving build $AU_JNOW. Build $pick's files stay on this Mac, and \`auster update\` asks again."
    return 1
  fi
  now=$AU_JNOW
  au_serving_read "$r"
  if [ "$way" = in-turn ]; then
    tp=$p tc=$c
    au_paused_take || { au_say "builds/paused could not be written, so build $pick was not tested. $AU_JNAME keeps serving build $now."; return 1; }
    if au_job_loaded "$AU_LABEL_ENGINE"; then
      au_say "This Mac cannot hold both builds at once: the server stops while build $pick is tested."
      launchctl kickstart -k "gui/$AU_UID/$AU_LABEL_ENGINE" > /dev/null 2>&1
    fi
    for ((i = 0; i < 60; i++)); do nc -z -w 1 127.0.0.1 "$AU_SV_PORT" > /dev/null 2>&1 || break; sleep 1; done
    if [ "$i" = 60 ]; then
      au_paused_release
      au_say "The server did not stop within a minute, so build $pick was not tested. $AU_JNAME keeps serving build $now."
      return 1
    fi
  else
    au_say "This Mac can hold both builds at once: build $pick is tested beside the one serving, which keeps answering."
  fi
  au_candidate_test "$tp" "$tc" || rc=$?
  au_serving_read "$r"
  AU_PEOPLE=$p AU_CONTEXT=$c AU_PORT=$AU_SV_PORT
  if [ "$rc" = 0 ]; then
    au_say "Build $pick passed the recipe's test on this Mac, so it now serves in place of build $now..."
    au_kept_add "$r" || au_stop "What it serves now could not be kept (builds/$r/kept), so the build was not changed."
    AU_CHANGED=1
    au_descriptor "$AU_DATA/builds/$r/serving" 0 || au_stop "The record of what serves (builds/$r/serving) could not be written."
    for f in "$AU_DATA/builds/$r"/failed/*-"$pick"; do [ -f "$f" ] && rm -f "$f"; done   # tried again, and it passed
  elif [ "$rc" = 1 ]; then
    au_say "Build $pick did not pass the recipe's test on this Mac. $AU_JNAME stays on build $now."
    au_mkdir "$AU_DATA/builds/$r/failed" && au_descriptor "$AU_DATA/builds/$r/failed/$(au_now)-$pick" 0 ||
      au_stop "The build failed its test, and its record could not be written."
  else
    au_say "A key for the test could not be made, so build $pick was not tested. $AU_JNAME stays on build $now."
  fi
  if [ "$way" = in-turn ]; then
    AU_T0=$(date +%s)
    au_paused_release
    au_job_loaded "$AU_LABEL_ENGINE" || au_engine_start || up=0
  else
    au_engine_start || up=0
  fi
  AU_RP_WAIT=   # the check below is a repair's too: the engine now runs on the files it put back (D3.6)
  if [ "$rc" = 0 ]; then
    if [ "$up" = 0 ]; then
      au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
      au_say "Nothing switches back by itself: \`auster rollback\` goes back to what it served before, with no download."
      exit 4
    fi
    au_switch_check "$r"
    return 0
  fi
  if [ "$up" = 0 ]; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_say "Serving is still build $now: \`auster restart\` starts it again and checks it."
    exit 4
  fi
  au_say "Checking the server on the home network, on build $now..."
  au_server_check "$r" "$AU_T0"
  case "$AU_CHECK" in
    passed)
      au_say "The server answered on build $now, at $AU_CHECK_SPEED tokens a second, and refused a request with no key."
      [ "$rc" != 1 ] || au_say "$AU_JNAME keeps serving build $now; build $pick is not offered again until \`auster update --retry\`."
      return 1 ;;
    open)
      au_say "The server did not refuse a request that carried no key, so Auster stopped it. It stays stopped until \`auster start\`."
      exit 4 ;;
    *)
      au_say "The server did not answer its check within $AU_CHECK_SECS s: $AU_CHECK_WHY. \`auster status\` says how the engine's last start went."
      au_say "Serving is still build $now, which it was before the test: \`auster restart\` starts it again and checks it."
      exit 4 ;;
  esac
}

au_update_remove() { # -> the earlier builds the disk rule named (AU_JREMOVE), removed now that the room is needed (D3.6 step 3,
  # C6), by common/auster's au_builds_remove, which `auster cleanup` shares: each entry of kept/ or failed/ deleted, then each
  # file in store/ and engines/ it named that no descriptor left, of any recipe, names, and that is not the chosen build's (C6:
  # never the build in use's, which serving names, nor the chosen one's). 1, with no file of store/ or engines/ deleted, when
  # an entry named, or a descriptor left, cannot be read
  local x keep=
  for x in 23 30 8 9 10; do keep+="store/$(au_build_field "$AU_JPICK" "$x")"$'\n'; done
  keep+="engines/$(au_build_field "$AU_JPICK" 23)"
  au_builds_remove "$keep" ${AU_JREMOVE[@]+"${AU_JREMOVE[@]}"}
}

au_update_programs() { # -> B3 step 6 after the yes (BD18, T94), once a run, before anything else changes or is fetched,
  # on the build already serving; only a repair of the build in use comes before it (au_repair, D3.6), so that its
  # restart meets the files the build was tested with and a failure here is still the programs' alone. When Auster's own
  # programs change: the new bin/auster answers `status` once from its temporary name, or nothing is renamed and the run
  # ends with exit 3 (after a repair, saying that the files it put back stay whole); the programs in use are copied into
  # jobs/previous/, unless it exists (an earlier change never checked: nothing is copied over it); the new ones are put
  # in place by rename (AU_PROGRAMS_IN). Then, and also when jobs/previous/ is there with the programs unchanged, the
  # engine is restarted and the server checked (step 13), which serve as a repair's too: passed deletes jobs/previous/
  # and the update goes on; open and not answered end the run with exit 4, naming `auster rollback`, which puts the
  # previous programs back. Nothing is put back by itself
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
      if [ "$AU_RP_DONE" = 1 ]; then   # after a repair (D3.6): its files stay, and the next start takes them up
        au_say "The auster command of $AU_VERSION did not answer \`auster status\` on this Mac, so none of Auster's programs was changed."
        au_say "The files put back above stay whole; the server takes them up at its next start."
      else
        au_say "The auster command of $AU_VERSION did not answer \`auster status\` on this Mac, so none of Auster's programs was changed, and nothing else was either."
      fi
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
    AU_CHANGED=1 AU_PROGRAMS_IN=1
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
  AU_RP_WAIT=   # this restart and check are a repair's too (D3.6, "Order against B3 step 6")
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
  AU_RP_WAIT=   # the switch's restart and check are a repair's too (D3.6, "No restart of its own")
  if ! au_engine_start; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_say "Nothing switches back by itself: \`auster rollback\` goes back to what it served before, with no download."
    exit 4
  fi
  au_switch_check "$r"
}

au_switch_check() { # RECIPE -> the server check (B3 step 13) after a switch, of setting (au_switch_setting) or of build
  # (au_update_test), once the engine runs again from AU_T0 on the new serving: passed writes its speed into serving, this
  # Mac's baseline for what it now serves (A5), and returns; open and not answered end the run with exit 4, naming
  # `auster rollback`, which goes back with no download. Nothing switches back by itself, and nothing goes in failed/
  local r=$1
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

au_update_check() { # B3 step 13 before step 15, on a run that changed nothing or after its changes passed: a recipe
  # whose serving has a speed of 0 has not passed a server check since its switch (A5), and jobs/previous/ means that
  # Auster's programs have not passed one since an update changed them (B3 step 6, T94); a repair that completed with no
  # restart after it (AU_RP_WAIT) has its check here (D3.6, "No restart of its own"); and a recipe whose engine job's
  # last start is engine-hash, whose serving can be read and whose files all match (a repair is made otherwise, or with
  # several recipes none is checked), is checked too, so that a second paste never ends 0 while the engine job refuses
  # its files (D3.6). Each way the engine is started again, as `auster start` starts it, and checked before step 15
  # writes the stamp. Passed goes on (and deletes jobs/previous/); open and not answered end the run with exit 4 and no
  # stamp. A run whose repair was passed over or failed never comes here (au_repair_end)
  local r need=() prev=0 why=speed
  if [ -e "$AU_DATA/jobs/previous" ] || [ -L "$AU_DATA/jobs/previous" ]; then prev=1; fi
  for r in "${AU_URECIPES[@]}"; do
    au_serving_read "$r" || continue
    if [ "$AU_SV_SPEED" = 0 ] || [ "$prev" = 1 ]; then need+=("$r")
    elif [ "$AU_RP_WAIT" = "$r" ]; then need+=("$r"); why=repair
    elif au_start_read "$r" && [ "$AU_ST_CODE" = engine-hash ]; then need+=("$r"); [ "$why" = repair ] || why=hash
    fi
  done
  [ "${#need[@]}" -gt 0 ] || return 0
  if [ "$prev" = 1 ]; then
    au_say "Auster's own programs were changed by an earlier update whose server check never passed (jobs/previous holds the ones before), so the server is started again and checked on the home network before anything else..."
  elif [ "$why" = repair ]; then
    au_say "The files of the build this Mac serves are whole again, so the server is started again on them and checked on the home network..."
  elif [ "$why" = hash ]; then
    au_say "The engine job's last start found a file it checks changed (engine-hash), and every file of the build is whole now, so the server is started again and checked on the home network..."
  else
    au_say "The server has not passed a check since its build was last switched, so it is started again and checked on the home network..."
  fi
  if ! au_engine_start; then
    au_say "launchd did not start Auster's engine job, so the server was not checked. \`auster status\` says why."
    au_update_unfinished "${need[0]}"
    exit 4
  fi
  AU_RP_WAIT=
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
  # and nothing changed; 3 a recipe passed over (before its question, at its download or before its test), a new build
  # that failed its test, a new bin/auster that does not answer `status`, or a repair of the build in use passed over or
  # failed (au_repair_end); 4 the server check failed
  local s r no=0 short=0 asked=0 did=0
  AU_UPDATING=1   # a download that fails stops its recipe, not the run (au_fail)
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
    [ "$AU_J:$AU_JK" != change:build ] || au_update_ask
    AU_RP=
    [ "${#AU_URECIPES[@]}" != 1 ] || au_update_files "$r"   # one recipe at most has a repair (BD14): with several, none
    if [ -n "$AU_RP" ]; then   # a repair, whatever else the run does with the recipe (D3.6, "A repair")
      AU_RP_RECIPE=$r
      case "$AU_J" in
        ok|change) ;;
        *) au_say "$AU_J_SAY"; [ "$AU_JMOVEOFF" = 0 ] || short=1 ;;   # it keeps serving its build: the question is the repair's
      esac
      if ! au_repair_ask "$r"; then au_say "$AU_RP_SAY"; AU_RP_BAD=1 short=1; continue; fi
      [ "$AU_J" = change ] || AU_J=change AU_JK=repair
    fi
    case "$AU_J" in
      ok|held) au_say "$AU_J_SAY" ;;
      change) asked=1; if au_update_question; then au_update_yes "$r" || short=1; did=1; else no=1; fi ;;
      *) au_say "$AU_J_SAY"; short=1 ;;
    esac
  done
  if [ "$asked" = 0 ] && [ "$AU_PROGRAMS_CHANGE" = 1 ] && [ "$AU_RP_BAD" = 0 ]; then
    if au_update_programs_question; then au_update_yes; did=1; else no=1; fi
  fi
  if [ "$no" = 1 ]; then
    if [ "$did" = 0 ]; then au_undo; exit 1; fi
    short=1   # another recipe's no: not everything was updated
  fi
  [ "$AU_RP_BAD" = 0 ] || au_repair_end   # D3.6: no restart, no server check, no program changed and no step 15
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

au_people_files() { # RECIPE -> D3.6, "auster people": it fetches nothing and repairs nothing, and before any restart it
  # checks what the engine job checks at every start (B4 step 4): the engine's unpacked files against serving's list
  # sha256, with llama-server executable (au_engine_whole), the template and the system prompt; never the model's hash.
  # serving is read again. One that has changed makes the recipe refused (AU_J), naming the installer line, which
  # fetches it again
  local what=
  au_serving_read "$1" || return 0
  au_engine_whole "$AU_DATA/engines/$AU_SV_ENGINE" "$AU_SV_LIST" || what="the engine's files"
  au_store_has "$AU_SV_TEMPLATE" || what+="${what:+, }the template"
  au_store_has "$AU_SV_SYSTEM" || what+="${what:+, }the system prompt"
  [ -n "$what" ] || return 0
  AU_J=refused AU_J_SAY="A file of the build this Mac serves has changed ($what). Pasting the installer line again fetches it again."
}

au_people() { # -> `auster people <n>` (B6, C4; T112), run by release's install.sh with `people <n>` and so from
  # release's newest tree: the update's procedure for the build each recipe serves, at AU_PEOPLE_N people. This tree's
  # registry gives the recipe's limits (1 to its default), and section C the largest context per person that fits (C4),
  # for the build served only. A setting that would change goes to the question (au_update_question), and on a yes it is
  # the update's switch (au_switch_setting), after the server check that jobs/previous/ calls for, made first as an
  # update makes it (au_update_programs, which changes no program here). No other build is chosen, nothing is downloaded
  # or tested, none of Auster's programs is changed, and no stamp and no `mac` are written, even when this tree is of a
  # newer version (B6). Nothing is repaired either: a change is refused before the question while a file the engine job
  # checks at every start has changed (au_people_files, D3.6). Exits: 0 done, or nothing to change; 1 refused or
  # answered no, and nothing changed; 3 a recipe not changed while another was; 4 the server check
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
    [ "$AU_J" != change ] || au_people_files "$r"   # D3.6: before any restart, refused while a file it checks has changed
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
    update|remove) AU_RECIPE=; if [ "$AU_MODE" = update ] && [ "${1:-}" = --retry ]; then AU_RETRY=1; shift; fi ;;
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
    au_tm_said
    au_update
  fi
  if [ "$AU_MODE" = people ]; then   # B6, from `auster people <n>` (install.sh people <n>)
    [ "$AU_ROOT_NEW" = 0 ] || au_refuse "Auster is not installed on this Mac, so there is no number of people to change."
    AU_REG="$AU_TREE/registry.tsv"   # the recipe's limits from this tree's registry (B6)
    au_step3_root
    au_tm_said
    au_people
  fi
  au_registry
  au_bd14
  au_step3_root
  if [ -e "$AU_DATA/builds/$AU_RECIPE/serving" ] || [ -L "$AU_DATA/builds/$AU_RECIPE/serving" ]; then
    au_tm_said
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
