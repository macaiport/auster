#!/bin/bash
# Phase 1 of Auster, by hand (docs/phase-1.md): fetch one model file from Hugging Face by commit, with
# no login, resumable, and keep it only if its size and sha256 equal the ones given. Logs the time taken.
#
#   scripts/phase-1/fetch-model.sh <repo> <commit> <file> <size> <sha256>
set -u
W="${AUSTER_P1:-$HOME/Library/Developer/Auster/phase-1}"
[ $# -eq 5 ] || { echo "usage: $0 <repo> <commit> <file> <size> <sha256>" >&2; exit 2; }
REPO=$1; COMMIT=$2; FILE=$3; SIZE=$4; SHA=$5
[[ "$COMMIT" =~ ^[0-9a-f]{40}$ && "$SHA" =~ ^[0-9a-f]{64}$ && "$SIZE" =~ ^[0-9]{1,15}$ ]] || { echo "bad commit, size or hash" >&2; exit 2; }
[[ "$FILE" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,200}\.gguf$ && "$REPO" =~ ^[A-Za-z0-9._-]{1,96}/[A-Za-z0-9._-]{1,96}$ ]] || { echo "bad repo or file name" >&2; exit 2; }
cd "$W/store" || exit 1
LOG="$W/runs/fetch-$FILE.log"
now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }

if [ -f "$FILE" ]; then echo "$FILE is already here" | tee -a "$LOG"; exit 0; fi
echo "start $(date '+%F %T'), free $(df -g . | awk 'NR==2{print $4}') GiB" | tee -a "$LOG"
t0=$(now)
/usr/bin/curl -q --proto '=https' --proto-redir '=https' --tlsv1.2 -sSL -C - --retry 3 -o "$FILE.part" \
  -w 'code %{http_code} bytes %{size_download} secs %{time_total} speed %{speed_download}\n' \
  "https://huggingface.co/$REPO/resolve/$COMMIT/$FILE" >> "$LOG" 2>&1
rc=$?
t1=$(now)
echo "curl exit $rc after $(echo "$t1 - $t0" | bc) s" | tee -a "$LOG"
got=$(stat -f %z "$FILE.part" 2>/dev/null || echo 0)
[ "$got" = "$SIZE" ] || { echo "size $got, expected $SIZE: kept as .part to resume" | tee -a "$LOG"; exit 1; }
t0=$(now); h=$(/usr/bin/openssl dgst -sha256 -r "$FILE.part" | cut -d' ' -f1); t1=$(now)
echo "sha256 in $(echo "$t1 - $t0" | bc) s" | tee -a "$LOG"
if [ "$h" = "$SHA" ]; then
  mv "$FILE.part" "$FILE" && chmod 444 "$FILE" && echo "verified: $FILE ($SIZE bytes)" | tee -a "$LOG"
else
  rm -f "$FILE.part"; echo "HASH MISMATCH: got $h; the download is deleted" | tee -a "$LOG"; exit 1
fi
