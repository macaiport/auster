# T4 (D3.2, D3.3, D3.4): two checks in one day make one pair of requests (the changelog and the registry, U3),
# and a check that reached GitHub and failed also uses up the day: a 404 or a 500 with exit 0, curl's exits 22,
# 28 (its time limit), 35, 52, 56 (cut short) and 63 (too large), a 200 with no version heading, and a check
# stopped while it waits, as the check job's watchdog leaves one. Each failure leaves `offer`, `notes.md` and
# `registry` as they were and no temporary file. With the cases of
# 1launcher's test of the refresh that still apply: what a first check writes; the day's edge (86,399 s
# skipped, 86,400 fetched); --now; a `tried` later than now; a `tried` or an `offer` of a newer format left as
# it is, with nothing fetched; a `tried` or an AU_UPDATE_NOW that would run a command; an AU_CURL that is not a
# plain absolute path; an _update that others can write; newer, never different (an older answer leaves the
# offer and the notes as they were); and stubs named mktemp, stat, date and mv first on PATH, never run.
# Mutants: tests/mutants/T4a and T4b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env
changelog "$W/cl" v0.2.0 v0.1.0

# --- a first check, then the day
fresh; stamp release v0.1.0; answer 200 "$W/cl"
same "$(upd --refresh)" "ready${TAB}v0.1.0${TAB}v0.2.0$TAB-${TAB}fetched" "the first check: fetched, ready"
same "$(cat "$U/offer"):$(cat "$U/tried"):$(cmp -s "$U/notes.md" "$W/cl" && echo same):$(leftovers)" \
  "auster-record 1${TAB}v0.2.0$TAB$NOW:auster-record 1$TAB$NOW:same:0" "  ...offer, tried and notes.md written, nothing left over"
same "$(cmp -s "$U/registry" "$W/reg-v0.2.0.tsv" && echo same)" same "  ...and registry, the answer of v0.2.0, whole"
same "$(stat -f %Lp "$U/offer") $(stat -f %Lp "$U/tried") $(stat -f %Lp "$U/notes.md") $(stat -f %Lp "$U/registry")" "600 600 600 600" "  ...each of mode 0600"
same "$(AT=$((NOW + 3600)) upd --refresh | cut -f5):$(asks)" "skipped:2" "a second check an hour later: skipped, still one pair of requests"
same "$(AT=$((NOW + 86399)) upd --refresh | cut -f5):$(asks)" "skipped:2" "at 86,399 s: skipped"
same "$(AT=$((NOW + 86400)) upd --refresh | cut -f5):$(asks)" "fetched:4" "at 86,400 s: fetched, a second pair"
same "$(AT=$((NOW + 86405)) upd --refresh --now | cut -f5):$(asks)" "fetched:6" "--now inside the day: fetched"
tried $((NOW + 500))
same "$(upd --refresh | cut -f5):$(asks)" "fetched:8" "a tried later than now: fetched"

# --- failures use up the day
printf '%s\n' '# Changelog' 'no heading here' > "$W/nohead.md"
{ cat "$W/cl"; head -c 2097152 /dev/zero | tr '\0' 'x'; } > "$W/big.md"
failcase() { # LABEL STATUS [BODY]
  fresh; stamp release v0.1.0; offer v0.1.0; echo "old notes" > "$U/notes.md"; reg_as v0.1.0 "$U/registry"
  local o n g out rc
  o=$(sum "$U/offer"); n=$(sum "$U/notes.md"); g=$(sum "$U/registry")
  [ -z "${RS:-}" ] || answer_reg "$RS" "$RB"   # the registry's own answer, before the changelog's
  answer "$2" "${3:-$W/cl}"
  out=$(upd --refresh); rc=$?
  same "$(printf '%s' "$out" | cut -f5):$rc:$(asks)" "failed:0:2" "$1: failed, exit 0, two requests (the registry is asked whatever the changelog said)"
  same "$(sum "$U/offer"):$(sum "$U/notes.md"):$(sum "$U/registry"):$(leftovers):$(cat "$U/tried" 2>/dev/null)" "$o:$n:$g:0:auster-record 1$TAB$NOW" \
    "  ...offer, notes.md and registry as they were, nothing left over, the day's try recorded"
  same "$(AT=$((NOW + 3600)) upd --refresh | cut -f5):$(asks)" "skipped:2" "  ...and no third request within the day"
}
failcase "a 404 with exit 0" 404 -
failcase "a 500 with exit 0" 500 -
failcase "curl's exit 22" exit:22
failcase "curl's exit 28 (its time limit)" exit:28
failcase "curl's exit 35 (TLS)" exit:35
failcase "curl's exit 52 (an empty reply)" exit:52
failcase "curl's exit 56 after 40 bytes" exit:56:40
failcase "an answer too large (curl's exit 63)" 200 "$W/big.md"
failcase "a 200 with no version heading" 200 "$W/nohead.md"
# and the registry's (U3): the changelog good, the registry failing, the pair is not taken and the day is used up
reg_as v0.2.0 "$W/reg2.tsv"
regfail() { # LABEL STATUS [BODY]
  RS=$2 RB=${3:--}
  failcase "the registry: $1" 200 "$W/cl"
  RS=
}
regfail "a 404 with exit 0" 404 -
regfail "curl's exit 28 (its time limit)" exit:28
regfail "curl's exit 56 after 40 bytes" exit:56:40 "$W/reg2.tsv"
regfail "a 200 that is not a registry" 200 "$W/nohead.md"

