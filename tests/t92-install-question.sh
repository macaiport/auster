# T92, the question's half (V5; section C's half is t92-capability-first-disk.sh): at a first install,
# when order 1 fits in memory but not on disk, the question offers order 2 and says how much space order 1
# would need; with too little disk for any build the install refuses, in this Mac's figures, and nothing
# is fetched from the model's host (the engine that measures the Mac comes before the rule: B3 step 4).
# Mutants: tests/mutants/T92c and T92d.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
E=$(stat -f %z "$FX/engine.tar.gz")
V=1000000000000 FLOOR=50000000000          # a 1 TB volume: 5% is 50 GB, above 20 GiB
commas() { local n=$1 o=; while [ ${#n} -gt 3 ]; do o=",${n: -3}$o"; n=${n:0:${#n}-3}; done; printf '%s' "$n$o"; }
before=$(snapshot "$H")

AU_DISK_TOTAL_BYTES=$V AU_DISK_FREE_BYTES=$((FLOOR + 2040 + E + 100)) run_install $'no\nno\n' "$IR"
same "$RC" 1 "room for order 2 only: exit 1 at the no"
says "  Download    standin-b.gguf from Hugging Face ($REPO_B)" "the question offers order 2"
says "  Room        The first choice for this Mac, standin-a.gguf, would need 50.0 GB free (a download of $(commas $((3400 + E))) bytes);" \
  "and says how much space order 1 would need: its free space and its download"
says "this Mac has 50.0 GB free, so the next build that fits is offered." "and how much this Mac has"
same "$(requests huggingface.co)" "" "nothing asked of the model's host before the yes"
same "$(snapshot "$H")" "$before" "a no leaves nothing"

AU_DISK_TOTAL_BYTES=$V AU_DISK_FREE_BYTES=$((FLOOR + 100)) run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 1 "room for no build: exit 1"
says "There is not room on this Mac's disk: it has 50.0 GB free" "it refuses in this Mac's figures"
says "Nothing was fetched." "and says nothing was fetched"
grep -q 'Auster is ready to install' "$W/out" && bad "room for no build: it asked the question" || ok "room for no build: no question"
same "$(requests huggingface.co)$(requests cdn.example.test)" "" "nothing fetched from the model's host"
same "$(snapshot "$H")" "$before" "and nothing left"
done_
