# T143 (the conventions' audit, its second pass, 2026-11-28; docs/conventions.md section 2, "Fixed sentences"; B3 step 13,
# B6): when the server check is not answered, its reason says the engine job's last start in a fixed sentence for each code
# au_start_read matches, the code after it in parentheses and never alone (as `auster status` says it, T142). `auster
# restart`, the stub launchctl starting the engine job's real program, meets each code in turn: this Mac behind another
# router (not-home), with no default route (no-network), the engine's key file emptied (keys), the stub engine never
# listening (starting), and the template changed in store/ (engine-hash). Each run exits 4 and names `auster status`.
# Mutants: tests/mutants/T143a (each code said alone, as before), T143b (the sentence for keys without its code), T143c
# (no sentence for engine-hash).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
engine_up
kf="$DATA/keys/engine.keys"
T=$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f5)   # the template

why() { # CODE WORDS LABEL -> the check of the `auster restart` just run was not answered, for the reason WORDS (CODE)
  same "$RC" 4 "$3: auster restart, its check not answered: exit 4"
  outsays "The server did not answer its check within 3 s: $2 ($1)." "  ...it says why in a sentence, the code after it"
  outsays "\`auster status\` says how the engine's last start went." "  ...and names auster status"
  grep -qE "last start says|: $1\.\$" "$W/out" && bad "  ...the code alone" || ok "  ...never the code alone"
}

STUB_NET_ROUTER_MAC=0:0:5e:0:53:2 AU_SERVER_CHECK_SECS=3 auster restart
why not-home "this Mac is not on the home network Auster was installed on, so the engine job did not start the engine" "behind another router"

STUB_NET_IF= AU_SERVER_CHECK_SECS=3 auster restart
why no-network "this Mac had no network connection, so the engine job did not start the engine" "no default route"

cp -p "$kf" "$W/engine.keys"; : > "$kf"
AU_SERVER_CHECK_SECS=3 auster restart
why keys "the engine's key file (keys/engine.keys) holds no key it can use, so the engine job did not start the engine" "the key file emptied"
cat "$W/engine.keys" > "$kf"

engine_set 'port=8484' behaviour nolisten
AU_SERVER_CHECK_SECS=3 auster restart
why starting "the engine job started the engine, but the engine did not answer the recipe's question" "an engine that never listens"
engine_set 'port=8484' behaviour ok

chmod 644 "$DATA/store/$T"; printf '{# one more line #}\n' >> "$DATA/store/$T"
AU_SERVER_CHECK_SECS=3 auster restart
why engine-hash "a check the engine job makes at every start failed, so it did not start the engine" "the template changed"
done_
