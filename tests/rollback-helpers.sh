# Sourced by the rollback's tests (U6: T12, T27, T57, and the rollback clauses of T94, T107, T109 and T112) after lib.sh,
# helpers.sh, install-helpers.sh, job-helpers.sh, command-helpers.sh and update-run-helpers.sh:
#   model_in MODEL      that model's stand-in (IMA or IMB) put in store/, read-only, whole
#   kept_put BUILD MODEL PEOPLE CONTEXT [SPEED [DATE]]   an entry of builds/<recipe>/kept/ for that build at that setting,
#                       named by DATE (2026-11-20T10:00:00Z by default) and the build, written as job-helpers.sh's
#                       serving_put writes serving (the installed engine's list, its template put in store/), with its
#                       model put in store/; SPEED 36.9 by default
#   hold_ids            the build ids in builds/<recipe>/hold, one a line after its format line, or "none" without a hold
#   watch_serving BUILD PEOPLE CONTEXT   in the background: once serving names BUILD at PEOPLE and CONTEXT, the speed its
#                       launch line holds then, into $W/watched ("never" if not within 30 s); WATCH is its process
model_in() {
  local name sha
  case "$1" in "$IMA") name=standin-a.gguf sha=$SA ;; "$IMB") name=standin-b.gguf sha=$SB ;; *) return 1 ;; esac
  [ ! -f "$DATA/store/$sha" ] || chmod 644 "$DATA/store/$sha"
  cp "$FX/models/$name" "$DATA/store/$sha" && chmod 444 "$DATA/store/$sha"
}

kept_put() {
  local s="$DATA/builds/$IR/serving" keep="$W/kept-put.serving"
  cp -p "$s" "$keep"
  serving_put "$1" "$2" "$3" "$4" "${5:-36.9}"
  mkdir -p "$DATA/builds/$IR/kept"
  mv "$s" "$DATA/builds/$IR/kept/${6:-2026-11-20T10:00:00Z}-$1"
  chmod 600 "$DATA/builds/$IR/kept/${6:-2026-11-20T10:00:00Z}-$1"
  mv "$keep" "$s"
  model_in "$2"
}

hold_ids() {
  local f="$DATA/builds/$IR/hold"
  if [ ! -e "$f" ]; then echo none; return 0; fi
  [ "$(head -n 1 "$f")" = 'auster-record 1' ] || { echo "a hold of another form: $(head -c 200 "$f")"; return 0; }
  tail -n +2 "$f"
}

watch_serving() {
  local b=$1 p=$2 c=$3 s="$DATA/builds/$IR/serving"
  rm -f "$W/watched"
  ( for i in $(seq 600); do
      if [ "$(sed -n 2p "$s" 2>/dev/null | cut -f2) $(sed -n 5p "$s" 2>/dev/null | cut -f2,3)" = "$b $p	$c" ]; then
        sed -n 5p "$s" | cut -f6 > "$W/watched"; exit 0
      fi
      sleep 0.05
    done
    echo never > "$W/watched" ) &
  WATCH=$!
}
