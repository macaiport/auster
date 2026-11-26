# T88: section C on four Macs, by the test variables, for the household recipe at four people (C1 to C4):
# 16 GB refuses, naming what the smallest build needs; 36 GB (38,654,705,664 bytes) with a GPU limit of
# 27,648 MiB gives order 2 at 15,360, and at two people 31,744; 64 GB with 53,084 MiB gives order 1 at
# 32,768; 128 GB gives order 1 at 32,768 (the recipe's maximum binds). Also: each build's needs as C2 works
# them out, the figures said with where they came from, and a test variable that fails its pattern not
# used. Every figure below is worked out by hand in the comments. Mutants: tests/mutants/T88a to T88c.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"

# 16 GB (12,288 MiB, an assumed limit). Order 2 at the minimum, 4 x 8,192: the cache is 163,840 x 32,768
# bytes = 5,120 MiB, so 13,302 + 665 + 5,120 = 19,087 MiB on the GPU and 19,519 in all; it needs a GPU
# limit of 19,087 + 1,024 = 20,111 MiB and memory of 19,519 + 12,288 = 31,807 MiB. Order 1 needs more
# (42,976 and 43,460), so order 2 is the smallest.
o=$(on $GB16 12288 "$HREG" $HH)
same "$(pick "$o")" "refused fit 3" "16 GB: refused, nothing fits"
same "$(kind "$o" needs)" "needs${T}$B2${T}4${T}8192${T}19087${T}19519${T}20111${T}31807" \
  "16 GB: names what the smallest build (order 2, four at 8,192) needs, and the limit and memory that takes"
same "$(kind "$o" figures)" "figures${T}12288${T}17179869184${T}-${T}-${T}test${T}test${T}-${T}-" "16 GB: says this Mac's figures, from the test variables"
same "$(kind "$o" build | cut -f2-7 | tr '\t\n' ' ')" "1 $B1 fit - 42976 43460 2 $B2 fit - 19087 19519 " "16 GB: each build ruled out by fit, its needs at the minimum"

# 36 GB, 36,864 MiB, GPU limit 27,648 MiB. Order 1 alone takes 42,256 MiB before any cache: no context.
# Order 2, four people: the cache is 0.625 MiB a token of context. The rest of the Mac allows 36,864 -
# 12,288 = 24,576 MiB in all, so at most 24,144 on the GPU, 10,177 MiB of cache: 15,360 (9,600 MiB: 23,567
# on the GPU, 23,999 in all), not 16,384 (10,240). The GPU rule alone would allow 19,456.
o=$(on $GB36 27648 "$HREG" $HH)
same "$(pick "$o")" "$B2 4 15360 0" "36 GB, four people: order 2 at 15,360"
same "$(kind "$o" choice | cut -f5,6)" "23567${T}23999" "36 GB, four people: 23,567 MiB on the GPU, 23,999 in all"
same "$(kind "$o" build | head -1 | cut -f4,5)" "fit${T}-" "36 GB: order 1 does not fit"
# Two people: 0.3125 MiB a token. 10,177 MiB of cache allows 31,744 (9,920 MiB: 23,887 on the GPU, 24,319 in
# all), not 32,768 (10,240)
o=$(on $GB36 27648 "$HREG" $HH --people 2)
same "$(pick "$o")" "$B2 2 31744 0" "36 GB, two people: order 2 at 31,744"
same "$(kind "$o" choice | cut -f5,6)" "23887${T}24319" "36 GB, two people: 23,887 MiB on the GPU, 24,319 in all"

# 64 GB with 53,084 MiB: order 1, four at 32,768, has 2,880 MiB of cache: 41,923 + 333 + 2,880 = 45,136 on
# the GPU (C2's own example), 46,160 with the margin, and 45,620 in all, leaving 19,916 MiB
o=$(on $GB64 53084 "$HREG" $HH)
same "$(pick "$o")" "$B1 4 32768 0" "64 GB: order 1 at 32,768"
same "$(kind "$o" choice | cut -f5,6)" "45136${T}45620" "64 GB: 45,136 MiB on the GPU, 45,620 in all (C2)"
same "$(kind "$o" build | tail -1 | cut -f4-7 | tr '\t' ' ')" "ok 32768 34447 34879" "64 GB: order 2 also fits, at 34,447 MiB (C2's example), and is not chosen"

# 128 GB (98,304 MiB, an assumed limit): order 1 at 32,768, the recipe's maximum
o=$(on $GB128 98304 "$HREG" $HH)
same "$(pick "$o")" "$B1 4 32768 0" "128 GB: order 1 at 32,768, the recipe's maximum"

# A test variable is used only when it matches whole (C1)
o=$(AU_RAM_BYTES=$GB64 AU_GPU_MIB='53084 ' cap "$HREG" $HH)
same "$(pick "$o")" "refused figures gpu,missing 3" "a GPU limit with a trailing space is not used, and nothing is guessed"
o=$(AU_RAM_BYTES=0x10 AU_GPU_MIB=53084 cap "$HREG" $HH --ram $GB36)
same "$(kind "$o" figures | cut -f3,7)" "$GB36${T}measured" "memory 0x10 is not used; the measured figure is"
o=$(AU_RAM_BYTES=$GB64 AU_GPU_MIB=053084 cap "$HREG" $HH)
same "$(kind "$o" refused)" "refused${T}figures${T}gpu,missing" "a leading zero fails the pattern"

# A recipe the registry cannot give is refused before any figure is used
same "$(pick "$(on $GB64 53084 "$CAPF/no-such.tsv" $HH)")" "refused registry unreadable 3" "no registry: refused, unreadable"
same "$(pick "$(on $GB64 53084 "$HREG" rsvh4l2c3prht)")" "refused registry absent 3" "a recipe the registry does not name: refused, absent"
same "$(kind "$(on $GB64 53084 "$HREG" not-an-id 2>/dev/null)" exit | cut -f2)" 2 "a recipe id that fails its pattern: a usage error"
done_
