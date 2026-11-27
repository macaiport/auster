# T26, the install's half (V5): an install refuses while the lock, builds/updating, is live, and leaves it
# as it is; a lock whose process is gone, whose number now belongs to another process, or that is from an
# earlier boot, is taken over (D3.1, D3.6). The other commands' halves (a second update, rollback, cleanup,
# `auster stop`, `key revoke`, the check job) and mutant (c), the generic reader, come with U2, U4, U6 and
# V7. Mutants: tests/mutants/T26a and T26b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir -m 700 "$DATA" "$DATA/builds"
: > "$DATA/.auster-data-root"
sleep 300 & live=$!
printf '%s\tThu Nov 20 10:00:00 2026\tsleep 300\n' "$live" > "$STUB_PS_TABLE"
BOOT=$(sysctl -n kern.bootsessionuuid)   # the stub's

stale_lock "$DATA/builds/updating" "$live" "$BOOT" "Thu Nov 20 10:00:00 2026"
lock=$(cat "$DATA/builds/updating")
before=$(snapshot "$H")
run_install $'no\nno\n' "$IR"
same "$RC" 1 "a live lock: exit 1"
says "Another run of Auster (process $live) is installing, updating or changing the server." "a live lock: it says another run holds it"
grep -q 'Auster is ready to install' "$W/out" && bad "a live lock: it went on to the question" || ok "a live lock: it asks nothing"
same "$(cat "$DATA/builds/updating")" "$lock" "a live lock: left as it was"
same "$(snapshot "$H")" "$before" "a live lock: nothing else changed"
same "$(requests | grep -c "$ENGINE_URL")" 0 "a live lock: nothing fetched for the install"

taken() { # LABEL -> after the run: the question was reached, so the lock was taken; it is released at the end
  same "$RC" 1 "$1: exit 1 at the no"
  says "Auster is ready to install household on this Mac." "$1: taken over, and the run reached the question"
  [ -e "$DATA/builds/updating" ] && bad "$1: a lock is left" || ok "$1: the lock is released at the end"
  same "$(ls -A "$DATA")" ".auster-data-root
builds" "$1: what this run made is gone, and what was there stays"
}
stale_lock "$DATA/builds/updating"
run_install $'no\nno\n' "$IR"; taken "a lock whose process is gone"
stale_lock "$DATA/builds/updating" "$live" "$BOOT" "Thu Nov 19 09:00:00 2026"
run_install $'no\nno\n' "$IR"; taken "a lock whose number now belongs to another process"
stale_lock "$DATA/builds/updating" "$live" 00000000-1111-2222-3333-444444444444 "Thu Nov 20 10:00:00 2026"
run_install $'no\nno\n' "$IR"; taken "a lock from an earlier boot"
printf 'not a lock\n' > "$DATA/builds/updating"
run_install $'no\nno\n' "$IR"; taken "a lock that cannot be read (absent)"
kill "$live" 2>/dev/null
done_
