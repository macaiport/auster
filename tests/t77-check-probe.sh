# T77: the check job's probe on 127.0.0.1 (B5 step 2), and its notifications (step 6). Against this Mac's own
# baseline in serving (20 tok/s here): an answer at half of it gives ok, below half slow. With the engine
# answering HTTP 500 and /health 200: broken, notified at once naming `auster restart` (BD19), but only while
# the speed is not 0; while it is 0 the same answers give failed, notified at once in a sentence that names
# `auster status` with kept/ empty and `auster rollback` with an entry there, never `auster restart`. No
# listener: down. A request with no key answered: open, notified at once, and once only. No answer within the
# limit: failed, notified only on the second run in a row. The probe fails closed (B3 step 13): the request
# with no key timing out, or answering 500, is open; 401 and 403 are refused. While builds/stopped exists it
# sends nothing and records stopped. Mutants: tests/mutants/T77a to T77f.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
export AU_CHECK_LIMIT=3
CH=http://127.0.0.1:8484/v1/chat/completions
printf '{"choices":[{"message":{"role":"assistant","content":"1"}}],"timings":{"predicted_per_second":36.9}}' > "$W/answer.json"
printf '{"status":"ok"}' > "$W/health.json"

probe() { # LABEL RESULT [SPEED] -> the check job run once; its probe gave RESULT (and SPEED)
  check_job
  same "$(probe_field probe 1)" "$2" "$1: the probe gives $2"
  [ -z "${3:-}" ] || same "$(probe_field probe 2)" "$3" "$1: at $3"
}
told() { # LABEL N [SENTENCE-PART] -> the stub notifier has had N notifications, the last holding SENTENCE-PART
  same "$(notes)" "$2" "$1: $2 notifications so far"
  [ -z "${3:-}" ] || case "$(last_note)" in *"$3"*) ok "$1: the notification names $3" ;; *) bad "$1: the notification: $(last_note)" ;; esac
}
fresh() { rm -f "$DATA/_update/engine"; : > "$STUB_NOTIFY_LOG"; }

engine_job; engine_wait
same "$EJ_CODE" starting "the engine runs"
speed_set 20
engine_live 8484 answers ''
engine_live 8484 rate 10
probe "half the baseline" ok 10
told "half the baseline" 0
engine_live 8484 rate 9.9
probe "below half the baseline" slow 9.9
told "slow" 0

engine_live 8484 rate 36.9
engine_live 8484 behaviour http500
fresh; probe "HTTP 500 with /health 200" broken
told "broken" 1 "auster restart"
probe "broken again" broken
told "broken again" 1

speed_set 0
fresh; probe "HTTP 500 while the speed is 0" failed
told "failed while the speed is 0, kept/ empty" 1 "auster status"
case "$(last_note)" in *restart*) bad "the speed-0 sentence names auster restart" ;; *) ok "the speed-0 sentence does not name auster restart" ;; esac
cp "$DATA/builds/$IR/serving" "$DATA/builds/$IR/kept/2026-11-26T00:00:00Z-$IB2"
fresh; probe "HTTP 500 while the speed is 0, an entry in kept/" failed
told "failed while the speed is 0, kept/ not empty" 1 "auster rollback"
rm -f "$DATA/builds/$IR/kept"/*
speed_set 20

engine_live 8484 behaviour ok
engine_live 8484 open 1
fresh; probe "a request with no key answered" open
told "open" 1 "did not refuse a request that carried no key"
probe "open again" open
told "open again" 1
engine_live 8484 open 0
probe "refused again" ok
told "refused again" 1

touch "$DATA/builds/stopped"
n=$(ls "$STUB_CURL_DIR/requests" | wc -l | tr -d ' ')
fresh; probe "builds/stopped" stopped
same "$(ls "$STUB_CURL_DIR/requests" | wc -l | tr -d ' ')" "$n" "builds/stopped: no request sent"
told "builds/stopped" 0
printf 'not a record' > "$DATA/builds/stopped"; probe "builds/stopped unreadable" stopped
rm -f "$DATA/builds/stopped"

engine_job_end
fresh; probe "no listener" down
told "down once" 0
probe "no listener, the second run" down
told "down twice" 1 "auster status"

# No engine: the stub curl answers 127.0.0.1:8484 from routes. A,B,... are the answers to the POSTs in turn:
# each run sends the question with Auster's key, then the request with no key.
routes() { rm -f "$STUB_CURL_DIR"/.count-*; route_drop "$CH"; route_drop http://127.0.0.1:8484/health
  curl_route GET http://127.0.0.1:8484/health 200 "$W/health.json"; curl_route POST "$CH" "$1" "$W/answer.json"; }
routes 'sleep:30,401,sleep:30,401'
fresh; probe "no answer within the limit" failed
told "no answer, once" 0
probe "no answer, the second run" failed
told "no answer, twice" 1 "twice in a row"
last=$(ls -d "$STUB_CURL_DIR"/requests/* | tail -n 1)
grep -qi '^authorization:' "$last/headers" && bad "the request with no key carried a key" || ok "the last request carried no key"
same "$(plutil -extract max_tokens raw -o - "$last/body")" 1 "the request with no key asks for one token"
grep -qF "Bearer $(cat "$DATA/keys/probe")" "$(ls -d "$STUB_CURL_DIR"/requests/* | tail -n 2 | head -n 1)/headers" &&
  ok "the question before it carried Auster's own key" || bad "the question carried no probe key"

routes '200,sleep:30'
fresh; probe "the request with no key times out" open
told "a time-out is open" 1 "did not refuse"
routes '200,500'
fresh; probe "the request with no key answers 500" open
routes '200,200'
fresh; probe "the request with no key answers 200" open
routes '200,401'
fresh; probe "the request with no key answers 401" ok 36.9
routes '200,403'
fresh; probe "the request with no key answers 403" ok 36.9
done_
