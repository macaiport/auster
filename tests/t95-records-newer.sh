# T95, the readers' half and bin/auster's (U2): an older version meeting a record of a newer format -- `auster-record 2`
# (`auster-descriptor 2` for a descriptor) with format 1's fields, with a field more, and beyond its bound (a one-line
# record over 4,096 bytes) -- reads the format first and never as its own. Each reader of common/auster's, the rule
# file's and section C's says newer; the jobs' own readers take it as absent (the check job's record of its own,
# _update/engine, as newer); and none rewrites it. Then on an installed Mac: every command of bin/auster that writes
# refuses while any record is of a newer format, says how to update or remove, and changes nothing; `status` names
# each such record and says the same; `remove` still works. The driver's half is t95-install-newer.sh.
# Mutants: tests/mutants/T95c, T95d and T95e (T95a and T95b are the lock's, T95f the driver's).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/records-helpers.sh"
records_env

for rec in $RECORDS; do
  p=$(path_of "$rec")
  for c in same field big; do
    newer_of "$rec" "$c" "$p"
    was=$(shasum -a 256 < "$p")
    for r in $(readers_of "$rec"); do
      case "$r" in auster.*|updates.*|js.*|check.state) want=newer ;; *) want=absent ;; esac
      same "$(read_with "$r" "$p")" "$want" "$rec in format 2, $c, $r: $want"
    done
    same "$(shasum -a 256 < "$p")" "$was" "$rec in format 2, $c: as it was"
  done
  good "$rec" "$p"
done
newer_of stopped big "$W/b"
[ "$(stat -f %z "$W/b")" -gt 4096 ] && ok "the one-line record beyond its bound is over 4,096 bytes" || bad "the big one-line record is small"
cd "$W" || exit 1

# --- bin/auster on an installed Mac
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
newer_of hold same "$DATA/builds/$IR/hold"
newer_of noted field "$DATA/_update/noted"
newer_of local-name big "$DATA/builds/local-name"
for f in "$DATA/builds/$IR/hold" "$DATA/_update/noted" "$DATA/builds/local-name"; do
  before=$(snapshot "$DATA")
  for c in stop start restart network update 'people 2' 'key add ipad2' 'key revoke ipad'; do
    auster $c
    same "$RC" 1 "${f##*/} of a newer format, $c: refused"
    outsays "was written by a newer version of Auster, so this one leaves it as it is." "${f##*/} of a newer format, $c: it says so"
    outsays "Paste the installer line from the guide to update, or remove Auster with: \"$DATA/bin/auster\" remove" "${f##*/} of a newer format, $c: and how to update or remove"
  done
  same "$(snapshot "$DATA")" "$before" "${f##*/} of a newer format: after every command, the data root as it was"
  auster status
  same "$RC" 0 "${f##*/} of a newer format: status works"
  outsays "${f#"$DATA"/} was written by a newer version of Auster, which this one does not read." "status names ${f##*/}"
  outsays "Paste the installer line from the guide to update, or remove Auster with" "status says how to update or remove"
  rm -f "$f"
done
newer_of serving same "$DATA/builds/$IR/serving"
was=$(shasum -a 256 < "$DATA/builds/$IR/serving")
auster restart
same "$RC:$(shasum -a 256 < "$DATA/builds/$IR/serving")" "1:$was" "serving of a newer format: restart refused, serving never rewritten"
ANSWERS=$'yes\nno\n' auster remove
same "$RC" 0 "with a record of a newer format, remove still works"
outsays "The files are kept." "and keeps the files on a no"
done_
