# T100, the update's half (U4; B3 step 4, D3.6, BD9, U2's `local-name`): an update records neither the home network's
# router nor the Mac's `.local` name again; only a first install and `auster network` do. With the Mac now behind
# another router and under another name, an update that changes nothing (a second paste) and one answered no each leave
# builds/mac and builds/local-name byte for byte as they were. A yes to a change of build (U5's middle part: its files
# fetched) and a yes to a change of setting each write `mac` once (U5), with the GPU limit measured (50,000 MiB by the
# test variable for the setting) and the router and keep-awake of the install, and leave builds/local-name as it was;
# after the change of setting the engine job finds the Mac off its home network and the server check is not answered
# (exit 4), until `auster network` records the new router. Mutants: tests/mutants/T100a (record the router at every
# update), T100b (write the router the Mac is behind now into `mac` after the yes).
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
same "$RC" 3 "an update answered yes to a change of build: exit 3, its files fetched"
same "$(sed -n 6,7p "$DATA/builds/mac")" "$(printf '%s\n' "$mac" | sed -n 6,7p)" "  ...builds/mac's router and keep-awake those of the install"
same "$(cat "$DATA/builds/local-name")" "$name" "  ...builds/local-name as it was"
[ -f "$DATA/store/$SA" ] || cp "$W/pristine/store/$SA" "$DATA/store/$SA"   # the yes above fetched it
serving_put "$IB1" "$IMA" 4 16384 36.9
AU_GPU_MIB=50000 AU_SERVER_CHECK_SECS=4 update_run $'yes\n'
same "$RC" 4 "a change of setting answered yes, behind another router: exit 4, the engine off its home network"
says "the engine job's last start says not-home" "  ...the engine job says not-home"
same "$(sed -n 2p "$DATA/builds/mac")" "gpu-mib	50000" "  ...builds/mac written with the GPU limit this run measured"
same "$(sed -n 6,7p "$DATA/builds/mac")" "$(printf '%s\n' "$mac" | sed -n 6,7p)" "  ...and the router and keep-awake of the install"
same "$(cat "$DATA/builds/local-name")" "$name" "  ...builds/local-name as it was"
done_
