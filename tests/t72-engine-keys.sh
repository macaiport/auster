# T72: the key-file guard (B4 step 3, B7). keys/engine.keys empty, of blank lines, of a comment only, a link, of
# mode 0644, with a line that is not a key, with a key and a trailing space, with no final newline, or with 65
# keys: the engine is not started and `start` says keys. The engine takes an empty file, or one of blank or
# comment lines, as no key at all (docs/phase-1.md, step 12). A file as the install wrote it starts it, and
# the engine reads its keys. The clause "revoking the last device leaves Auster's own key" and mutant (b),
# writing the key file in place, are `auster key revoke`'s, which V7 builds. Mutant: tests/mutants/T72a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
kf="$DATA/keys/engine.keys"

guard() { # LABEL: the key file as the case left it
  engine_job; engine_wait
  same "$EJ_CODE" keys "$1: start says keys"
  same "$(starts)" "$NSTARTS" "$1: no engine started"
  engine_job_end
  job_reset
}
: > "$kf"; guard "an empty file"
printf '\n\n' > "$kf"; guard "blank lines"
printf '# no key here\n' > "$kf"; guard "a comment only"
cp "$kf" "$W/keys-elsewhere"; rm "$kf"; ln -s "$W/keys-elsewhere" "$kf"; guard "a link to a good key file"
chmod 644 "$kf"; guard "mode 0644"
printf 'not a key\n' >> "$kf"; guard "a line that is not a key"
sed 's/$/ /' "$kf" > "$W/k" && cat "$W/k" > "$kf"; guard "a key with a trailing space"
printf '%s' "$(cat "$kf")" > "$W/k" && cat "$W/k" > "$kf"; guard "no final newline"
for i in $(seq 65); do printf '%032x\n' "$i"; done > "$W/k" && cat "$W/k" > "$kf"; guard "65 keys"

engine_job; engine_wait
same "$EJ_CODE" starting "the key file as the install wrote it: start says starting"
if [ -n "$EJ_START" ]; then
  same "$(cat "$EJ_START/keys")" "$(cat "$kf")" "the engine read every key in it"
  same "$(wc -l < "$EJ_START/keys" | tr -d ' ')" 2 "the device's key and Auster's own"
else
  bad "no engine started: $(tail -n 3 "$W/engine-job.out")"
fi
engine_job_end
done_
