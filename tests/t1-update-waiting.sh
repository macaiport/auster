# T1, the half with a build waiting (U3; D3.2, D3.3): `ready` means the offered version is newer than the scripts'
# OR some recipe has a build waiting. With the scripts, the offer and _update/registry all of v0.1.0 (a check
# made), a Mac serving order 2 where order 1 fits gives `ready`, the same version on both sides of the state line,
# and its recipe's line says waiting; serving order 1 gives `current` and same. A newer version on offer with the
# recipe the same gives `ready` (the versions'), and an older or equal one with nothing waiting gives `current`.
# The check's own state line (--refresh) says the same after a fetch, and --noted, which a notification reads
# (U7), names a version only for a newer one (D3.3: a build waiting for a reason on the Mac is told by `auster
# status` alone). Mutant: tests/mutants/T1b (a build waiting does not make the word ready).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/update-helpers.sh"
update_env

fresh; known v0.1.0; mac_put 53084 $GB64; served $HH $B2 4 32768
same "$(upd)" "ready${TAB}v0.1.0${TAB}v0.1.0$TAB-" "serving order 2 where order 1 fits, scripts and offer of one version: ready"
same "$(rfield $HH 3)" waiting "  ...its recipe's line: waiting"
same "$(upd --recipes | head -n 1)" "ready${TAB}v0.1.0${TAB}v0.1.0$TAB-" "  ...--recipes's state line says the same"
same "$(upd --noted)" "" "  ...and --noted names no version: nothing new was released"
same "$([ -e "$U/noted" ] && echo noted || echo none)" none "  ...and writes no noted"

fresh; known v0.1.0; mac_put 53084 $GB64; served $HH $B1 4 32768
same "$(upd)" "current${TAB}v0.1.0${TAB}v0.1.0$TAB-" "serving order 1, the first in the order: current"
same "$(rfield $HH 3)" same "  ...its recipe's line: same"

fresh; stamp release v0.9.0; offer v0.10.0; reg_as v0.10.0 "$U/registry"; mac_put 53084 $GB64; served $HH $B1 4 32768
same "$(upd)" "ready${TAB}v0.9.0${TAB}v0.10.0$TAB-" "v0.10.0 on offer, v0.9.0 installed, the recipe the same: ready"
same "$(rfield $HH 3)" same "  ...its recipe's line: same"
fresh; stamp release v0.10.0; offer v0.9.0; reg_as v0.9.0 "$U/registry"; mac_put 53084 $GB64; served $HH $B1 4 32768
same "$(upd)" "current${TAB}v0.10.0${TAB}v0.9.0$TAB-" "v0.9.0 on offer, v0.10.0 installed, nothing waiting: current"

# The check: the state line of --refresh, after a fetch that found the same version, with a build waiting
changelog "$W/cl" v0.1.0
fresh; stamp release v0.1.0; offer v0.1.0; mac_put 53084 $GB64; served $HH $B2 4 32768; answer 200 "$W/cl"
same "$(upd --refresh)" "ready${TAB}v0.1.0${TAB}v0.1.0$TAB-${TAB}fetched" "a check that finds v0.1.0, serving order 2: ready, fetched"
same "$(rfield $HH 3):$(rfield $HH 7)" "waiting:$B1" "  ...order 1 waiting"
done_
