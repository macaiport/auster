# T71: /props and /v1/models from the stub engine, started as the engine job starts it, show no path: the
# model is named by its sha256 relative to store/, and the models list by the build id (B4 step 8, --alias),
# so neither shows /Users/, the home folder or the account's name. Mutant: tests/mutants/T71a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
engine_job; engine_wait
same "$EJ_CODE" starting "the engine job starts the engine"
key=$(cat "$DATA/keys/probe")
curl -s -o "$W/props" -H "Authorization: Bearer $key" http://127.0.0.1:8484/props
curl -s -o "$W/models" -H "Authorization: Bearer $key" http://127.0.0.1:8484/v1/models
same "$(plutil -extract model_path raw -o - "$W/props")" "$SA" "/props names the model by its sha256 alone"
same "$(plutil -extract data.0.id raw -o - "$W/models")" "$IB1" "/v1/models names it by the build id"
for f in props models; do
  for s in /Users/ "$H" "$DATA" tester; do
    if grep -qF -- "$s" "$W/$f"; then bad "$f shows $s"; else ok "$f does not show $s"; fi
  done
  if grep -q '"/' "$W/$f"; then bad "$f holds a path: $(cat "$W/$f")"; else ok "$f holds no path"; fi
done
engine_job_end
done_
