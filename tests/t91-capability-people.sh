# T91, section C's half: an update keeps the household's number of people (C4), and `auster people 2`
# chooses again for the build served. What V3 can show is the rule's answer: the caller passes the people
# from the launch line (--people) and the build served (--serving), and the choice carries them. Naming a
# change of context or build in the question, in figures, is the update's (U4, U5), and `auster people`'s
# switch, rollback and server check are U5's and V7's (T112); the choice line gives them the figures to
# compare with the launch line. Also C5, the way an update tests (side by side or in turn; T16 is U5's),
# and D3.7 with section C's own fit and the caller's `hold` and `failed/` (T44 used a stand-in). Mutant:
# tests/mutants/T91a.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"

# 36 GB with 27,648 MiB (T88), serving order 2. The household chose two people earlier: an update carries 2
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 2)")" "$B2 2 31744 0" \
  "an update with two people carried over: order 2 for two at 31,744, not four at 15,360"
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 4)")" "$B2 4 15360 0" "the same Mac carrying four: 15,360"
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 1)")" "$B2 1 32768 0" "carrying one: the recipe's maximum, 32,768"
same "$(pick "$(on $GB36 27648 "$HREG" $HH --people 3)")" "$B2 3 21504 0" \
  "a first install where the household lowered the default to three: 21,504"

# `auster people 2` on a Mac serving four at 15,360: the build served, chosen again for two
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 2 --keep-build)")" "$B2 2 31744 0" \
  "auster people 2: order 2 chosen again, for two at 31,744"
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 4 --keep-build)")" "$B2 4 15360 0" "auster people 4: back to 15,360"

# The number is from 1 to the recipe's default: above it, the default
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B2 --people 6)")" "$B2 4 15360 0" "six carried over, the default four: four"

# 64 GB with 53,084 MiB, serving order 2: order 1 is earlier in the order and fits, so an update picks it
# (D3.7) for the people carried over; `auster people` changes no build
same "$(pick "$(on $GB64 53084 "$HREG" $HH --serving $B2 --people 2)")" "$B1 2 32768 0" "an update serving order 2: order 1 is waiting, for the two carried over"
same "$(pick "$(on $GB64 53084 "$HREG" $HH --serving $B2 --people 2 --keep-build)")" "$B2 2 32768 0" \
  "auster people 2 with order 1 waiting: order 2 stays (T112)"
o=$(on $GB36 27648 "$HREG" $HH --serving $B1 --people 4 --keep-build)
same "$(pick "$o"):$(kind "$o" needs | cut -f2)" "refused fit 3:$B1" "auster people on a build that cannot fit: refused, naming its needs"
same "$(kind "$(on $GB36 27648 "$HREG" $HH --keep-build 2>/dev/null)" exit | cut -f2)" 2 "--keep-build with no build served: a usage error"

# C5: the way. On 128 GB with 98,304 MiB, serving order 2 for four at 32,768 (34,447 MiB on the GPU, 34,879
# in all) and testing order 1 for one at 8,192 (42,256 + 180 = 42,436 on the GPU, 42,920 in all): 76,883 +
# 1,024 is within 98,304 and 131,072 - 77,799 is at least 12,288, so side by side. On 64 GB, in turn.
LOADED="--serving $B2 --loaded $B2 4 32768"
same "$(kind "$(on $GB128 98304 "$HREG" $HH $LOADED)" choice | cut -f2,7)" "$B1${T}side-by-side" "128 GB, order 2 loaded: order 1 tested side by side"
same "$(kind "$(on $GB64 53084 "$HREG" $HH $LOADED)" choice | cut -f2,7)" "$B1${T}in-turn" "64 GB, order 2 loaded: order 1 tested in turn"
same "$(kind "$(on $GB128 77907 "$HREG" $HH $LOADED)" choice | cut -f7)" "side-by-side" "GPU limit 77,907 MiB, the two needs plus 1,024: side by side"
same "$(kind "$(on $GB128 77906 "$HREG" $HH $LOADED)" choice | cut -f7)" "in-turn" "GPU limit one MiB less: in turn"
same "$(kind "$(on $GB128 98304 "$HREG" $HH --serving $B2)" choice | cut -f7)" "in-turn" "nothing loaded (the engine not running): in turn"
same "$(kind "$(on $GB128 98304 "$HREG" $HH)" choice | cut -f7)" "in-turn" "a first install, nothing loaded: in turn, at the household's setting"
same "$(kind "$(on $GB128 98304 "$HREG" $HH --serving $B2 --loaded b4cvp4l4ee5tl 1 8192)" choice | cut -f7)" "in-turn" \
  "a loaded build the registry does not define: in turn, the safe way"

# D3.7 with section C's own `fit` (T44 used a stand-in): the build served no longer fitting lets a later
# one be offered; the caller's `hold` and `failed/` rule builds out through the same judge
same "$(pick "$(on $GB36 27648 "$HREG" $HH --serving $B1 --people 4)")" "$B2 4 15360 0" "serving order 1 on 36 GB, where it no longer fits: order 2 is offered"
same "$(pick "$(on $GB64 53084 "$HREG" $HH --serving $B2 --held $B1)")" "$B2 4 32768 0" "order 1 held: order 2 stays"
same "$(pick "$(on $GB64 53084 "$HREG" $HH --failed $B1)")" "$B2 4 32768 0" "a first install with order 1 in failed/: order 2"
o=$(on $GB64 53084 "$HREG" $HH --failed $B1 --held $B2)
same "$(pick "$o")" "refused none failed,held 3" "every build failed or held: refused, naming why"
same "$(kind "$o" build | cut -f4 | paste -sd' ' -)" "failed held" "each build shows its own code"
cp "$HREG" "${TMPDIR%/}/t91-withdrawn.tsv"; printf 'withdraw\t%s\tsecurity\n' $B2 >> "${TMPDIR%/}/t91-withdrawn.tsv"
same "$(pick "$(on $GB36 27648 "${TMPDIR%/}/t91-withdrawn.tsv" $HH --serving $B2)")" "refused none fit,withdrawn 3" \
  "serving order 2, withdrawn, where order 1 cannot fit: nothing to move to, and not called a lack of fit"
done_
