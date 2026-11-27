# T95, the installer's half (V5, U2): a driver meeting records of a newer format refuses with exit 1, says how
# to update or remove, and never rewrites them. The lock, builds/updating: `auster-record 2` with exactly
# format 1's fields, with one field more, and larger than 4,096 bytes; the format is read before the fields
# or the size are counted. And `builds/mac` and the stamp in format 2; then (U2) every other record of D3.1, each
# in format 2 alone. The readers' half, and bin/auster's, are t95-records-newer.sh. Mutants: tests/mutants/T95a,
# T95b and T95f.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir -m 700 "$DATA" "$DATA/builds"
: > "$DATA/.auster-data-root"
BOOT=$(sysctl -n kern.bootsessionuuid)
/usr/bin/true & gone=$!; wait "$gone"

newer() { # FILE LABEL -> after the run: exit 1, it says a newer version wrote FILE and how to remove, FILE as it was
  same "$RC" 1 "$2: exit 1"
  says "$1 was written by a newer version of Auster, so this one leaves it as it is." "$2: it says a newer version wrote it"
  says "Paste the installer line from the guide to update, or remove Auster with: \"$DATA/bin/auster\" remove" "$2: and how to update or remove"
  same "$(shasum -a 256 < "$1")" "$was" "$2: the record is as it was"
  grep -q 'Auster is ready to install' "$W/out" && bad "$2: it went on" || ok "$2: it went no further"
}
L="$DATA/builds/updating"
printf 'auster-record 2\t%s\t%s\tThu Nov 26 08:00:00 2026\n' "$gone" "$BOOT" > "$L"; was=$(shasum -a 256 < "$L")
run_install $'no\nno\n' "$IR"; newer "$L" "the lock in format 2, with format 1's four fields"
printf 'auster-record 2\t%s\t%s\tThu Nov 26 08:00:00 2026\tmore\n' "$gone" "$BOOT" > "$L"; was=$(shasum -a 256 < "$L")
run_install $'no\nno\n' "$IR"; newer "$L" "the lock in format 2, with one field more"
{ printf 'auster-record 2\t%s\t%s\tThu Nov 26 08:00:00 2026\t' "$gone" "$BOOT"; printf '%05000d\n' 0; } > "$L"; was=$(shasum -a 256 < "$L")
[ "$(stat -f %z "$L")" -gt 4096 ] && ok "the fixture is larger than 4,096 bytes" || bad "the fixture is small"
run_install $'no\nno\n' "$IR"; newer "$L" "the lock in format 2, larger than 4,096 bytes"
rm -f "$L"

M="$DATA/builds/mac"
printf 'auster-record 2\ngpu-mib\t53084\nmore\tthan format 1 has\n' > "$M"; was=$(shasum -a 256 < "$M")
run_install $'no\nno\n' "$IR"; newer "$M" "builds/mac in format 2"
rm -f "$M"
mkdir -m 700 "$DATA/_update"
S="$DATA/_update/scripts"
printf 'auster-record 2\trelease\tv0.9.0\t%s\t2026-11-26T15:04:05Z\tmore\n' "$COMMIT" > "$S"; was=$(shasum -a 256 < "$S")
run_install $'no\nno\n' "$IR"; newer "$S" "the stamp in format 2"
rm -f "$S"

# U2: every other record of D3.1, each alone in format 2 (D3.1: every record carries its own format number)
mkdir -m 700 "$DATA/builds/$IR" "$DATA/builds/$IR/kept" "$DATA/builds/$IR/failed"
for r in builds/stopped builds/paused builds/local-name "builds/$IR/start" "builds/$IR/hold" _update/offer _update/tried \
    _update/noted _update/engine "builds/$IR/serving" "builds/$IR/kept/2026-11-20T10:00:00Z-$IB1" "builds/$IR/failed/2026-11-21T10:00:00Z-$IB1"; do
  f="$DATA/$r"
  case "$r" in */serving|*/kept/*|*/failed/*) printf 'auster-descriptor 2\nbuild\tmore than format 1 has\n' ;; *) printf 'auster-record 2\tmore\tthan\tformat\t1\thas\n' ;; esac > "$f"
  was=$(shasum -a 256 < "$f")
  run_install $'no\nno\n' "$IR"; newer "$f" "$r in format 2"
  rm -f "$f"
done
done_
