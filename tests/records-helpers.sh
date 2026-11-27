# Sourced by the tests of D3.1's records (U2: T6 and T95's tables) after lib.sh, helpers.sh and install-helpers.sh
# (for its ids). It makes a data root by hand, with no install, and runs each reader of each record on it:
#   records_env         W, a work folder; D, a data root (mode 0700, its marker, every record of D3.1 in its form);
#                       common/auster loaded with AU_DATA=$D; the engine job's and the check job's readers taken out
#                       of their programs into $W/engine-readers.sh and $W/check-readers.sh (they load nothing, so
#                       their functions are what the jobs run); and the shell moved to $RUN, where `f` would be made
#   RECORDS             every record, by a name of its own
#   path_of REC         where REC lives in D
#   good REC FILE       REC in its form, as Auster writes it, into FILE
#   readers_of REC      the readers of REC: `auster.*` common/auster's (the driver's and bin/auster's), `engine.*` and
#                       `check.*` the jobs', `updates.*` the rule file's (its descriptor and hold readers since U3),
#                       `js.mac` section C's (capability-lib.js)
#   read_with READER FILE   one word: ok (read, and equal to what `good` wrote), absent, newer, unreadable (a hold
#                       that passes its recipe over), unknown (stopped, the reason unknown), or other
#   make_case REC CASE FILE   FILE as one of T6's cases: link (to a good copy), folder, big (beyond its bound),
#                       line (a line more), field (a field more on its last line), name (an entry of kept/ or failed/
#                       not named by its date and build), or hostile:L:F (field F of line L, from 1, made
#                       a[$(touch f)])
#   cases_of REC        T6's cases for REC, one a line
#   newer_of REC CASE FILE   FILE as one of T95's: same (format 2, format 1's fields), field (format 2 with a field
#                       more, a one-line record), big (format 2, beyond the bound)
RECORDS="serving kept failed hold start mac updating paused stopped scripts offer tried noted engine local-name"
HOSTILE='a[$(touch f)]'

records_env() {
  local b
  W=$(mktemp -d "${TMPDIR%/}/records.XXXXXX")
  D="$W/data"
  RUN="$W/run"
  mkdir -m 700 "$D" "$D/builds" "$D/store" "$D/engines" "$D/keys" "$D/logs" "$D/bin" "$D/jobs" "$D/_update" \
    "$D/builds/$IR" "$D/builds/$IR/kept" "$D/builds/$IR/failed"
  mkdir "$RUN"
  : > "$D/.auster-data-root"
  . "$ROOT/common/auster"
  AU_DATA=$D AU_UID=$(id -u) AU_USER=$(id -un)
  RB=$(sysctl -n kern.bootsessionuuid)
  RL=$(au_trim "$(ps -p $$ -o lstart=)")   # the test's own shell: a lock or paused naming it names a live process
  for b in engine check; do
    sed -n -E -e '/^RE_[A-Z0-9_]+=/p' -e '/^T=/p' -e '/^(split|trim|size|sha|ends_in_newline)\(\) \{.*\}$/p' \
      -e '/^(live|paused_live|read_serving|mac_read|start_address|state_read)\(\) \{/,/^\}/p' "$ROOT/common/auster-$b" > "$W/$b-readers.sh"
  done
  printf '%s\n' 'ObjC.import("Foundation");' \
    'function auLoad(p) { return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null)); }' \
    'function run(argv) {' \
    '  eval(auLoad(argv[0] + "/common/registry-lib.js")); eval(auLoad(argv[0] + "/common/capability-lib.js"));' \
    '  var g = auCapReadFile(argv[1], AU_CAP_MAX.mac);' \
    '  return (g.ok ? auCapParseMac(g.bytes, g.big) : { state: "absent" }).state;' \
    '}' > "$W/mac.js"
  for b in $RECORDS; do good "$b" "$(path_of "$b")"; done
  cd "$RUN" || return 1
}

