# T118 (U6, its third part; D3.6 "A changed file of the build in use is fetched again"), the repair's refusals and
# failures, the second paste, and the words; tests/t118-repair-order.sh holds its order against Auster's programs and a
# move. On a Mac that installed order 1 and serves it, each run's tree a release newer than the stamp whose programs are
# those in use, so that a step 15 would move the stamp (each run is `install.sh update`, as the update's .command file
# runs it: this tree's installer, pasted with a newer release, would install a named version): (i) the engine job's last
# start engine-hash (a `start` written by the test) with every file matching, the stub engine not listening: the server
# check is made, and not answered exits 4 with no stamp, never 0. (ii) The tree's order no longer naming order 1, so
# section C moves the recipe to order 2: order 1's changed template copied from this tree's assets/ and its changed
# model fetched from the stub publisher at the repo and commit of serving's model line (another commit than any
# registry's), then the move completes (exit 0); with the report naming order 1 on a line that differs from serving's
# instead, passed over before the question, nothing fetched (exit 3). (iii) A changed template in no assets/ of the
# tree: passed over before the question (exit 3); with the engine job's last start engine-hash besides, the stub engine
# not listening: no kickstart, exit 3, not 4. (iv) The publisher's HEAD answering 404 for a changed model: passed over
# before the question, nothing deleted. (v) The download cut short after the yes: exit 3, the part kept, no kickstart,
# the stub engine still answering, no stamp, and with kept/ empty and no jobs/previous/ the installer line named and not
# `auster rollback` (xii's first clause). (vi) The disk below the floor with what is left of the model's download (its
# part counted): passed over for room, naming `auster cleanup`. (xii) The words by state: with no stamp when the run
# began, "paste the line again ... or remove it", no key shown and still no stamp; a no says "pasting the installer line
# again offers this again", exit 1, nothing changed. (xiv) `auster people` with a changed template: refused before any
# restart, naming the installer line, no kickstart, serving byte for byte, exit 1. (xv) A failed/ entry of another build
# present: the repair fetches serving's model, not the failed entry's. (xvii) A recipe section C passes over (fit) with
# a changed template: repaired as a repair alone, one check, exit 0.
# Mutants: tests/mutants/T118a (au_update_check ignores the engine job's start code), T118b (take the file's URL and
# size from _update/registry), T118c (restart a recipe whose repair failed), T118d (decide what the Mac holds by the
# file existing: no HEAD for a changed model), T118e (no disk rule for a repair's download), T118k (pass the recipe over
# when the report has no line for the build in use), T118l (check the server after a repair passed over while the engine
# job's last start is engine-hash), T118m (`auster people` restarting with a changed template), T118n (run step 15 after
# a repair passed over, declined or failed), T118o (take serving's lines after the judge without reading it again),
# T118q (pass over a recipe section C passes over without repairing it); the others are tests/t118-repair-order.sh's.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept" ST="$DATA/_update/scripts"
T1=$(sed -n 2p "$S" | cut -f5)   # order 1's template
FLOOR=50000000000                # 5% of install_env's 1 TB volume
REL=0
fresh() { # [ORDER...] -> release names a new commit, of version v0.2.<n>, whose tree is $ROOT's (its programs those in use);
  # TC its commit, T its source folder
  REL=$((REL + 1)) TC=$(printf '%040x' $((8192 + REL)))
  release_at "v0.2.$REL" "$TC" "$@"
  T="$FX/tree-src-$TC"
}
pack() { tree_archive "$T" "auster-$TC" "$TC" "$FX/tree-$TC.tar.gz"; }
sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
same_size() { # FILE -> its middle byte changed, at the same size, read-only as store/ keeps it
  local f=$1 n
  n=$(stat -f %z "$f")
  { head -c $((n / 2)) "$f"; printf 'X'; tail -c +$((n / 2 + 2)) "$f"; } > "$W/changed"
  chmod 644 "$f"; cat "$W/changed" > "$f"; chmod 444 "$f"
}
template_off() { chmod 644 "$DATA/store/$T1"; printf '{# one more line #}\n' >> "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"; }
template_on() { chmod 644 "$DATA/store/$T1"; cp "$FX/assets/order-1.jinja" "$DATA/store/$T1"; chmod 444 "$DATA/store/$T1"; }
start_hash() { printf 'auster-record 1\ncode\tengine-hash\naddress\t-\nboot\t-\ntime\t%s\n' "$(date +%s)" > "$DATA/builds/$IR/start"; chmod 600 "$DATA/builds/$IR/start"; }
engine_again() { # -> the stub engine answering, and the engine job started again on it
  local i
  engine_set '*' behaviour ok
  launchctl kickstart -k "gui/$UIDN/$EJOB"
  for i in $(seq 150); do engine_alive && return 0; sleep 0.1; done
  bad "the engine did not start again: $(tail -n 5 "$DATA/logs/engine.log")"
}
kicks() { job_calls "$1" | grep -o 'launchctl kickstart' | wc -l | tr -d ' '; }
mark() { N=$(wc -l < "$STUB_LOG"); rm -rf "$STUB_CURL_DIR/requests"; S0=$(cat "$S"); ST0=$(cat "$ST" 2>/dev/null); }
hosts() { requests | grep -E 'huggingface|cdn\.example|github\.com/ggml|objects\.example' | tr '\n' ' '; }
stamp_kept() { same "$(cat "$ST" 2>/dev/null)" "$ST0" "$1: the stamp as it was: no step 15"; }

