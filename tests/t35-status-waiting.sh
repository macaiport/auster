# T35, `auster status`'s half (U3; B6, D3.3, D3.5): status prints the word for the Mac and each recipe's line, from
# the deployed rule file's --recipes. On an installed Mac serving order 2, with the scripts, the offer and the
# registry all of v0.1.0 and order 1 fitting this Mac: the update check's sentence says an update is waiting
# though no newer version is out, and the recipe's line names the recipe by its label, the build it serves and
# the one waiting (by id and model file), the download (only what store/ does not hold: model A, 3,400 bytes), and
# that this Mac can run it, for how many people, at what context and with how much memory. A person who does not
# update leaves it waiting: after `auster update` (U4's; it changes nothing here) and after another check that
# finds the same version, status still shows it, and --noted names nothing (D3.3: no notification for a build
# that waits for a reason on the Mac). With a newer version, the version and its date are named. A build that no
# longer waits says `the same`; a hold that cannot be read, passed over (held); a build served that is withdrawn,
# with nothing else offered, withdrawn. Mutant: tests/mutants/T35a (call a Mac current when its scripts are).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
cmd_install
U="$DATA/_update"
same "$(sed -n 2p "$DATA/builds/$IR/serving" | cut -f2)" "$IB1" "the install serves order 1 on this 64 GB Mac"
cp "$FX/registry.tsv" "$U/registry"; printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
serving_put "$IB2" "$IMB" 4 32768 36.9
rm -f "$DATA/store/$SA"   # model A, which order 1 needs: the only file the update would fetch
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" | cut -f1-3)" "ready${TAB:=	}v0.1.0${TAB}v0.1.0" "serving order 2, all of v0.1.0: the rule file says ready"

waiting() { # LABEL
  outsays "Auster v0.1.0 is the newest version at the last update check, and an update is waiting for this Mac (below)." "$1: an update is waiting, though no newer version is out"
  outsays "The recipe household: waiting. An update would move it from build $IB2 to build $IB1 (standin-a.gguf), in Auster v0.1.0" "$1: which recipe, from which build to which"
  outsays "It would download 3,400 bytes that this Mac does not hold yet." "$1: the download, only what store/ does not hold"
  outsays "This Mac can run it: 4 people at a time, each with a context of 32,768 tokens, holding 44.6 GB of memory, 44.1 GB of it on the GPU." \
    "$1: that this Mac can run it, in its figures"
}
auster status; same "$RC" 0 "status: exit 0"
waiting "status"
none_of() { if grep -qF -- "$1" "$W/out"; then bad "$2: $(cat "$W/out")"; else ok "$2"; fi; }
none_of "is released; this Mac has" "  ...and no newer version is said to be out"

auster update; same "$RC" 3 "auster update (U4's) changes nothing here: exit 3"
auster status; waiting "after auster update did nothing"

route_drop "$CHANGELOG"; route_drop "$REGISTRY"
printf '# Changelog\n\n## v0.1.0 (2026-11-27)\n\nFirst.\n' > "$FX/changelog-1.md"
curl_route GET "$CHANGELOG" 200 "$FX/changelog-1.md"; curl_route GET "$REGISTRY" 200 "$FX/registry.tsv"
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" --refresh --now | cut -f1,5)" "ready${TAB}fetched" "another check, of the same version: ready"
same "$(AU_UPDATE_DIR=$U /bin/bash "$U/updates.sh" --noted)" "" "  ...and --noted names nothing: no new version to tell of"
auster status; waiting "after another check"

# A newer version: its number and date
install_registry "$U/registry" v0.2.0; printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$U/offer"
printf '# Changelog\n\n## v0.2.0 (2026-12-01)\n\nTwo.\n\n## v0.1.0 (2026-11-27)\n\nFirst.\n' > "$U/notes.md"
auster status
outsays "Auster v0.2.0 is released; this Mac has v0.1.0." "a newer version: the two versions"
outsays "The recipe household: waiting. An update would move it from build $IB2 to build $IB1 (standin-a.gguf), in Auster v0.2.0 of 2026-12-01." \
  "  ...and the version that brings the build waiting, with its date"

# The same; passed over; withdrawn
cp "$FX/registry.tsv" "$U/registry"; printf 'auster-record 1\tv0.1.0\t1799990000\n' > "$U/offer"
printf 'auster-record 1\n%s\n' "$IB1" > "$DATA/builds/$IR/hold"
auster status
outsays "Auster v0.1.0 is the newest version at the last update check." "order 1 held: current"
outsays "The recipe household: the same, serving build $IB2, the build for this Mac." "  ...the recipe the same"
none_of "an update is waiting" "  ...and nothing waiting"
rm -f "$DATA/builds/$IR/hold"; mkdir "$DATA/builds/$IR/hold"
auster status; outsays "The recipe household: passed over (held). No update is offered for it." "a hold that cannot be read: passed over (held)"
rmdir "$DATA/builds/$IR/hold"; printf 'auster-record 1\n%s\n' "$IB1" > "$DATA/builds/$IR/hold"
{ cat "$FX/registry.tsv"; printf 'withdraw\t%s\tquality\n' "$IB2"; } > "$U/registry"
auster status
outsays "The recipe household: withdrawn. The build it serves, $IB2, has been withdrawn, and no other build is offered for this Mac; it keeps serving." \
  "the build served withdrawn, order 1 held: withdrawn"
rm -f "$DATA/builds/$IR/hold"
auster status
outsays "The recipe household: waiting. An update would move it from build $IB2 to build $IB1" "  ...with order 1 free again: waiting"
outsays "The build it serves, $IB2, has been withdrawn." "  ...and status adds that the build it serves is withdrawn (A3)"
done_
