# T57 (U6; D3.6, AD13): going back offline. On a Mac serving order 1 with order 2 in kept/, _update/registry deleted
# and the stub curl failing every address it is not an engine's (no route at all): `auster rollback` goes back from the
# kept descriptor alone, its files checked against the sizes and sha256s that descriptor names, says that withdrawals
# are not known here, passes its server check and holds order 1; the only requests it makes are the server check's,
# to the engine on the home address.
# Mutants: tests/mutants/T57a (fetch the registry during rollback), T57b (refuse to go back without the registry).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
. "$TESTS/rollback-helpers.sh"
update_install
engine_up
S="$DATA/builds/$IR/serving"
kept_put "$IB2" "$IMB" 4 32768 36.9 2026-11-20T10:00:00Z
rm -f "$DATA/_update/registry"
: > "$STUB_CURL_DIR/routes"
rm -rf "$STUB_CURL_DIR/requests" "$STUB_CURL_DIR/unrouted"
n=$(wc -l < "$STUB_LOG")
ANSWERS=$'1\n' auster rollback
same "$RC" 0 "offline, with no _update/registry: auster rollback, exit 0"
outsays "Whether a build has been withdrawn is not known here (_update/registry cannot be read), so none is marked." "  ...it says withdrawals are not known here"
same "$(sed -n 2p "$S" | cut -f2) $(sed -n 5p "$S" | cut -f1-4,6)" "$IB2 launch	4	32768	8484	36.9" "  ...order 2 serves, and its server check passed"
same "$(hold_ids)" "$IB1" "  ...order 1 held"
same "$(tail -n +$((n + 1)) "$STUB_LOG" | grep '^curl' | grep -vc 'http://10\.0\.0\.5:8484/')" 0 "  ...no request but the server check's"
same "$(requests | grep -vc '^POST http://10\.0\.0\.5:8484/')" 0 "  ...none sent anywhere but the engine"
[ -s "$STUB_CURL_DIR/unrouted" ] && bad "  ...it asked for $(cat "$STUB_CURL_DIR/unrouted")" || ok "  ...and nothing unrouted asked for"
[ -e "$DATA/_update/registry" ] && bad "  ..._update/registry written" || ok "  ..._update/registry still absent"
done_
