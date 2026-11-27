# T116 (B6, D3.1; U2): the `.local` name the household's devices were given is recorded at a first install, in
# builds/local-name (one line: `auster-record 1`, the name, the time), and `auster status` says when macOS has
# changed the Mac's name since (it does when another device takes the name, and whatever answers to the old one could
# then show its own page, D3.10), naming the old address and the way back; nothing while the name is the same, or
# when the install had no name to give. `auster network` records the name the Mac has now, and status is quiet
# again. Mutants: tests/mutants/T116a and T116b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
L="$DATA/builds/local-name"
same "$(cut -f1,2 "$L" 2>/dev/null)" "auster-record 1	test-mac" "the install recorded the name its devices were given, test-mac"
cut -f3 "$L" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' && ok "  ...and when" || bad "the time: $(cat "$L")"
same "$(wc -l < "$L" | tr -d ' '):$(awk -F'\t' '{ print NF }' "$L"):$(stat -f %Lp "$L")" "1:3:600" "  ...one line, three fields, mode 0600"

auster status
same "$RC" 0 "status: exit 0"
grep -q 'name on the home network' "$W/out" && bad "the same name: status says it changed" || ok "the same name: status says nothing of it"

STUB_LOCALHOSTNAME=test-mac-2 auster status
outsays "macOS has changed this Mac's name on the home network from test-mac.local to test-mac-2.local" "macOS gave it another name: status says so, with both names"
outsays "A device that opens http://test-mac.local:8484/ no longer reaches this Mac" "  ...and the address its devices were given"
outsays '`auster network` records the name it has now' "  ...and the way to record the new one"

STUB_LOCALHOSTNAME=test-mac-2 auster network
same "$RC" 0 "auster network: exit 0"
same "$(cut -f1,2 "$L")" "auster-record 1	test-mac-2" "  ...it records the name the Mac has now"
STUB_LOCALHOSTNAME=test-mac-2 auster status
grep -q 'name on the home network' "$W/out" && bad "after network, status still says the name changed" || ok "after network, status says nothing of it"

printf 'auster-record 1\t-\t2026-11-27T10:00:00Z\n' > "$L"
STUB_LOCALHOSTNAME=other auster status
grep -q 'name on the home network' "$W/out" && bad "an install with no name to give: status speaks of one" || ok "an install that had no name to give: nothing said, whatever the name now"
done_
