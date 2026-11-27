# T97, the installer's half (V5): an engine archive holding a link that points outside it (by .. or by an
# absolute target), an absolute name, a .. name, or a setuid bit is refused when it is unpacked (B3 step 9;
# step 4 unpacks the same way to measure the Mac): exit 1, the question never reached, nothing left in
# the home folder or in TMPDIR, and nothing made outside. The engine job's half (a changed file stops a
# start with engine-hash, and mutant (b)) is V6's. Mutant: tests/mutants/T97a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir "$W/tmp"
cp -R "$FX/engine-src" "$W/good-src"
before=$(snapshot "$H")

evil() { # LABEL SAYS -> the archive now in $FX/engine.tar.gz named by the registry and refused
  install_registry "$FX/registry.tsv"
  install_tree "$FX/registry.tsv"
  TMPDIR="$W/tmp/" run_install $'no\nyes\nipad\n' "$IR"
  same "$RC" 1 "$1: exit 1"
  says "$2" "$1: says why"
  grep -q 'Auster is ready to install' "$W/out" && bad "$1: it went on to the question" || ok "$1: refused before the question"
  same "$(snapshot "$H")" "$before" "$1: nothing left in the home folder"
  same "$(ls -A "$W/tmp")" "" "$1: nothing left in TMPDIR"
  same "$(find "$W" -name escape -o -name 'abs-*' | grep -v "^$W/abs/" | head -n 1)" "" "$1: nothing made outside"
}
fresh() { rm -rf "$W/e"; cp -R "$W/good-src" "$W/e"; }

fresh; ln -s ../../escape "$W/e/llama-stub/libevil.dylib"
(cd "$W/e" && tar -czf "$FX/engine.tar.gz" llama-stub)
evil "a link out by .." "The engine archive holds a link that points outside it, so it is refused."

fresh; ln -s /etc/hosts "$W/e/llama-stub/libhosts.dylib"
(cd "$W/e" && tar -czf "$FX/engine.tar.gz" llama-stub)
evil "a link to an absolute path" "The engine archive holds a link that points outside it, so it is refused."

fresh; mkdir -p "$W/abs"; printf 'x\n' > "$W/abs/abs-file"
(cd "$W/e" && tar -cPzf "$FX/engine.tar.gz" llama-stub "$W/abs/abs-file")
case "$(tar -tzf "$FX/engine.tar.gz" | tail -n 1)" in /*) ok "the fixture holds an absolute name" ;; *) bad "the fixture: $(tar -tzf "$FX/engine.tar.gz")" ;; esac
evil "an absolute name" "The engine archive holds an absolute name, so it is refused."

fresh
(cd "$W/e" && tar -czf "$FX/engine.tar.gz" -s ',^llama-stub/libstub\.0\.dylib$,llama-stub/../../escape,' llama-stub)
grep -qx 'llama-stub/../../escape' <(tar -tzf "$FX/engine.tar.gz") && ok "the fixture holds a .. name" || bad "the fixture: $(tar -tzf "$FX/engine.tar.gz")"
evil "a .. name" "The engine archive holds a name with .. in it, so it is refused."

fresh; chmod 4755 "$W/e/llama-stub/llama-server"
(cd "$W/e" && tar -czf "$FX/engine.tar.gz" llama-stub)
case "$(tar -tvzf "$FX/engine.tar.gz" | grep 'llama-server$')" in -rws*) ok "the fixture holds a setuid program" ;; *) bad "the fixture: no setuid" ;; esac
evil "a setuid bit" "The engine archive holds a program with its setuid or setgid bit, so it is refused."

# The good archive still goes through, so that the refusals above are the archives' own
(cd "$W/good-src" && tar -czf "$FX/engine.tar.gz" llama-stub)
install_registry "$FX/registry.tsv"; install_tree "$FX/registry.tsv"
run_install $'no\nno\n' "$IR"
says "Auster is ready to install household on this Mac." "the good archive: unpacked, and the run reaches the question"
done_
