# T90: the context limit of the model file applies per person (C4): a file limit of 20,000 gives at most
# 19,456 per person; a limit below the recipe's minimum passes the build over. Order 1's model line (line
# 3, field 10) is changed at run time; the Mac is 64 GB with 53,084 MiB, where order 1 fits at the
# recipe's maximum for four. Mutant: tests/mutants/T90a.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t90.XXXXXX")
limit() { # LIMIT -> a copy of the household registry with order 1's model file limited to LIMIT tokens
  sed "3s/${T}262144\$/${T}$1/" "$HREG" > "$W/l$1.tsv"
  printf '%s\n' "$W/l$1.tsv"
}
same "$(sed -n 3p "$(limit 20000)" | cut -f1,2,10)" "model${T}mjhs5h65av6o4${T}20000" "the fixture: Mistral's model line, limit 20,000"

same "$(pick "$(on $GB64 53084 "$(limit 20000)" $HH)")" "$B1 4 19456 0" "file limit 20,000, four people: order 1 at 19,456 each"
same "$(pick "$(on $GB64 53084 "$(limit 20000)" $HH --people 1)")" "$B1 1 19456 0" "file limit 20,000, one person: still 19,456"
same "$(pick "$(on $GB64 53084 "$(limit 19456)" $HH)")" "$B1 4 19456 0" "file limit 19,456: 19,456, the limit itself"
same "$(pick "$(on $GB64 53084 "$(limit 19455)" $HH)")" "$B1 4 18432 0" "file limit 19,455: one step down, 18,432"
same "$(pick "$(on $GB64 53084 "$(limit 8192)" $HH)")" "$B1 4 8192 0" "file limit 8,192, the recipe's minimum: order 1 at 8,192"

o=$(on $GB64 53084 "$(limit 8191)" $HH)
same "$(pick "$o")" "$B2 4 32768 0" "file limit 8,191, below the recipe's minimum: order 1 passed over, order 2 at 32,768"
same "$(kind "$o" build | head -1 | cut -f2-7 | tr '\t' ' ')" "1 $B1 fit - - -" "order 1 shows fit, with no context and no needs"

# The limit never lowers the recipe's own maximum: a file limit above it leaves the maximum binding
same "$(context_of "$(on $GB64 53084 "$(limit 1048576)" $HH)")" 32768 "file limit 1,048,576: the recipe's maximum, 32,768"

# Every build's file below the minimum: nothing has a context, and no smallest need can be named
sed "4s/${T}131072\$/${T}4096/" "$(limit 4096)" > "$W/both.tsv"
o=$(on $GB64 53084 "$W/both.tsv" $HH)
same "$(pick "$o"):$(kind "$o" needs)" "refused fit 3:" "both files below the minimum: refused fit, no needs line"
done_
