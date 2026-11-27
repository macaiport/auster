# T102, the installer's half (V5; section C's half is t102-capability-list-devices.sh): step 4 runs the
# engine's --list-devices (B3 step 4). With b12359's real output the GPU limit, 53,084 MiB, is the one
# kept in builds/mac after the yes; with the altered copies (no MTL0, the columns swapped) the install
# refuses before the question, names what it could not read, and guesses no limit.
# Mutant: tests/mutants/T102b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
before=$(snapshot "$H")

for copy in no-mtl0:no-mtl0 columns-swapped:mtl0-form; do
  engine_set '*' list-devices "${copy%%:*}"
  run_install $'no\nyes\nipad\n' "$IR"
  same "$RC" 1 "${copy%%:*}: exit 1"
  says "The engine's report of this Mac's GPU (llama-server --list-devices) is not in the form Auster reads (${copy#*:}). No limit is guessed, so nothing was installed." "${copy%%:*}: it refuses, and says what it could not read"
  grep -q 'Auster is ready to install' "$W/out" && bad "${copy%%:*}: it asked the question" || ok "${copy%%:*}: no question"
  same "$(snapshot "$H")" "$before" "${copy%%:*}: nothing left"
done

engine_set '*' list-devices b12359
STUB_MEMSIZE=68719476736 run_install $'yes\nno\n' "$IR"   # keep awake, then no: nothing kept
same "$RC" 1 "b12359's output: it reaches the question"
says "44.1 GB of it on the GPU" "b12359's output: the question's figures come from it"
run_install $'no\nyes\nipad\n' "$IR"
same "$RC" 0 "b12359's output: installed"
same "$(cat "$DATA/builds/mac" | cut -f1 | tr '\n' ' ')" "auster-record 1 gpu-mib memory-bytes macos measured router keep-awake " "builds/mac has the keys of capability-lib.js's form, in order"
same "$(sed -n 's/^gpu-mib	//p; s/^memory-bytes	//p; s/^router	//p; s/^keep-awake	//p' "$DATA/builds/mac" | tr '\n' ' ')" \
  "53084 68719476736 00:00:5e:00:53:01 no " "builds/mac: the GPU limit from --list-devices, the memory, the router and the household's answer"
same "$(sed -n 's/^macos	//p' "$DATA/builds/mac")" 27.2 "builds/mac: the macOS version"
case "$(sed -n 's/^measured	//p' "$DATA/builds/mac")" in 20[0-9][0-9]-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]Z) ok "builds/mac: when it was measured, in UTC" ;; *) bad "measured: $(cat "$DATA/builds/mac")" ;; esac
done_
