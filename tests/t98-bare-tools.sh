# T98: the suite runs under /bin/bash 3.2 with a PATH of what macOS 14 ships. Its mutant (T98a) makes
# tools/mint-id use a tool outside that PATH, and the whole suite must then go red.
. "$TESTS/lib.sh"
same "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}" 3.2 "bash is 3.2"
for t in timeout jq python3 git brew base32; do
  if command -v "$t" >/dev/null 2>&1; then bad "$t is reachable"; else ok "$t is not reachable"; fi
done
for t in openssl od tr sed awk curl shasum plutil osascript launchctl; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t is reachable"; else bad "$t is missing"; fi
done
done_
