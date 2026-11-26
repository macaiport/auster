# T47: tools/mint-id (plan A2). Mutants: tests/mutants/T47a to T47c.
. "$TESTS/lib.sh"
M="$ROOT/tools/mint-id"
STUBS="$TESTS/stubs"
same "$(PATH="$STUBS:$PATH" STUB_OPENSSL_RAND_HEX=0000000000000000 "$M" b)" baaaaaaaaaaaa "all-zero bytes"
same "$(PATH="$STUBS:$PATH" STUB_OPENSSL_RAND_HEX=ffffffffffffffff "$M" b)" b777777777777 "all-one bytes"
same "$(PATH="$STUBS:$PATH" STUB_OPENSSL_RAND_HEX=fffffffffffffff0 "$M" b)" b777777777777 "only the first 60 bits count"
same "$(PATH="$STUBS:$PATH" STUB_OPENSSL_RAND_HEX=0000000000000010 "$M" b)" baaaaaaaaaaab "the 60th bit is the last character's lowest"
for k in r b e m k; do
  id=$("$M" $k)
  if [[ "$id" =~ ^$k[a-z2-7]{12}$ ]]; then ok "kind $k matches its pattern"; else bad "kind $k: $id"; fi
done
"$M" x >/dev/null 2>&1; same $? 2 "an unknown kind is a usage error"
"$M" >/dev/null 2>&1; same $? 2 "no kind is a usage error"
out=$(for i in $(seq 1000); do "$M" m; done)
same "$(printf '%s\n' "$out" | sort -u | wc -l | tr -d ' ')" 1000 "1,000 real runs, no repeat"
same "$(printf '%s\n' "$out" | grep -c -v -E '^m[a-z2-7]{12}$')" 0 "only a-z and 2-7"
done_
