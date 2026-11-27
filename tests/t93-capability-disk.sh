# T93: the disk rule (C6). Room at 5% of the volume and at 20 GiB, one byte either side; free disk read
# from `df -k` in KiB and counted in bytes; the shortest run of builds from the front that makes room is
# named whole, failed first and then the oldest kept, with no build in it dropped (C6, settled at V3: no
# failed build is spared to save a count); a file named by another recipe's descriptor is not counted
# free, nor one the build in use names. The update's own use of the names (asking, removing, cleanup) is
# U6's (T17). Mutants: tests/mutants/T93a and T93b, the plan's; T93c to T93e, the other three clauses;
# T93f, a failed build the room does not need dropped from the run.
. "$TESTS/lib.sh"
. "$TESTS/capability-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t93.XXXXXX")

# The files of the two household builds (A6, the fixture registry), and four model stand-ins
E=82b00abc740160e1b9980e6cc79c117345fa34af058c80e6c0a69aa8ddccde75      # engine b12359
M1=c56fdf063ad8c215c0e56c322383b3fb242189ce9047cdbb3e7dcad11380c1b8     # order 1's model
M2=d3a024d29e0e8f35d9353f5d4f08fc3715406835c8ae1328ce2f3bd212a43434     # order 2's model
P1=d54dd73b805021458132f1abadff68e79dde941432f6940c32cdecdeb1190767     # order 1's template
P2=39f03c383413f531fd302c06c7e982ad98c83f0657a8339ae25478ccb81fdcda     # order 2's template
S=c44bab6bddc7d9f48e834d2120bffeda2aa087b0bb4a2f1c74d17ab103d02e49      # the system prompt
Q=41bb822fb2b3768364f4676059d99b4d9115cc958eafe7dac3e6a5e02747faf9      # the recipe's test
X1=$(printf '%064d' 1) X2=$(printf '%064d' 2) X3=$(printf '%064d' 3) Y1=$(printf '%064d' 4)
K1=bdmeh7senvu4o K2=bn4tipluss7mf K3=bcvfdsj3etq36   # kept, oldest first
F1=b5i5hlb3txrgy F2=bcrviv7l7zgay                    # failed, oldest first
R2=r3xlfscwhhghx Q1=b37bscio6jhg6                    # another recipe, and the build it serves
desc() { printf 'desc\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"; }
file() { printf 'file\t%s\t%s\n' "$1" "$2"; }
verdict() { # OUTPUT -> `choice <disk verdict>` or `refused <reason>`
  local c
  c=$(kind "$1" choice | cut -f8)
  if [ -n "$c" ]; then echo "choice $c"; else echo "refused $(kind "$1" refused | cut -f2- | tr "\t" " ")"; fi
}

# --- The floor, on an update that downloads nothing: serving order 1, its files all on disk
{ echo 'auster-disk 1'; file store/$E 16907811; file engines/$E 42000000; file store/$M1 44407639744
  desc $HH serving - $B1 $E $M1 $P1 $S $Q; } > "$W/held"
floor() { # FREE TOTAL -> verdict, serving order 1 on the 64 GB Mac with that much free on that volume
  verdict "$(AU_DISK_FREE_BYTES=$1 AU_DISK_TOTAL_BYTES=$2 on $GB64 53084 "$HREG" $HH --serving $B1 --disk "$W/held")"
}
o=$(AU_DISK_FREE_BYTES=21474836480 AU_DISK_TOTAL_BYTES=245107195904 on $GB64 53084 "$HREG" $HH --serving $B1 --disk "$W/held")
same "$(kind "$o" disk)" "disk${T}0${T}21474836480${T}21474836480${T}0" "the build served and its files on disk: nothing to download"
# 245,107,195,904 bytes: 5% is 12,255,359,795.2, less than 20 GiB, so the floor is 20 GiB, 21,474,836,480
same "$(floor 21474836480 245107195904)" "choice room" "small volume, exactly 20 GiB free: room"
same "$(floor 21474836479 245107195904)" "refused room" "small volume, 20 GiB less a byte: no room"
# 1,000,000,000,019 bytes: 5% is 50,000,000,000.95, rounded up to 50,000,000,001, more than 20 GiB
same "$(floor 50000000001 1000000000019)" "choice room" "large volume, exactly 5% free (rounded up): room"
same "$(floor 50000000000 1000000000019)" "refused room" "large volume, 5% less a byte: no room"
# 429,496,729,600 bytes: 5% is exactly 20 GiB
same "$(floor 21474836480 429496729600):$(floor 21474836479 429496729600)" "choice room:refused room" "5% exactly 20 GiB: the same floor either way"

# --- df -k, in KiB. This Mac's volume, 1,948,404,040 KiB, is 1,995,165,736,960 bytes; 5% is 99,758,286,848
# bytes, 97,420,202 KiB exactly
dfk() { # AVAILABLE-KIB [-P] -> df -k output for that volume
  if [ "${2:-}" = -P ]; then
    printf 'Filesystem   1024-blocks       Used Available Capacity  Mounted on\n/dev/disk3s1  1948404040 1625052236 %9s    95%%    /System/Volumes/Data\n' "$1"
  else
    printf 'Filesystem   1024-blocks       Used Available Capacity iused      ifree %%iused  Mounted on\n/dev/disk3s1  1948404040 1625052236 %9s    95%% 2560778 2893107240    0%%   /System/Volumes/Data\n' "$1"
  fi
}
viadf() { # DF-FILE -> verdict, serving order 1 on the 64 GB Mac
  verdict "$(on $GB64 53084 "$HREG" $HH --serving $B1 --disk "$W/held" --df "$1")"
}
dfk 97420202 > "$W/df-in"; dfk 97420201 > "$W/df-out"; dfk 97420202 -P > "$W/df-p"
o=$(on $GB64 53084 "$HREG" $HH --serving $B1 --disk "$W/held" --df "$W/df-in")
same "$(kind "$o" figures | cut -f4,5,8,9)" "99758286848${T}1995165736960${T}measured${T}measured" "df -k: KiB read and counted in bytes"
same "$(viadf "$W/df-in")" "choice room" "df -k with 97,420,202 KiB available, exactly 5%: room"
same "$(viadf "$W/df-out")" "refused room" "one KiB less: no room"
same "$(viadf "$W/df-p")" "choice room" "df -k -P, the same figures: room"
o=$(AU_DISK_FREE_BYTES=0 AU_DISK_TOTAL_BYTES=245107195904 on $GB64 53084 "$HREG" $HH --serving $B1 --disk "$W/held" --df "$W/df-in")
same "$(kind "$o" figures | cut -f4,8)" "0${T}test" "the test variables win over df"
printf 'Filesystem 512-blocks Used Available Capacity Mounted on\n/dev/disk3s1 3896808080 3250104472 194840404 95%% /\n' > "$W/df-512"
same "$(viadf "$W/df-512")" "refused figures disk,df-form" "df in 512-byte blocks: refused, nothing guessed"
{ dfk 97420202; echo '/dev/disk4s1  100 50 50 50% /Volumes/Other'; } > "$W/df-two"
same "$(viadf "$W/df-two")" "refused figures disk,df-form" "df naming two volumes: refused"

# --- Which builds to remove. An update on the 64 GB Mac serving order 2, to order 1 (earlier, and it
# fits: D3.7). Order 1 downloads its model, 44,407,639,744 bytes; the engine is on disk already. On the
# small volume (floor 21,474,836,480) room needs 65,882,476,224 free, less what removal frees.
# On disk: kept K1 (oldest, model X1, 30 GB), K2 (X2, 10 GB), K3 (newest, X3, 5 GB); failed F1 (Y1, 8 GB)
# and F2 (every file shared with the build served: it frees nothing); and recipe R2's serving names X1, so
# K1 frees nothing either. The order is F1, F2, K1, K2, K3, freeing 8, 0, 0, 10 and 5 GB.
{ echo 'auster-disk 1'
  file store/$E 16907811; file engines/$E 42000000; file store/$M2 14334432256; file store/$P2 2048
  file store/$S 73; file store/$Q 4096
  file store/$X1 30000000000; file store/$X2 10000000000; file store/$X3 5000000000; file store/$Y1 8000000000
  desc $HH serving - $B2 $E $M2 $P2 $S $Q
  desc $HH kept 2026-03-01T00:00:00Z $K3 $E $X3 $P2 $S $Q
  desc $HH kept 2026-01-01T00:00:00Z $K1 $E $X1 $P2 $S $Q
  desc $HH failed 2026-02-20T00:00:00Z $F2 $E $M2 $P2 $S $Q
  desc $HH kept 2026-02-01T00:00:00Z $K2 $E $X2 $P2 $S $Q
  desc $HH failed 2026-02-15T00:00:00Z $F1 $E $Y1 $P2 $S $Q
  desc $R2 serving - $Q1 $E $X1 $P2 $S $Q; } > "$W/many"
NEED=$((44407639744 + 21474836480))
same "$NEED" 65882476224 "room needs 65,882,476,224 free, by hand"
removals() { # FREE [HOLDINGS] -> the builds named, in order, each with its yes, or the refusal
  local o
  o=$(AU_DISK_FREE_BYTES=$1 AU_DISK_TOTAL_BYTES=245107195904 on $GB64 53084 "$HREG" $HH --serving $B2 --disk "${2:-$W/many}")
  if [ -n "$(kind "$o" choice)" ]; then
    printf '%s %s\n' "$(kind "$o" choice | cut -f2,8 | tr '\t' ' ')" "$(kind "$o" remove | cut -f3,5,6 | tr '\t\n' ': ')"
  else verdict "$o"; fi
}
same "$(removals $NEED)" "$B1 room " "exactly enough free: room as it is, nothing named"
same "$(removals $((NEED - 1)))" "$B1 remove failed:$F1:- " "one byte short: the oldest failed build is enough"
same "$(removals $((NEED - 8000000000)))" "$B1 remove failed:$F1:- " "8 GB short: F1 alone, which frees exactly that"
# 10 GB short, K2's model exactly: F1 then K2, F1 kept in though K2 alone would do (a failed build is never
# a rollback target). F2 and K1 free nothing (F2's files are the served build's, K1's model is another
# recipe's), so neither is named: removing them would cost a rollback target for no room
same "$(removals $((NEED - 10000000000)))" "$B1 remove failed:$F1:- kept:$K2:- " \
  "10 GB short: F1 then K2, F1 not dropped, F2 and K1 (freeing nothing) not named"
same "$(removals $((NEED - 18000000000)))" "$B1 remove failed:$F1:- kept:$K2:- " \
  "18 GB short: F1 and K2; F2 and K1 free nothing and are not named"
same "$(removals $((NEED - 23000000000)))" "$B1 remove failed:$F1:- kept:$K2:- kept:$K3:yes " \
  "23 GB short: the run to K3, the one before the one in use, on the person's yes"
o=$(AU_DISK_FREE_BYTES=$((NEED - 23000000000)) AU_DISK_TOTAL_BYTES=245107195904 on $GB64 53084 "$HREG" $HH --serving $B2 --disk "$W/many")
same "$(kind "$o" disk)" "disk${T}44407639744${T}21474836480${T}$((NEED - 23000000000))${T}23000000000" "the disk line: download, floor, free, and the 23 GB freed"
same "$(kind "$o" remove | head -1)" "remove${T}$HH${T}failed${T}2026-02-15T00:00:00Z${T}$F1${T}-" "a remove line in full"
o=$(AU_DISK_FREE_BYTES=$((NEED - 23000000001)) AU_DISK_TOTAL_BYTES=245107195904 on $GB64 53084 "$HREG" $HH --serving $B2 --disk "$W/many")
same "$(verdict "$o"):$(kind "$o" room)" "refused room:room${T}$B1${T}44407639744${T}$NEED" "one byte more short than every removal frees: refused, saying the space needed"

# The build in use is never counted free, even with no descriptor of its own listed: without the
# serving line, F2's model (the one in use) must still not count, so 14,334,432,256 short needs the run to K2
grep -v "^desc${T}$HH${T}serving" "$W/many" > "$W/no-serving"
same "$(removals $((NEED - 14334432256)) "$W/no-serving")" "$B1 remove failed:$F1:- kept:$K2:- " \
  "the build in use's files never count, listed or not"

# The holdings are Auster's own: a line out of form is a usage error, never half read
{ cat "$W/many"; printf 'file\tstore/../x\t1\n'; } > "$W/bad"
same "$(kind "$(AU_DISK_FREE_BYTES=1 AU_DISK_TOTAL_BYTES=1 on $GB64 53084 "$HREG" $HH --serving $B2 --disk "$W/bad" 2>/dev/null)" exit | cut -f2)" 2 \
  "holdings with a path out of form: a usage error"
done_
