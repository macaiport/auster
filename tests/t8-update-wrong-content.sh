# T8 (U5; D3.6 step 3, B3 step 7): a download of the right size and the wrong content is deleted, and the server still
# answers on the old build. On a Mac serving order 2 with order 1 waiting, the publisher's HEAD names the registry's size
# and sha256 but its CDN sends the wrong stand-in (3,400 bytes, its last byte changed): after the yes the file arrives,
# its size matches, its sha256 does not, and it is deleted. Exit 3; no model A in store/ and no part left; serving as it
# was; the engine's process the same, and it still answers a household key.
# Mutant: tests/mutants/T8a (compare the size only).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1   # serving order 2, model A not in store/
engine_up
route_drop https://cdn.example.test/a; curl_route GET https://cdn.example.test/a 200 "$FX/models/standin-a-wrong.gguf"
s0=$(cat "$DATA/builds/$IR/serving") pid=$(engine_pid)
rm -rf "$STUB_CURL_DIR/requests"
update_run $'yes\n'
same "$RC" 3 "a download of the right size and the wrong content: exit 3"
same "$(requests | grep -cE '^GET https://cdn\.example\.test/a$')" 1 "  ...the file was fetched"
says "The model that arrived is not the file the registry names (its sha256 differs), so it was deleted." "  ...it says the file was not the registry's, and was deleted"
says "The recipe household is not updated: it keeps serving build $IB2." "  ...and that the recipe keeps its build"
[ -e "$DATA/store/$SA" ] || [ -e "$DATA/store/$SA.part" ] && bad "  ...a file for model A in store/: $(ls "$DATA/store")" || ok "  ...no file for model A in store/, and no part"
same "$(cat "$DATA/builds/$IR/serving")" "$s0" "  ...serving as it was"
same "$(engine_pid)" "$pid" "  ...the engine's process the same"
same "$(ask_engine "$(key_of ipad)")" 200 "  ...and the server still answers a household key"
done_