path_of() {
  case "$1" in
    serving|hold|start) printf '%s' "$D/builds/$IR/$1" ;;
    kept) printf '%s' "$D/builds/$IR/kept/2026-11-20T10:00:00Z-$IB1" ;;
    failed) printf '%s' "$D/builds/$IR/failed/2026-11-21T10:00:00Z-$IB1" ;;
    mac|updating|paused|stopped|local-name) printf '%s' "$D/builds/$1" ;;
    scripts|offer|tried|noted|engine) printf '%s' "$D/_update/$1" ;;
  esac
}

good() {
  local s=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  case "$1" in
    serving|kept|failed)
      printf 'auster-descriptor 1\n'
      printf 'build\t%s\t%s\t%s\t%s\t%s\t%s\t41923\t333\t484\t23040\t0\t0.95\tdev-mac-64gb\n' "$IB1" "$IE" "$IMA" "$s" "$s" "$s"
      printf 'engine\t%s\tmacos-arm64\tb12359\tllama-b12359-bin-macos-arm64.tar.gz\t17000000\t%s\t14\n' "$IE" "$s"
      printf 'model\t%s\t%s\t%s\tstandin-a.gguf\t3400\t%s\tapache-2.0\tendorsed\t262144\n' "$IMA" "$REPO_A" "$COMMIT_A" "$SA"
      printf 'launch\t4\t32768\t8484\t%s\t36.9\n' "$s" ;;
    hold) printf 'auster-record 1\n%s\n%s\n' "$IB1" "$IB2" ;;
    start) printf 'auster-record 1\ncode\tstarting\naddress\t10.0.0.5\nboot\t%s\ntime\t1800000000\n' "$RB" ;;
    mac) printf 'auster-record 1\ngpu-mib\t53084\nmemory-bytes\t68719476736\nmacos\t27.2.1\nmeasured\t2026-11-26T15:04:05Z\nrouter\t0a:1b:2c:3d:4e:5f\nkeep-awake\tno\n' ;;
    updating|paused) printf 'auster-record 1\t%s\t%s\t%s\n' "$$" "$RB" "$RL" ;;
    stopped) printf 'auster-record 1\thousehold\t2026-11-26T08:00:00Z\n' ;;
    scripts) printf 'auster-record 1\trelease\tv0.1.0\t%s\t2026-11-27T10:00:00Z\n' "$COMMIT" ;;
    offer) printf 'auster-record 1\tv0.2.0\t1799990000\n' ;;
    tried) printf 'auster-record 1\t1799999000\n' ;;
    noted) printf 'auster-record 1\tv0.2.0\t2\n' ;;
    engine) printf 'auster-record 1\nprobe\tok\t36.9\t1799999000\nfailures\t0\naddress\t10.0.0.5\ntold-probe\t-\ntold-address\t-\ntold-fit\tno\n' ;;
    local-name) printf 'auster-record 1\ttest-mac\t2026-11-27T10:00:00Z\n' ;;
  esac > "$2"
}

readers_of() {
  case "$1" in
    serving) echo auster.desc engine.serving check.serving updates.serving ;;
    kept|failed) echo auster.entry updates.entry ;;
    hold) echo auster.hold updates.hold ;;
    start) echo auster.start check.start ;;
    mac) echo auster.mac engine.mac check.mac js.mac ;;
    updating) echo auster.lock check.live ;;
    paused) echo engine.paused check.paused ;;
    stopped) echo auster.stopped ;;
    scripts) echo auster.scripts updates.scripts ;;
    offer) echo updates.offer ;;
    tried) echo updates.tried ;;
    noted) echo updates.noted ;;
    engine) echo auster.probe check.state ;;
    local-name) echo auster.localname ;;
  esac
}

_tok() { case "$1" in 0) echo ok ;; 2) echo newer ;; *) echo absent ;; esac; }
_job() { # engine|check COMMAND... -> the job's readers loaded in a subshell, with its DATA and BOOT, then COMMAND's code
  ( . "$W/$1-readers.sh"; DATA=$D BOOT=$RB PAUSE_SECS=1800; shift; "$@" ) > /dev/null 2>&1
}
_upd() { ( AU_UPDATE_DIR=$D/_update; . "$ROOT/common/updates.sh"; "$@" ) 2>/dev/null; }