fresh; stamp release v0.1.0; offer v0.1.0; answer hang,200 "$W/cl"   # a second request, if one is made, is answered
env AU_UPDATE_DIR="$U" AU_UPDATE_NOW="$NOW" /bin/bash "$S" --refresh > /dev/null 2>&1 & bg=$!   # env execs bash: bg is the check itself
for i in $(seq 100); do [ -n "$(ls "$STUB_CURL_DIR/requests" 2>/dev/null)" ] && break; sleep 0.05; done
kill "$bg" 2>/dev/null; wait "$bg" 2>/dev/null
for d in "$STUB_CURL_DIR"/requests/*; do kill "$(cat "$d/pid")" 2>/dev/null; done
same "$(asks):$(cat "$U/tried" 2>/dev/null):$(cut -f2 "$U/offer")" "1:auster-record 1$TAB$NOW:v0.1.0" "a check stopped while curl waits: the day's try was recorded first"
same "$(AT=$((NOW + 3600)) upd --refresh | cut -f5):$(asks)" "skipped:1" "  ...and no second request within the day"

# --- records of a newer format, and values that would run a command
fresh; stamp release v0.1.0; answer 200 "$W/cl"; printf 'auster-record 2\t%s\tmore\n' $((NOW - 90000)) > "$U/tried"; was=$(sum "$U/tried")
same "$(upd --refresh | cut -f5):$(asks):$(sum "$U/tried"):$([ -e "$U/offer" ] && echo offer || echo none)" "failed:0:$was:none" \
  "a tried of a newer format: nothing fetched, nothing written, tried as it was"
fresh; stamp release v0.1.0; answer 200 "$W/cl"; printf 'auster-record 2\tv0.1.0\t1700000000\n' > "$U/offer"; was=$(sum "$U/offer")
same "$(upd --refresh | cut -f5):$(asks):$(sum "$U/offer"):$([ -e "$U/tried" ] && echo tried || echo none)" "failed:0:$was:none" \
  "an offer of a newer format: nothing fetched, nothing written, offer as it was"
fresh; stamp release v0.1.0; answer 200 "$W/cl"; printf 'auster-record 1\ta[$(touch %s/ran5)]\n' "$W" > "$U/tried"
same "$(upd --refresh | cut -f5):$([ -e "$W/ran5" ] && echo ran || echo none)" "fetched:none" "a tried that would run a command: absent (the fetch is made), nothing run"
fresh; stamp release v0.1.0; answer 200 "$W/cl"
same "$(AT='a[$(touch '"$W"'/ran6)]' upd --refresh | cut -f5):$(grep -c "^auster-record 1$TAB[0-9]\{9,12\}\$" "$U/tried"):$([ -e "$W/ran6" ] && echo ran || echo none)" \
  "fetched:1:none" "an AU_UPDATE_NOW that would run a command: the clock instead, nothing run"
for c in curl "$W/a b/curl" './curl' '/tmp/$(touch '"$W"'/ran7)'; do
  fresh; stamp release v0.1.0; answer 200 "$W/cl"
  same "$(AU_CURL=$c upd --refresh | cut -f5):$(asks):$(ls -A "$U" | tr '\n' ' '):$([ -e "$W/ran7" ] && echo ran || echo none)" "failed:0:scripts :none" \
    "AU_CURL [$c]: nothing fetched, nothing written, nothing run"
done

# --- a folder others can write, and an older answer
fresh; stamp release v0.1.0; answer 200 "$W/cl"; chmod 770 "$U"
same "$(upd --refresh | cut -f5):$(asks):$(ls -A "$U" | tr '\n' ' ')" "failed:0:scripts " "an _update the group can write: failed, nothing fetched, nothing written"
chmod 700 "$U"
fresh; stamp release v0.1.0; offer v0.4.0; echo "notes of 0.4.0" > "$U/notes.md"; answer 200 "$W/cl"
o=$(sum "$U/offer"); n=$(sum "$U/notes.md")
same "$(upd --refresh | cut -f3,5):$(sum "$U/offer"):$(sum "$U/notes.md"):$(leftovers)" "v0.4.0${TAB}fetched:$o:$n:0" \
  "an answer older than the offer (a copy up to five minutes old): the offer and notes.md as they were"

# --- the programs it runs are the system's, whatever comes first on PATH
mkdir -p "$W/pathbin"
for p in mktemp stat date mv head cp find; do
  printf '#!/bin/bash\necho %s >> %q\nexec /usr/bin/false\n' "$p" "$W/pathcalls" > "$W/pathbin/$p"; chmod +x "$W/pathbin/$p"
done
fresh; stamp release v0.1.0; tried 1; answer 200 "$W/cl"; : > "$W/pathcalls"
same "$(PATH="$W/pathbin:$PATH" AT=notatime upd --refresh | cut -f1,5):$(wc -l < "$W/pathcalls" | tr -d ' ')" "ready${TAB}fetched:0" \
  "stubs named mktemp, stat, date, mv, head, cp and find first on PATH: the check still works, and none ran"
same "$(PATH="$W/pathbin:$PATH" upd --noted):$(wc -l < "$W/pathcalls" | tr -d ' ')" "v0.2.0:0" "  ...--noted too"
done_
