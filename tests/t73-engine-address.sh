# T73: the home address (B4 step 5, BD9). A default route through utun0, a hardware port with a public or a
# 169.254 address, an address in 172.32/16 (outside 172.16/12), or a router whose hardware address differs
# from the one recorded in builds/mac: the engine is not started and `start` says not-home. On the home network
# it listens on 127.0.0.1 and the home address only, also when arp writes the router's address with capitals
# and leading zeros. Mutants: tests/mutants/T73a to T73c.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
same "$(sed -n 's/^router	//p' "$DATA/builds/mac")" 00:00:5e:00:53:01 "builds/mac records the router of the install"

away() { # LABEL VAR=VALUE...
  local l=$1; shift
  engine_job "$@"; engine_wait
  same "$EJ_CODE" not-home "$l: start says not-home"
  same "$(sed -n 's/^address	//p' "$DATA/builds/$IR/start")" - "$l: start holds no address"
  same "$(starts)" "$NSTARTS" "$l: no engine started"
  engine_job_end
}
away "a default route through utun0" STUB_NET_IF=utun0
away "a public address" STUB_NET_ADDR=203.0.113.7
away "a 169.254 address" STUB_NET_ADDR=169.254.10.20
away "an address in 172.32/16" STUB_NET_ADDR=172.32.0.9
away "another router" STUB_NET_ROUTER_MAC=0:0:5e:0:53:99
away "no arp entry for the router" STUB_NET_ROUTER_MAC=

home() { # LABEL ADDRESS VAR=VALUE...
  local l=$1 a=$2; shift 2
  engine_job "$@"; engine_wait
  same "$EJ_CODE" starting "$l: start says starting"
  same "$(sed -n 's/^address	//p' "$DATA/builds/$IR/start")" "$a" "$l: start holds the home address"
  if [ -n "$EJ_START" ]; then
    same "$(sed -n '/^--host$/{n;p;}' "$EJ_START/args")" "127.0.0.1,$a" "$l: it listens on 127.0.0.1 and $a only"
    same "$(sed -n '/^--cors-origins$/{n;p;}' "$EJ_START/args")" "http://$a:8484,http://test-mac.local:8484" "$l: its own two addresses are its CORS origins"
  else
    bad "$l: no engine started"
  fi
  engine_job_end
}
home "the home network" 10.0.0.5
home "arp with capitals and leading zeros" 10.0.0.5 STUB_NET_ROUTER_MAC=00:00:5E:00:53:01
home "a home network in 172.16/12" 172.20.1.2 STUB_NET_ADDR=172.20.1.2
done_
