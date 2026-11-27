# T50: a line with an empty field in the middle and an extra field at the end is passed over, not read
# with its fields shifted; a line with CRLF endings is passed over (A3). Also any other control character
# (ESC, NUL, DEL, US) and overlong UTF-8. Mutants: tests/mutants/T50a, the plan's; T50b, control
# characters narrowed to CR; T50c, no overlong-UTF-8 check.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t50.XXXXXX")

# empty-middle.tsv: a later recipe line, its third field empty and its values one field to the right
o=$(reader "$REG/empty-middle.tsv" "$HH"); same $? 0 "empty-middle: read"
same "$(kind "$o" passed | cut -f2,4)" "9${T}field 3 (label) is empty" "the line with the empty field is passed over"
same "$(kind "$o" recipe | cut -f5-9 | tr '\t' ' ')" "household publisher,endorsed 4 8192 32768" "the recipe keeps its first line"
same "$(taken "$o")" "$B1" "order 1 is taken"

# Two tabs elsewhere: in an order line, and before a withdraw's reason
extend "$REG/good-v0.1.0.tsv" "$W/order.tsv" "order${T}$HH${T}${T}$B2${T}$B1"
o=$(reader "$W/order.tsv" "$HH")
same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}field 3 (build) is empty:$B1" "an order line with an empty field is passed over"
extend "$REG/good-v0.1.0.tsv" "$W/withdraw.tsv" "withdraw${T}$B1${T}${T}security"
o=$(reader "$W/withdraw.tsv" "$HH")
same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}field 3 (reason) is empty:$B1" "a withdraw line with an empty reason is passed over, nothing withdrawn"

# CRLF
o=$(reader "$REG/crlf-line.tsv" "$HH")
same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}holds a CR or another control character:$B1" \
  "crlf-line: the order line ending in CR LF is passed over, the earlier order stands"
o=$(reader "$REG/crlf-all.tsv" "$HH"); same "$?:$(state "$o")" 3:unreadable "crlf-all: its first line holds a CR, so it is not read"
{ cat "$REG/good-v0.1.0.tsv"; printf 'withdraw\t%s\tsecurity\tlater\r\n' "$B1"; } > "$W/cr-extra.tsv"
o=$(reader "$W/cr-extra.tsv" "$HH")
same "$(passed_lines "$o"):$(taken "$o")" "9:$B1" "a CR in a field after the last one known still passes the line over"

# The line's own shape, beyond T50's two cases: the reader's reading of A3's "one record a line" of plain
# text. A last line with no newline (a file cut short) is passed over, and so is an empty line, and a
# line that is not UTF-8 even in a field after the last one known
head -c $(( $(stat -f %z "$REG/good-v0.1.0.tsv") - 1 )) "$REG/good-v0.1.0.tsv" > "$W/nonl.tsv"
o=$(reader "$W/nonl.tsv" "$HH")
same "$(passed_lines "$o"):$(state "$o")" "8:unreadable" "a last line with no newline is passed over: the only order line goes, so the recipe cannot be read"
g=$(gate "$W/nonl.tsv"); same "$?:$g" "1:line 8: no newline at the end of the file" "the gate fails it"
extend "$REG/good-v0.1.0.tsv" "$W/blank.tsv" "" "$(rec withdraw $B1 security)"
o=$(reader "$W/blank.tsv")
same "$(kind "$o" passed | cut -f2,4):$(state "$o")" "9${T}an empty line:ok" "an empty line is passed over, the lines after it are read"
same "$(kind "$(reader "$W/blank.tsv" "$HH")" build | head -1 | cut -f3)" withdrawn "the withdraw line after the empty one is read"
{ cat "$REG/good-v0.1.0.tsv"; printf 'withdraw\t%s\tsecurity\tlater\377\n' "$B1"; } > "$W/latin.tsv"
o=$(reader "$W/latin.tsv" "$HH")
same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}not UTF-8:$B1" "a line that is not UTF-8 is passed over, nothing withdrawn"

# Control characters other than CR, and overlong UTF-8, each in a field after the last one known, where no
# field pattern looks: the line is still passed over, and nothing is withdrawn
for c in 'ESC 033' 'NUL 000' 'DEL 177' 'US 037'; do
  { cat "$REG/good-v0.1.0.tsv"; printf "withdraw\t%s\tsecurity\tlater\\${c#* }\n" "$B1"; } > "$W/ctl.tsv"
  same "$(sed -n 9p "$W/ctl.tsv" | od -An -tx1 | tr -d ' \n' | tail -c 4)" "$(printf '%02x0a' $((8#${c#* })))" "the ${c% *} line holds that byte"
  o=$(reader "$W/ctl.tsv" "$HH")
  same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}holds a CR or another control character:$B1" "a line holding ${c% *} is passed over, nothing withdrawn"
done
for u in '2 \300\257' '3 \340\200\257'; do   # / written in two bytes, and in three
  { cat "$REG/good-v0.1.0.tsv"; printf "withdraw\t%s\tsecurity\tlater${u#* }\n" "$B1"; } > "$W/overlong.tsv"
  o=$(reader "$W/overlong.tsv" "$HH")
  same "$(kind "$o" passed | cut -f2,4):$(taken "$o")" "9${T}not UTF-8:$B1" "overlong UTF-8 in ${u% *} bytes is not UTF-8: passed over, nothing withdrawn"
done
g=$(gate "$W/ctl.tsv"); same "$?:$g" "1:line 9: holds a CR or another control character" "the gate fails a line holding a control character"

g=$(gate "$REG/empty-middle.tsv"); same "$?:$g" "1:line 9: field 3 (label) is empty" "the gate fails empty-middle"
g=$(gate "$REG/crlf-line.tsv"); same "$?:$g" "1:line 9: holds a CR or another control character" "the gate fails crlf-line"
done_