read_with() {
  local r=$1 f=$2 rc=0 o
  case "$r" in
    auster.desc) au_desc_read "$f" || rc=$?; _tok $rc ;;
    auster.entry) au_entry_read "$f" || rc=$?; _tok $rc ;;
    auster.hold)
      au_hold_read "$IR"
      if [ "$AU_HOLD" = ok ]; then [ "${AU_HOLD_IDS[*]:-}" = "$IB1 $IB2" ] && echo ok || echo other; else echo "$AU_HOLD"; fi ;;
    auster.start)
      au_start_read "$IR" || rc=$?
      if [ "$rc" = 0 ]; then [ "$AU_ST_CODE:$AU_ST_ADDR:$AU_ST_TIME" = starting:10.0.0.5:1800000000 ] && echo ok || echo other; else _tok $rc; fi ;;
    auster.mac) au_mac_read; echo "$AU_MAC" ;;
    auster.lock) au_lock_read "$f"; case "$AU_LOCK" in held) echo ok ;; *) echo "$AU_LOCK" ;; esac ;;
    auster.stopped)
      au_stopped_read
      case "$AU_STOPPED:$AU_STOPPED_WHY" in yes:household) echo ok ;; yes:unknown) echo unknown ;; newer:*) echo newer ;; no:*) echo absent ;; *) echo other ;; esac ;;
    auster.scripts)
      au_line_read "$f" 4 || rc=$?
      if [ "$rc" = 0 ]; then [ "${AU_LF[*]}" = "release v0.1.0 $COMMIT 2026-11-27T10:00:00Z" ] && echo ok || echo absent; else _tok $rc; fi ;;
    auster.probe) au_probe_read || rc=$?; [ "$rc:$AU_PR_RESULT:$AU_PR_SPEED" = 0:ok:36.9 ] && echo ok || _tok $rc ;;
    auster.localname) au_localname_read; [ "$AU_LN:$AU_LN_NAME" = ok:test-mac ] && echo ok || echo "$AU_LN" ;;
    engine.serving|check.serving) _job "${r%.*}" read_serving "$f" || rc=1; _tok $rc ;;
    engine.mac|check.mac) _job "${r%.*}" mac_read || rc=1; _tok $rc ;;
    check.start) _job check start_address "$IR" || rc=1; _tok $rc ;;
    check.live) _job check live "$f" 0 || rc=1; _tok $rc ;;
    check.paused) _job check live "$f" 1800 || rc=1; _tok $rc ;;
    engine.paused) _job engine paused_live || rc=1; _tok $rc ;;
    check.state) ( . "$W/check-readers.sh"; DATA=$D; state_read || exit 2; [ "$ST_RESULT:$ST_SPEED" = ok:36.9 ] ) > /dev/null 2>&1 || rc=$?; _tok $rc ;;
    js.mac) osascript -l JavaScript "$W/mac.js" "$ROOT" "$f" 2>/dev/null ;;
    updates.scripts)
      o=$(_upd eval '_auu_state versions; printf "%s:%s" "$AUU_INSTALLED" "$AUU_DETAIL"')
      case "$o" in v0.1.0:*) echo ok ;; *:newer) echo newer ;; *) echo absent ;; esac ;;
    updates.serving) _upd _auu_desc "$f" || rc=$?; _tok $rc ;;
    updates.entry) _upd _auu_entry "$f" || rc=$?; _tok $rc ;;
    updates.hold)
      o=$(_upd eval "_auu_hold $IR; printf '%s:%s' \"\$AUU_HOLD\" \"\${AUU_HOLD_IDS[*]:-}\"")
      case "$o" in "ok:$IB1 $IB2") echo ok ;; ok:*) echo other ;; *) echo "${o%%:*}" ;; esac ;;
    updates.offer) o=$(_upd _auu_offer) || rc=$?; [ "$rc:$o" = 0:v0.2.0 ] && echo ok || _tok $rc ;;
    updates.tried)
      o=$(_upd eval '_auu_read "$AU_UPDATE_DIR/tried" 1 || exit $?; [[ ${_AUU_F[0]} =~ $_AUU_TIME ]] || exit 1; printf %s "${_AUU_F[0]}"') || rc=$?
      [ "$rc:$o" = 0:1799999000 ] && echo ok || _tok $rc ;;
    updates.noted)
      o=$(_upd eval '_auu_read "$AU_UPDATE_DIR/noted" 2 || exit $?; [[ ${_AUU_F[0]} =~ $_AUU_VER ]] && [[ ${_AUU_F[1]} =~ ^[12]$ ]] || exit 1; printf %s "${_AUU_F[*]}"') || rc=$?
      [ "$rc:$o" = "0:v0.2.0 2" ] && echo ok || _tok $rc ;;
    *) echo "read_with: $r?" ;;
  esac
}

