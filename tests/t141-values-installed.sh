# T141 (the conventions' audit, 2026-11-28; docs/conventions.md section 2, "Fixed sentences": never what a program printed,
# and a value only after it matches its pattern): on a Mac that serves, `auster` matches what the rule file and macOS give
# before a sentence names it.
#   - The rule file's version: a stand-in _update/updates.sh whose state line names a version in no form (v0.1.0x), as
#     `manual` from a tag and as `current`: `update` and `status` say their sentences without it.
#   - The rule file's own sentences: with the real rule file and an update waiting, AU_OPEN that is no plain path (at the
#     screen), AU_CURL that is none (over SSH) and a TMPDIR that does not exist (with a newer version offered, since a
#     build waiting is judged in a folder of TMPDIR) each stop the update with bin/auster's own sentence for the code the
#     rule file gives, never the rule file's sentence; a stand-in rule file of the older form, a sentence and no code, has
#     its sentence left unsaid.
#   - macOS's version on an update (au_update_ask, the driver run directly as install.sh runs it, since install.sh refuses
#     such a version first): the recipe is passed over in fixed words, the version not printed.
#   - The account's short name: `auster status` refuses a name macOS does not give, without printing it.
# Mutants: tests/mutants/T141a (the named version printed unmatched by `update`), T141b (the rule file's sentence printed
# again), T141c (the update's macOS version printed unmatched), T141d (`current`'s version printed unmatched), T141e (the
# named version printed unmatched by `status`).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
. "$TESTS/update-run-helpers.sh"
update_install
waiting_b1
RULES="$DATA/_update/updates.sh"
cp "$RULES" "$W/updates.sh"

# --- the rule file's version, in no form Auster reads
printf '#!/bin/bash\nprintf "manual\\tv0.1.0x\\t-\\ttag\\n"\n' > "$RULES"
auster update
same "$RC" 1 "a tag whose version is in no form: update refused, exit 1"
outsays "Auster was installed as a named version, which is never offered an update, so nothing was changed." "  ...it says so without the version"
grep -q 'v0.1.0x' "$W/out" && bad "  ...it prints the version" || ok "  ...and never prints it"
auster status
outsays "Update checks are not made: Auster was installed as a named version, which is never offered an update." "status: it says so without the version"
grep -q 'v0.1.0x' "$W/out" && bad "  ...it prints the version" || ok "  ...and never prints it"
printf '#!/bin/bash\nprintf "current\\tv0.1.0x\\tv0.1.0x\\t-\\n"\n' > "$RULES"
auster update
same "$RC" 1 "current, its version in no form: update refused, exit 1"
outsays "Nothing is waiting: this version of Auster is the newest at the last update check" "  ...it says so without the version"
grep -q 'v0.1.0x' "$W/out" && bad "  ...it prints the version" || ok "  ...and never prints it"

# --- the rule file's own sentences: a code, said in bin/auster's words
cp "$W/updates.sh" "$RULES"
AU_OPEN=relative/open auster update
same "$RC" 1 "AU_OPEN no plain path: update refused, exit 1"
outsays "AU_OPEN is not a plain absolute path, so Terminal was not opened." "  ...in bin/auster's words for open-path"
grep -q 'Terminal was not opened: AU_OPEN' "$W/out" && bad "  ...it prints the rule file's sentence" || ok "  ...not the rule file's sentence"
AU_CURL=relative/curl SSH_CONNECTION='10.0.0.9 50111 10.0.0.5 22' auster update
same "$RC" 1 "over SSH, AU_CURL no plain path: update refused, exit 1"
outsays "AU_CURL is not a plain absolute path, so the update's file was not written." "  ...in bin/auster's words for curl-path"
grep -q "The update's file was not written: AU_CURL" "$W/out" && bad "  ...it prints the rule file's sentence" || ok "  ...not the rule file's sentence"
cp "$DATA/_update/offer" "$W/offer"
printf 'auster-record 1\tv0.2.0\t1799990000\n' > "$DATA/_update/offer"   # ready by the versions alone, which need no folder
TMPDIR="$W/no-such-folder/" auster update
same "$RC" 1 "no folder for the update's file: update refused, exit 1"
outsays "A folder for the update's file could not be made in the temporary folder." "  ...in bin/auster's words for no-folder"
grep -q 'Paste the installer line from the guide instead' "$W/out" && bad "  ...it prints the rule file's sentence" || ok "  ...not the rule file's sentence"
cp "$W/offer" "$DATA/_update/offer"
printf '#!/bin/bash\ncase "${1:-}" in --open|--command) printf "failed\\tA sentence of the rule file.\\n" ;; *) printf "ready\\tv0.1.0\\tv0.1.0\\t-\\n" ;; esac\n' > "$RULES"
auster update
same "$RC" 1 "a rule file of the older form, a sentence and no code: exit 1"
grep -q 'A sentence of the rule file' "$W/out" && bad "  ...it prints the rule file's sentence" || ok "  ...its sentence is left unsaid"
outsays "The update could not be started, so nothing was changed." "  ...and bin/auster says the update did not start"
cp "$W/updates.sh" "$RULES"

# --- macOS's version on an update: the driver run from the tree as install.sh runs it
printf '' > "$W/answers"
HOME="$H" AU_TTY="$W/answers" STUB_MACOS='ninety-nine' /bin/bash "$FX/tree-src-$COMMIT/common/driver.sh" update \
  --commit "$COMMIT" --line release --version v0.1.0 > "$W/out" 2>&1
RC=$?
same "$RC" 3 "an update, sw_vers in no form Auster reads: the recipe passed over, exit 3"
says "Build $IB1 needs an engine that runs on macOS 14 or later, and this Mac has a version of macOS that cannot be read." "  ...it says so in fixed words"
grep -q 'ninety' "$W/out" && bad "  ...it prints what sw_vers gave" || ok "  ...and never prints what sw_vers gave"

# --- the account's short name, in bin/auster
STUB_USER='o brien;x' auster status
same "$RC" 1 "status, a short name macOS does not give: exit 1"
outsays "Auster cannot tell which account it runs as." "  ...it says so"
grep -q 'brien' "$W/out" && bad "  ...it prints the name" || ok "  ...and never prints the name"
done_
