# Sourced by the update run's tests (U4: T5's `auster update` half, T7, T19, T26's update half, T35's `auster update`
# clause, T38, T44 after an update, T46, T54's update half, T65, T84's update, T91's question) after lib.sh, helpers.sh,
# install-helpers.sh, job-helpers.sh and command-helpers.sh:
#   update_install [make_home option...]   cmd_install, the route to release's install.sh, and a TMPDIR of the test's own
#                       ($W/tmp/), so that the .command files it looks for are its own and not an earlier test file's
#   INSTALL_SH          release's install.sh, the address the update's .command file fetches; routed to $ROOT's
#   release_at VERSION COMMIT [ORDER...]   release names COMMIT (GitHub's API), whose tree holds a registry of VERSION
#                       with that order (install_registry's; order 1 then order 2 by default) and a changelog of VERSION
#   waiting_b1          the Mac made to serve order 2 for four people at 32,768 (serving_put), with order 1 waiting: model A
#                       taken out of store/, and _update's registry and offer those of v0.1.0, as a check leaves them
#   repaste ANSWERS     the installer line pasted again, for the recipe: output in $W/out, exit code in RC
#   update_run ANSWERS  install.sh update, as the update's .command runs it: output in $W/out, exit code in RC
#   opened              the paths of the files the stub open was asked to open, one a line
#   run_command PATH ANSWERS   that .command file run as Terminal runs it, with HOME=$H, the questions answered from
#                       ANSWERS and the QR code drawn on $W/screen: output in $W/out, exit code in RC
#   data_snap           a snapshot of the data root (tests/helpers.sh snapshot), logs/ left out
#   job_calls N         the stub launchctl's calls after line N of STUB_LOG that start, stop or change a job
#   engine_pid          the process of the engine the engine job started, or none
#   says_not TEXT LABEL ok when the run's output does not hold TEXT
# and for the test in isolation and the switch (U5's last part: T9, T16, T24, T25, T28, T31 to T33, T55, T60, T94, T99,
# T109, T115):
#   CPORT               the candidate's port, the first free one from 18484 (B3 step 10)
#   big_mac             a Mac with a GPU limit of 100,000 MiB and 128 GB of memory, on which order 2 serving four at
#                       32,768 and order 1 for one at 8,192 fit at once: the update tests side by side (C5)
#   start_on PORT       the stub engine's newest start folder whose --port is PORT, or nothing
#   arg_of START OPTION the value the engine of that start folder was given for OPTION
#   during_test FUNCTION   in the background: once a candidate registers on CPORT, FUNCTION runs once, its output in
#                       $W/during ("no candidate" if none came within 30 s); DURING is its process, to wait for
#   candidate_slow [SECS]  the candidate answers every request, /health too, with 503 for SECS (2) after its start, so
#                       that during_test has that long with the candidate alive
CPORT=18484
INSTALL_SH=https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/install.sh

big_mac() { export AU_GPU_MIB=100000 STUB_MEMSIZE=137438953472; }

start_on() {
  local s
  for s in $(ls -d "$STUB_ENGINE_DIR"/starts/* 2>/dev/null | sort -r); do
    [ "$(sed -n '/^--port$/{n;p;}' "$s/args")" = "$1" ] && { printf '%s' "$s"; return 0; }
  done
}

arg_of() { sed -n "/^$2\$/{n;p;}" "$1/args"; }

during_test() {
  local f=$1
  rm -f "$W/during"
  ( for i in $(seq 600); do
      if [ -f "$STUB_ENGINE_DIR/ports/$CPORT" ]; then "$f" > "$W/during" 2>&1; exit 0; fi
      sleep 0.05
    done
    echo "no candidate" > "$W/during" ) &
  DURING=$!
}

candidate_slow() { engine_set "port=$CPORT" load "${1:-2}"; }

update_install() {
  cmd_install "$@"
  curl_route GET "$INSTALL_SH" 200 "$ROOT/install.sh"
  mkdir -p "$W/tmp" && export TMPDIR="$W/tmp/"
}

release_at() {
  local v=$1 c=$2
  shift 2
  install_registry "$FX/registry-$v.tsv" "$v" "$@"
  install_tree "$FX/registry-$v.tsv" "$c"
  route_drop "$API/heads/release"
  commit_route heads/release "$c"
}

waiting_b1() {
  serving_put "$IB2" "$IMB" 4 32768 36.9
  chmod 644 "$DATA/store/$SA"; rm -f "$DATA/store/$SA"
  cp "$FX/registry.tsv" "$DATA/_update/registry"
  printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$DATA/_update/offer"
}

repaste() { run_install "$1" "$IR"; }
update_run() { run_install "$1" update; }

opened() { cat "$STUB_DIR"/opened/*/path 2>/dev/null; }

run_command() {
  printf '%s' "$2" > "$W/answers"
  HOME="$H" AU_TTY="$W/answers" AU_SCREEN="$W/screen" /bin/bash "$1" > "$W/out" 2>&1 < /dev/null
  RC=$?
}

data_snap() { snapshot "$DATA" | grep -v -E $'\tlogs(/|$)'; }

job_calls() { tail -n +$(($1 + 1)) "$STUB_LOG" | grep -E '^launchctl (enable|disable|bootstrap|bootout|kickstart)' | cut -d' ' -f1-2 | tr '\n' ' '; }

engine_pid() { cat "$STUB_LAUNCHCTL_DIR/pids/$EJOB" 2>/dev/null || echo none; }

says_not() { if grep -qF -- "$1" "$W/out"; then bad "$2: $(head -c 3000 "$W/out")"; else ok "$2"; fi; }