cases_of() {
  local n l f
  echo link; echo folder; echo big; echo line; echo field
  case "$1" in kept|failed) echo name ;; esac
  good "$1" "$W/cases.tmp"
  n=0
  while IFS= read -r l; do
    n=$((n + 1))
    f=$(printf '%s\n' "$l" | awk -F'\t' '{ print NF }')
    for ((i = 1; i <= f; i++)); do echo "hostile:$n:$i"; done
  done < "$W/cases.tmp"
}

make_case() {
  local rec=$1 c=$2 f=$3 i
  rm -rf "$f" "$W/elsewhere"
  case "$c" in
    link) good "$rec" "$W/elsewhere"; ln -s "$W/elsewhere" "$f" ;;
    folder) mkdir "$f"; good "$rec" "$f/inside" ;;
    big) good "$rec" "$W/case.tmp"; awk 'BEGIN { x = sprintf("%9000s", ""); gsub(/ /, "x", x) } { l[NR] = $0 } END { for (i = 1; i < NR; i++) print l[i]; print l[NR] x }' "$W/case.tmp" > "$f" ;;
    line)
      good "$rec" "$f"
      if [ "$rec" = hold ]; then for ((i = 0; i < 63; i++)); do echo "$IB1"; done >> "$f"; else tail -n 1 "$f" >> "$f.more"; cat "$f.more" >> "$f"; rm -f "$f.more"; fi ;;
    field) good "$rec" "$W/case.tmp"; awk -v t="$(printf '\t')" '{ l[NR] = $0 } END { for (i = 1; i < NR; i++) print l[i]; print l[NR] t "extra" }' "$W/case.tmp" > "$f" ;;
    name) good "$rec" "$f"; mv "$f" "${f%/*}/$IB1" ;;
    hostile:*)
      good "$rec" "$W/case.tmp"
      awk -F'\t' -v OFS='\t' -v L="$(printf '%s' "$c" | cut -d: -f2)" -v F="$(printf '%s' "$c" | cut -d: -f3)" -v h="$HOSTILE" \
        'NR == L { $F = h } { print }' "$W/case.tmp" > "$f" ;;
  esac
}

newer_of() {
  local rec=$1 c=$2 f=$3 two
  rm -rf "$f"
  good "$rec" "$W/case.tmp"
  case "$rec" in serving|kept|failed) two='auster-descriptor 2' ;; *) two='auster-record 2' ;; esac
  awk -F'\t' -v OFS='\t' -v two="$two" 'NR == 1 { $1 = two } { print }' "$W/case.tmp" > "$W/case2.tmp"
  case "$c" in
    same) cp "$W/case2.tmp" "$f" ;;
    field) awk -v t="$(printf '\t')" '{ print $0 t "more" }' "$W/case2.tmp" > "$f" ;;
    big) awk 'BEGIN { x = sprintf("%9000s", ""); gsub(/ /, "x", x) } { l[NR] = $0 } END { for (i = 1; i < NR; i++) print l[i]; print l[NR] x }' "$W/case2.tmp" > "$f" ;;
  esac
}
