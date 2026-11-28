# T104: with no default route the engine job writes no-network, not not-home, and starts no engine; `auster
# status` says which. Through a VPN it is not-home, and status says that. Mutant: tests/mutants/T104a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install

engine_job STUB_NET_IF=; engine_wait
same "$EJ_CODE" no-network "no default route: start says no-network"
same "$(starts)" "$NSTARTS" "no default route: no engine started"
engine_job_end
HOME="$H" /bin/bash "$DATA/bin/auster" status > "$W/status" 2>&1
grep -qF "The engine job's last start: this Mac had no network connection, so it did not start the engine (no-network)." "$W/status" && ok "auster status says no-network" || bad "auster status: $(cat "$W/status")"
grep -q 'not-home' "$W/status" && bad "auster status says not-home" || ok "auster status does not say not-home"

engine_job STUB_NET_IF=utun0; engine_wait
same "$EJ_CODE" not-home "a VPN: start says not-home"
engine_job_end
HOME="$H" /bin/bash "$DATA/bin/auster" status > "$W/status" 2>&1
grep -qF "The engine job's last start: this Mac is not on the home network Auster was installed on, so it did not start the engine (not-home)." "$W/status" && ok "auster status says not-home" || bad "auster status: $(cat "$W/status")"
done_
