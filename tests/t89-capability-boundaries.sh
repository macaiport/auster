# T89: boundaries (C3, C4). One MiB either side of the GPU rule's limit, and of the 12 GiB rule, moves the
# context by exactly one step of 1,024; 12 GiB is 12,288 MiB. Order 2 for four people throughout (0.625 MiB
# of cache a token of context); order 1 never fits in these figures. Mutants: tests/mutants/T89a to T89c,
# the plan's three, and T89d, the GPU rule's slip made in the memory rule.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"

# The GPU rule, with memory to spare (128 GB). Order 2 at 19,456: 13,302 + 665 + 12,160 = 26,127 MiB, so
# 27,151 MiB with the margin is the smallest limit that allows it; at 20,480 it needs 27,791
L=27151
same "$(context_of "$(on $GB128 $L "$HREG" $HH)")" 19456 "GPU limit 27,151 MiB, exactly the need plus 1,024: 19,456 fits"
same "$(context_of "$(on $GB128 $((L - 1)) "$HREG" $HH)")" 18432 "GPU limit one MiB less: one step down, 18,432"
same "$(context_of "$(on $GB128 $((L + 1)) "$HREG" $HH)")" 19456 "GPU limit one MiB more: still 19,456"
same "$(context_of "$(on $GB128 27791 "$HREG" $HH)")" 20480 "GPU limit 27,791 MiB: the next step, 20,480"
same "$(context_of "$(on $GB128 27790 "$HREG" $HH)")" 19456 "GPU limit 27,790 MiB: still 19,456"

# The rule for the rest of the Mac, with the GPU limit out of the way. Order 2 at 15,360 needs 23,999 MiB in
# all, so 23,999 + 12,288 = 36,287 MiB (38,049,677,312 bytes) is the least memory that allows it
M=$((36287 * MIB))
same "$M" 38049677312 "36,287 MiB is 38,049,677,312 bytes"
same "$(context_of "$(on $M 1048576 "$HREG" $HH)")" 15360 "memory 36,287 MiB, exactly the need plus 12,288: 15,360 fits"
same "$(context_of "$(on $((M - MIB)) 1048576 "$HREG" $HH)")" 14336 "memory one MiB less: one step down, 14,336"
same "$(context_of "$(on $((M + MIB)) 1048576 "$HREG" $HH)")" 15360 "memory one MiB more: still 15,360"
same "$(context_of "$(on $((M - 1)) 1048576 "$HREG" $HH)")" 14336 "memory one byte less: memory rounds down to whole MiB, 14,336"
same "$(context_of "$(on $(((23999 + 12000) * MIB)) 1048576 "$HREG" $HH)")" 14336 \
  "memory of the need plus 12,000 MiB: 15,360 does not fit, since 12 GiB is 12,288 MiB"

# Both rules at once: at 36 GB with 27,648 MiB the memory rule binds (T88); the GPU rule alone would give 19,456
same "$(context_of "$(on $GB36 27648 "$HREG" $HH)")" 15360 "36 GB: the tighter rule decides"

# The minimum itself: order 2 at 8,192 for four needs 19,087 on the GPU and 19,519 in all
same "$(pick "$(on $GB128 20111 "$HREG" $HH)")" "$B2 4 8192 0" "GPU limit 20,111 MiB: order 2 at the recipe's minimum, 8,192"
same "$(pick "$(on $GB128 20110 "$HREG" $HH)")" "refused fit 3" "GPU limit 20,110 MiB: below the minimum, refused"
done_
