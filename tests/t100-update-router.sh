# T100, the update's half (U4; B3 step 4, D3.6, BD9, U2's `local-name`): an update records neither the home network's
# router nor the Mac's `.local` name again; only a first install and `auster network` do. With the Mac now behind
# another router and under another name, an update that changes nothing (a second paste), one answered no and one
# answered yes each leave builds/mac and builds/local-name byte for byte as they were. (Where an update writes `mac`
# after its yes, keeping the router and keep-awake, is U5's.) Mutant: tests/mutants/T100a (record the router at every
# update).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
mac=$(cat "$DATA/builds/mac"); name=$(cat "$DATA/builds/local-name")
same "$(sed -n 6p "$DATA/builds/mac")" "router	00:00:5e:00:53:01" "the install recorded the router"
export STUB_NET_ROUTER_MAC=0:0:5e:0:53:2 STUB_LOCALHOSTNAME=other-mac
kept() { # LABEL
  same "$(cat "$DATA/builds/mac")" "$mac" "$1: builds/mac as it was, the router of the install"
  same "$(cat "$DATA/builds/local-name")" "$name" "  ...and builds/local-name as it was"
}
repaste ''
same "$RC" 0 "behind another router, a second paste that changes nothing: exit 0"
kept "a second paste"
waiting_b1
update_run $'no\n'
same "$RC" 1 "an update answered no: exit 1"
kept "answered no"
update_run $'yes\n'
same "$RC" 3 "an update answered yes: exit 3, at U5's step"
kept "answered yes"
done_
