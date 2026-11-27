# T67: the question (B3 step 6). A no: exit 1, nothing asked of the model's host, no job touched, and the
# home folder as it was before the run (the data root this run made is gone). A smaller number of people
# chooses again and asks again. A yes: the question named the download's size and roughly how long it
# takes, the memory, the people and their context, the address, the home network, plain HTTP, the account,
# the sleep setting and the firewall, and on a laptop the lid. Mutants: tests/mutants/T67a and T67b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
before=$(snapshot "$H")

STUB_BATTERY=1 STUB_FIREWALL=1 STUB_PMSET_SLEEP=10 run_install $'yes\n2\nno\n' "$IR"
same "$RC" 1 "a no: exit 1"
says "Nothing was installed, and nothing of this run is left." "a no: it says nothing is left"
same "$(requests huggingface.co)$(requests cdn.example.test)" "" "a no: nothing asked of the model's host"
same "$(requests | cut -d' ' -f2 | tr '\n' ' ')" "$API/heads/release $CODELOAD/$COMMIT $ENGINE_URL $ENGINE_CDN " \
  "a no: only the commit, the tree and the engine that measures the Mac were fetched"
same "$(grep -c '^launchctl' "$STUB_LOG")" 0 "a no: no job touched"
same "$(snapshot "$H")" "$before" "a no: the home folder as it was before the run"
says "  Laptop      This Mac has a battery: with its lid closed it sleeps, whatever Auster does" "on a laptop: the lid"
says "  Firewall    on." "the firewall on"
says "This Mac sleeps after 10 minutes idle" "the sleep setting"
says "  People      2 people at a time, each with a context of 32,768 tokens." "a smaller number: chosen again for 2 people"
says "Install for 2 people? Type yes, another number of people (1 to 4), or no:" "and asked again"

: > "$STUB_LOG"; rm -rf "$STUB_CURL_DIR/requests"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "a yes: installed"
says "  Download    standin-a.gguf from Hugging Face ($REPO_A): 3,400 bytes in all." "the question named the download and its size"
says "At the speed this Mac fetched the engine, that takes under a minute." "roughly how long it takes"
says "The engine will hold 44.6 GB of this Mac's 64.0 GB of memory, 44.1 GB of it on the GPU." "the memory"
says "  People      4 people at a time, each with a context of 32,768 tokens." "the people and their context"
says "  Address     http://test-mac.local:8484/ and http://10.0.0.5:8484/, on the home network" "the address"
says "whose router is 00:00:5e:00:53:01. It listens nowhere else: not on another network, not through a VPN." "the home network"
says "  Plain HTTP  Anyone on that Wi-Fi who sets out to can read what is sent, the devices' keys included." "plain HTTP"
says "  Account     The engine runs as tester, with that account's files, and with no sandbox." "the account"
says "  Sleep       This Mac sleeps after 1 minute idle, and a sleeping Mac does not answer." "the sleep setting"
says "  Firewall    off." "the firewall"
says "Keep this Mac awake while the engine runs and while it downloads? [yes/no]" "whether Auster may keep the Mac awake"
grep -q 'Laptop' "$W/out" && bad "no battery, and a line about the lid" || ok "no battery: no line about the lid"
q=$(grep -bo 'Install for 4 people' "$W/out" | head -n 1 | cut -d: -f1)
f=$(grep -bo 'Fetching standin-a.gguf' "$W/out" | head -n 1 | cut -d: -f1)
[ -n "$q" ] && [ -n "$f" ] && [ "$f" -gt "$q" ] && ok "the model is fetched after the question" || bad "the question at byte $q, the fetch at $f"
done_
