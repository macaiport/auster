# T27 (U6; D3.6, D3.7, AD8, AD13): `auster rollback` from kept/. With nothing in kept/ and no jobs/previous, it says so
# and exits 1. On a Mac serving order 1 for four at 32,768 with order 2 in kept/: a kept model changed at the same size
# is caught, nothing changes and the server keeps answering a household key; an entry whose build failed its test here
# is marked and refused; one that _update/registry withdraws is marked and refused without --withdrawn-ok, and with it
# goes back, saying that it was withdrawn and printing nothing of the registry's own; that rollback's passed check holds
# order 1, the build left behind. Going back onto a held build (order 1) takes it off the list and holds the one left
# (order 2). A rollback whose server check fails (the stub engine answering HTTP 500 for order 2) exits 4, naming
# `auster status` and another rollback, with order 2 serving at a speed of 0: nothing switches back, no hold is written
# and nothing goes in failed/. (The words of each withdrawal's reason are U8's.)
# Mutants: tests/mutants/T27a (go back without hashing), T27b (write hold before the server check), T27c (put the build
# in failed/).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving" K="$DATA/builds/$IR/kept" F="$DATA/builds/$IR/failed"
launch() { sed -n 5p "$S" | cut -f1-4,6; }
build() { sed -n 2p "$S" | cut -f2; }
failed() { ls -A "$F" 2>/dev/null | tr '\n' ' '; }
s0=$(cat "$S") n=$(wc -l < "$STUB_LOG")
auster rollback
same "$RC" 1 "nothing in kept/ and no jobs/previous: exit 1"
outsays "There is nothing to go back to" "  ...it says so"
same "$(cat "$S"):$(job_calls "$n")" "$s0:" "  ...serving as it was, the engine not restarted"

kept_put "$IB2" "$IMB" 4 32768 36.9 2026-11-20T10:00:00Z
E2="build $IB2 (standin-b.gguf), 4 people at 32,768 tokens each, served until 2026-11-20 10:00:00 UTC"
unchanged() { # LABEL -> serving, kept/ and failed/ as they were, the engine not restarted and answering a household key
  same "$(cat "$S"):$(ls "$K"):$(failed)" "$s0:$k0:$f0" "$1: serving, kept/ and failed/ as they were"
  same "$(job_calls "$n")" "" "$1: the engine not restarted"
  same "$(ask_engine "$(key_of ipad)")" 200 "$1: the server keeps answering"
}
mark() { s0=$(cat "$S") k0=$(ls "$K") f0=$(failed) n=$(wc -l < "$STUB_LOG"); }

# --- a kept model changed at the same size
chmod 644 "$DATA/store/$SB"; { head -c 2039 "$FX/models/standin-b.gguf"; printf 'X'; } > "$DATA/store/$SB"
mark
ANSWERS=$'1\n' auster rollback
same "$RC" 1 "a kept model changed at the same size: exit 1"
outsays "  1  $E2" "  ...the entry listed, newest first"
outsays "The model (store/$SB) is missing or has changed since it was checked." "  ...it names the model"
outsays "nothing was changed: the server keeps serving as it was." "  ...and says nothing changed"
unchanged "a changed kept model"
model_in "$IMB"

# --- a build that failed its test here
mkdir -p -m 700 "$F"; cp -p "$K/2026-11-20T10:00:00Z-$IB2" "$F/2026-11-21T10:00:00Z-$IB2"
mark
ANSWERS=$'1\n' auster rollback
same "$RC" 1 "an entry whose build failed its test here: exit 1"
outsays "  1  $E2, failed its test here" "  ...marked"
outsays "Build $IB2 failed its test on this Mac (builds/$IR/failed), so Auster does not go back to it." "  ...and refused"
unchanged "a failed build"
rm -f "$F"/*

# --- a withdrawn build
{ cat "$FX/registry.tsv"; printf 'withdraw\t%s\tsecurity\n' "$IB2"; } > "$DATA/_update/registry"   # as the last check fetched it
mark
ANSWERS=$'1\n' auster rollback
same "$RC" 1 "an entry withdrawn, without --withdrawn-ok: exit 1"
outsays "  1  $E2, withdrawn" "  ...marked"
outsays "Build $IB2 has been withdrawn, so Auster goes back to it only when told so: \`auster rollback --withdrawn-ok\`." "  ...and refused"
unchanged "a withdrawn build"
ANSWERS=$'1\n' auster rollback --withdrawn-ok
same "$RC" 0 "with --withdrawn-ok: exit 0"
outsays "Build $IB2 has been withdrawn; Auster goes back to it because --withdrawn-ok says so." "  ...it says the build was withdrawn"
grep -q security "$W/out" && bad "  ...it printed the registry's reason as it came" || ok "  ...and prints nothing of the registry's own"
same "$(build) $(launch)" "$IB2 launch	4	32768	8484	36.9" "  ...order 2 serves, with the speed its check measured"
same "$(ls "$K" | sed -E 's/^[0-9T:-]{19}Z-//')" "$IB1" "  ...order 1 in kept/, the entry gone back to taken out"
same "$(hold_ids)" "$IB1" "  ...order 1, the build left behind, held"
outsays "Build $IB1 is held on this Mac now: no update moves it there again until \`auster unhold\`." "  ...and it says so"
same "$(failed)" "" "  ...nothing in failed/"

# --- going back onto a held build
ANSWERS=$'1\n' auster rollback
same "$RC" 0 "going back onto order 1, which is held: exit 0"
outsays "Build $IB1 was held on this Mac; going back to it takes it off the list." "  ...it says so"
same "$(build)" "$IB1" "  ...order 1 serves"
same "$(hold_ids)" "$IB2" "  ...order 1 off the list, order 2, the build left behind, on it"

# --- a rollback whose server check fails
engine_set "alias=$IB2,port=8484" behaviour http500
h0=$(cat "$DATA/builds/$IR/hold") f0=$(failed)
AU_SERVER_CHECK_SECS=4 ANSWERS=$'1\n' auster rollback --withdrawn-ok
same "$RC" 4 "a rollback whose server check fails: exit 4"
outsays "The server did not answer its check within 4 s" "  ...it says the server did not answer"
outsays "\`auster status\` says how the engine's last start went." "  ...it names auster status"
outsays "Another \`auster rollback\` goes further back, with no download." "  ...and another rollback"
same "$(build) $(launch)" "$IB2 launch	4	32768	8484	0" "  ...order 2 serves with a speed of 0: nothing switches back"
same "$(cat "$DATA/builds/$IR/hold")" "$h0" "  ...no hold written"
same "$(failed)" "$f0" "  ...and nothing in failed/"
engine_set "alias=$IB2,port=8484" behaviour ok
done_
