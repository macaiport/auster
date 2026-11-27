# T12 (U6; D3.6, D3.7, AD8): the hold a rollback writes, read end to end. On a Mac serving order 1 with order 2 in kept/,
# `auster rollback` goes back to order 2 and holds order 1; `auster status` then calls the recipe the same, not waiting
# (U3's recipe line). A later version (v0.2.0) whose registry still orders order 1 first leaves the recipe on order 2 and
# says that order 1 is held (U4's judge), exit 0, the stamp moved; a version (v0.3.0) that orders a different build first
# (the files of order 1 under a new id) offers that build, whose question is answered no. `auster unhold` deletes the
# hold, saying which build it held, and v0.2.0's registry then offers order 1 again; a second `unhold` finds nothing held.
# A rollback onto a hold of 64 builds, the most its reader reads, keeps the newest 64.
# Mutants: tests/mutants/T12a (key `hold` on the version: an update of a later version clears it), T12b (no bound on
# the hold).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
IB4=bwq5zfgyk3p7e   # a build of order 1's files under its own id (A2: never minted again)
update_install
engine_up
S="$DATA/builds/$IR/serving"
build() { sed -n 2p "$S" | cut -f2; }
stamp() { cut -f3 "$DATA/_update/scripts"; }
kept_put "$IB2" "$IMB" 4 32768 36.9 2026-11-20T10:00:00Z
cp "$FX/registry.tsv" "$DATA/_update/registry"                       # as the last check left them: v0.1.0, nothing newer
printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$DATA/_update/offer"

ANSWERS=$'1\n' auster rollback
same "$RC:$(build)" "0:$IB2" "auster rollback to order 2: exit 0, order 2 serves"
same "$(hold_ids)" "$IB1" "  ...order 1 held"
auster status
outsays "The recipe household: the same, serving build $IB2, the build for this Mac." "auster status: the recipe the same, order 1 not waiting"

# --- a later version that still names the held build
release_at v0.2.0 "$COMMIT2"
s0=$(cat "$S")
update_run ''
same "$RC" 0 "v0.2.0, order 1 still first: exit 0"
says "The recipe household: build $IB1 is held on this Mac, so it stays on build $IB2, and nothing changes." "  ...it says order 1 is held"
says_not "an update is waiting" "  ...and asks nothing"
same "$(cat "$S")" "$s0" "  ...serving as it was"
same "$(stamp)" v0.2.0 "  ...the stamp of v0.2.0"
same "$(hold_ids)" "$IB1" "  ...and order 1 still held"

# --- a version that names a different build
install_registry "$FX/registry-v0.3.0.tsv" v0.3.0 "$IB4" "$IB1" "$IB2"
awk -F'\t' -v OFS='\t' -v b1="$IB1" -v b4="$IB4" '{ print } $1 == "build" && $2 == b1 { $2 = b4; print }' "$FX/registry-v0.3.0.tsv" > "$W/reg" &&
  mv "$W/reg" "$FX/registry-v0.3.0.tsv"
install_tree "$FX/registry-v0.3.0.tsv" 3f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
route_drop "$API/heads/release"; commit_route heads/release 3f1e3a5c7e9f1b3d5f7a9c1e3b5d7f9a1c3e5b7d
update_run $'no\n'
same "$RC" 1 "v0.3.0, a different build first, answered no: exit 1"
says "The recipe household: an update is waiting." "  ...an update is offered"
says "  After       build $IB4 (standin-a.gguf)" "  ...for the build v0.3.0 names first"
same "$(cat "$S")" "$s0" "  ...and on the no, serving as it was"

# --- auster unhold lets the held one back
auster unhold
same "$RC" 0 "auster unhold: exit 0"
outsays "No build is held on this Mac now (it held $IB1): an update may move it to any build again." "  ...it says which build it held"
same "$(hold_ids)" none "  ...the hold deleted"
route_drop "$API/heads/release"; commit_route heads/release "$COMMIT2"
update_run $'no\n'
same "$RC" 1 "v0.2.0 again after unhold, answered no: exit 1"
says "  After       build $IB1 (standin-a.gguf)" "  ...order 1 is offered again"
auster unhold
same "$RC" 0 "a second auster unhold: exit 0"
outsays "No build is held on this Mac, so nothing was changed." "  ...nothing held"

# --- a hold of 64 builds, the most it may hold: the newest 64 are kept
for x in a b c d; do for y in a b c d e f g h i j k l m n o p; do printf 'baaaaaaaaaa%s%s\n' "$x" "$y"; done; done > "$W/ids"
{ printf 'auster-record 1\n'; cat "$W/ids"; } > "$DATA/builds/$IR/hold"
ANSWERS=$'1\n' auster rollback
same "$RC:$(build)" "0:$IB1" "auster rollback to order 1, 64 builds held: exit 0, order 1 serves"
same "$(hold_ids | wc -l | tr -d ' ') $(hold_ids | head -n 1) $(hold_ids | tail -n 1)" "64 baaaaaaaaaaab $IB2" \
  "  ...64 builds held: the oldest dropped, order 2 last"
done_
