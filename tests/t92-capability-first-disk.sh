# T92, section C's half: at a first install, when order 1 fits in memory but not on disk, the choice is
# order 2 and says how much space order 1 needs (BD13, C6); with too little disk for any build the rule
# refuses (exit 3), so nothing is fetched. The question's words, and the stub curl's log showing no model
# fetched, are the installer's (V5); the 17 MB engine it fetches to measure the Mac comes before this rule
# (B3 step 4). Mutants: tests/mutants/T92a and T92b.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t92.XXXXXX")

# A 460 GiB volume, 494,384,795,648 bytes: 5% is 24,719,239,782.4, so the floor is 24,719,239,783 bytes
# (more than 20 GiB). Downloads: order 1 is 44,407,639,744 + 16,907,811 = 44,424,547,555 bytes and needs
# 69,143,787,338 free; order 2 is 14,334,432,256 + 16,907,811 = 14,351,340,067 and needs 39,070,579,850.
V=494384795648
same "$((44407639744 + 16907811 + 24719239783)):$((14334432256 + 16907811 + 24719239783))" "69143787338:39070579850" "the sums, by hand"
disk() { # FREE [OPTION...] -> cap on the 64 GB Mac (order 1 fits in memory) with that much free on the volume
  local free=$1
  shift
  AU_DISK_FREE_BYTES=$free AU_DISK_TOTAL_BYTES=$V on $GB64 53084 "$HREG" $HH "$@"
}

o=$(disk 50000000000)
same "$(pick "$o")" "$B2 4 32768 0" "50 GB free: order 2 is offered"
same "$(kind "$o" room)" "room${T}$B1${T}44424547555${T}69143787338" "and the space order 1 would need is said: its download, and the free space it needs"
same "$(kind "$o" choice | cut -f8):$(kind "$o" disk)" "room:disk${T}14351340067${T}24719239783${T}50000000000${T}0" "order 2 has room: its download and the floor"
same "$(kind "$o" build | cut -f4 | paste -sd, -)" "room,ok" "order 1 shows room, order 2 ok"

o=$(disk 69143787338)
same "$(pick "$o"):$(kind "$o" room)" "$B1 4 32768 0:" "exactly order 1's need free: order 1, nothing passed over"
o=$(disk 69143787337)
same "$(pick "$o"):$(kind "$o" room | cut -f2)" "$B2 4 32768 0:$B1" "one byte less: order 2, and order 1's space said"

same "$(pick "$(disk 39070579850)")" "$B2 4 32768 0" "exactly order 2's need free: order 2"
o=$(disk 39070579849)
same "$(pick "$o")" "refused room 3" "one byte less: too little disk for any build, refused (nothing fetched)"
same "$(kind "$o" room | cut -f2-4 | tr '\t\n' ' ')" "$B1 44424547555 69143787338 $B2 14351340067 39070579850 " \
  "the refusal says what each build that fits in memory would need"
same "$(kind "$o" choice)" "" "and no choice is given"

# At 36 GB only order 2 fits in memory, so only its space is said
o=$(AU_DISK_FREE_BYTES=39070579849 AU_DISK_TOTAL_BYTES=$V on $GB36 27648 "$HREG" $HH)
same "$(pick "$o"):$(kind "$o" room | cut -f2 | paste -sd, -)" "refused room 3:$B2" "36 GB, too little disk: refused, naming order 2 only"

# An unfinished download of order 1's model counts: 30,000,000,000 bytes already down leaves 14,407,639,744
# + 16,907,811 to fetch, which needs 39,143,787,338 free
printf 'auster-disk 1\npartial\tc56fdf063ad8c215c0e56c322383b3fb242189ce9047cdbb3e7dcad11380c1b8\t30000000000\n' > "$W/partial"
o=$(disk 50000000000 --disk "$W/partial")
same "$(pick "$o"):$(kind "$o" disk | cut -f2)" "$B1 4 32768 0:14424547555" "order 1 partly downloaded: it fits on disk now, and only the rest is counted"

# No disk figures: the disk rule is not applied, and the choice says so
o=$(on $GB64 53084 "$HREG" $HH)
same "$(kind "$o" choice | cut -f2,8):$(kind "$o" room)" "$B1${T}unknown:" "no disk figures: order 1, disk unknown"
done_