# --- (i) the engine job's last start engine-hash, every file matching: the check is made, and exit 4, never 0
fresh
start_hash
engine_set '*' behaviour nolisten
mark
AU_SERVER_CHECK_SECS=4 update_run ''
same "$RC" 4 "(i) engine-hash with every file matching, the engine not answering: exit 4"
says "The engine job's last start found a file it checks changed (engine-hash)" "  ...the server is checked for it"
same "$(kicks "$N")" 1 "  ...the engine started again once"
stamp_kept "  ..."
engine_again

# --- (ii) the order no longer names the build in use: its files from serving's own lines, then the move to order 2
fresh "$IB2"
COMMIT_A2=a1b2c3d4e5f60718293a4b5c6d7e8f9012345678   # serving's model line names a commit no registry has
URL_A2=https://huggingface.co/$REPO_A/resolve/$COMMIT_A2/standin-a.gguf
curl_route HEAD "$URL_A2" 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$SA\""
curl_route GET "$URL_A2" 302 - "Location: https://cdn.example.test/a"
awk -F'\t' -v OFS='\t' -v c="$COMMIT_A2" 'NR == 4 { $4 = c } { print }' "$S" > "$W/s" && cat "$W/s" > "$S"
cp "$FX/registry.tsv" "$DATA/_update/registry"   # what an earlier check left: model A at its registry commit
template_off; same_size "$DATA/store/$SA"
mark
AU_SERVER_CHECK_SECS=8 update_run $'yes\n'
same "$RC" 0 "(ii) order 1 no longer in the order, its template and model changed, a move to order 2: exit 0"
case "$(hosts)" in *"GET $URL_A2 "*) ok "  ...its model fetched from the commit serving's model line names" ;; *) bad "  ...not from serving's commit: $(hosts)" ;; esac
case "$(hosts)" in *"GET $URL_A "*) bad "  ...fetched from a registry's commit: $(hosts)" ;; *) ok "  ...and from no registry's" ;; esac
same "$(sha_of "$DATA/store/$SA"):$(sha_of "$DATA/store/$T1")" "$SA:$T1" "  ...model A and order 1's template whole again"
same "$(sed -n 2p "$S" | cut -f2)" "$IB2" "  ...then the move completed: order 2 serves"
rm -f "$K"/*
fresh
awk -F'\t' -v OFS='\t' -v b="$IB1" '$1 == "build" && $2 == b { $8 = 41924 } { print }' "$FX/registry-v0.2.$REL.tsv" > "$W/reg"
install_tree "$W/reg" "$TC"
serving_put "$IB1" "$IMA" 4 32768 36.9
template_off
mark
update_run $'yes\n'
same "$RC" 3 "  the report naming order 1 on a line other than serving's: exit 3"
says "names build $IB1 on lines other than the ones it was installed from" "  ...passed over: the registry contradicts itself"
says_not "Fetch the files" "  ...before the question"
same "$(hosts)" "" "  ...nothing fetched"
stamp_kept "  ..."

# --- (iii) a changed template in no assets/ of the tree
fresh; rm -f "$T/assets/order-1.jinja"; pack
mark
update_run $'yes\n'
same "$RC" 3 "(iii) a changed template in no assets/ of the tree: exit 3"
says "This version of Auster holds no template with the sha256 build $IB1 names" "  ...passed over, saying so"
says_not "Fetch the files" "  ...before the question"
same "$(kicks "$N")" 0 "  ...no restart"
stamp_kept "  ..."
start_hash; engine_set '*' behaviour nolisten
mark
AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 3 "  the same with the engine job's last start engine-hash besides: exit 3, not 4"
same "$(kicks "$N")" 0 "  ...no kickstart, no check"
stamp_kept "  ..."
template_on
engine_again

# --- (iv) the publisher's HEAD answering 404 for a changed model
fresh
same_size "$DATA/store/$SA"; changed=$(sha_of "$DATA/store/$SA")
route_drop "$URL_A"; curl_route HEAD "$URL_A" 404 -; curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"
mark
update_run $'yes\n'
same "$RC" 3 "(iv) the publisher's HEAD answering 404 for the changed model: exit 3"
says "The publisher no longer offers standin-a.gguf" "  ...passed over, saying so"
says_not "Fetch the files" "  ...before the question"
same "$(sha_of "$DATA/store/$SA" 2>/dev/null)" "$changed" "  ...nothing deleted: the changed model still there"
same "$(requests | grep -c '^GET ')" 2 "  ...and nothing fetched but GitHub's API and the tree"
stamp_kept "  ..."
route_drop "$URL_A"
curl_route HEAD "$URL_A" 302 - "Location: https://cdn.example.test/a" "x-linked-size: 3400" "x-linked-etag: \"$SA\""
curl_route GET "$URL_A" 302 - "Location: https://cdn.example.test/a"

# --- (v) the download cut short after the yes (and xii: kept/ empty, no jobs/previous/)
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a exit:18:1000 "$FX/models/standin-a.gguf"
mark
update_run $'yes\n'
same "$RC" 3 "(v) the model's download cut short after the yes: exit 3"
same "$(stat -f %z "$DATA/store/$SA.part" 2>/dev/null)" 1000 "  ...the part kept for a resume"
same "$(kicks "$N")" 0 "  ...no kickstart"
same "$(ask_engine "$(key_of ipad)")" 200 "  ...the stub engine still answering"
stamp_kept "  ..."
says "Pasting the installer line again fetches it again." "  ...(xii) kept/ empty, no jobs/previous: the installer line named"
says_not "auster rollback" "  ...and not auster rollback"
says "Auster v0.2.$REL is on this Mac, but not everything was updated" "  ...the programs being those in use, the usual closing line"

# --- (vi) the disk below the floor with what is left of the model's download (3,400 less its part of 1,000)
fresh
mark
AU_DISK_FREE_BYTES=$((FLOOR + 2399)) update_run $'yes\n'
same "$RC" 3 "(vi) the disk one byte short of the floor with the 2,400 bytes left to fetch: exit 3"
says "There is not room on this Mac's disk to fetch it again" "  ...passed over for room"
says "\`auster cleanup\` lists what it can remove." "  ...naming auster cleanup"
says_not "Fetch the files" "  ...before the question"
same "$(hosts)" "HEAD $URL_A " "  ...nothing fetched: only the publisher asked"
stamp_kept "  ..."

# --- (xii) the words by state: no stamp when the run began; a no
cp "$ST" "$W/stamp"; rm -f "$ST"; : > "$W/screen"
mark
update_run $'yes\n'
same "$RC" 3 "(xii) no stamp when the run began, the download cut short again: exit 3"
says "paste the line again to fetch it again and finish, or remove it with: \"$DATA/bin/auster\" remove" "  ...it names pasting the line again, or removing it"
same "$(wc -c < "$W/screen" | tr -d ' ')" 0 "  ...no key shown"
[ -e "$ST" ] && bad "  ...a stamp was written" || ok "  ...and still no stamp"
cp "$W/stamp" "$ST"
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a.gguf"
before=$(data_snap); mark
update_run $'no\n'
same "$RC" 1 "  a no: exit 1"
says "Nothing was changed: pasting the installer line again offers this again." "  ...it says so"
same "$(data_snap)" "$before" "  ...nothing changed but logs/"
same "$(job_calls "$N")" "" "  ...no job restarted"

# --- (xiv) `auster people` with a changed template
model_in "$IMA"; rm -f "$DATA/store/$SA.part"
template_off
changed=$(sha_of "$DATA/store/$T1")
mark
ANSWERS=$'yes\n' auster people 2
same "$RC" 1 "(xiv) auster people 2 with a changed template: exit 1"
outsays "A file of the build this Mac serves has changed (the template). Pasting the installer line again fetches it again." "  ...refused, naming the installer line"
same "$(kicks "$N")" 0 "  ...no kickstart"
same "$(cat "$S")" "$S0" "  ...serving byte for byte as it was"
same "$(sha_of "$DATA/store/$T1")" "$changed" "  ...and nothing repaired"
template_on

# --- (xv) a failed/ entry of another build: the repair fetches serving's files, not the entry's
fresh
cp -p "$S" "$W/s"; serving_put "$IB2" "$IMB" 4 32768 36.9
mkdir -p "$DATA/builds/$IR/failed"; mv "$S" "$DATA/builds/$IR/failed/2026-11-21T10:00:00Z-$IB2"; mv "$W/s" "$S"
chmod 644 "$DATA/store/$SB"; rm -f "$DATA/store/$SB"   # what the entry names is not on this Mac
same_size "$DATA/store/$SA"
mark
update_run $'yes\n'
same "$RC" 0 "(xv) a failed entry of order 2 present, model A changed: exit 0"
case "$(hosts)" in *"GET $URL_A "*) ok "  ...model A fetched again, from serving's line" ;; *) bad "  ...model A not fetched: $(hosts)" ;; esac
case "$(hosts)" in *"$URL_B"*) bad "  ...the failed entry's model fetched: $(hosts)" ;; *) ok "  ...and not the failed entry's model" ;; esac
same "$(sha_of "$DATA/store/$SA")" "$SA" "  ...model A whole again"
rm -f "$DATA/builds/$IR"/failed/*

# --- (xvii) a recipe section C passes over (fit) with a changed template: a repair alone, one check, exit 0
fresh
cp -p "$DATA/builds/mac" "$W/mac"
template_off
mark
AU_GPU_MIB=1000 update_run $'yes\n'
same "$RC" 0 "(xvii) section C passes the recipe over (fit), its template changed: exit 0"
says "passed over (does not fit)" "  ...the recipe passed over by section C"
says "Fetch the files of household again now?" "  ...the question a repair's alone"
same "$(sha_of "$DATA/store/$T1")" "$T1" "  ...the template repaired"
same "$(kicks "$N")" 1 "  ...one restart, and its check"
says "The server answered, at 36.9 tokens a second, and refused a request with no key." "  ...which passed"
cp -p "$W/mac" "$DATA/builds/mac"
done_
