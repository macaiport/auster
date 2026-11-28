# T140 (the conventions' audit, 2026-11-28; docs/conventions.md section 2, "Fixed sentences": a value goes into a sentence
# only after it matches its pattern): before an install, three values the driver names are matched first. An account's
# short name that is not one macOS gives (`id -un` answering "o brien;x", the stub id's STUB_USER): the install refuses,
# saying it cannot tell which account it runs as, and never prints the name. A macOS version sw_vers gives in no form
# Auster reads, the driver run directly from the fetched tree (install.sh refuses such a version first, at B3 step 1):
# refused at step 4 in fixed words, the version not printed, and nothing left. A folder in builds/ whose name is no recipe
# id, holding a `serving`: no recipe is served there (BD14 refuses only for a recipe id), so the install goes on to its
# question, and the folder's name is never printed.
# Mutants: tests/mutants/T140a (the short name unmatched), T140b (sw_vers's version unmatched at step 4), T140c (any
# folder in builds/ taken for a recipe, its name printed).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
before=$(snapshot "$H")

# --- the account's short name
STUB_USER='o brien;x' run_install $'no\nno\n' "$IR"
same "$RC" 1 "a short name macOS does not give: exit 1"
says "Auster cannot tell which account it runs as." "  ...it says so"
grep -q 'brien' "$W/out" && bad "  ...it prints the name" || ok "  ...and never prints the name"
same "$(snapshot "$H")" "$before" "  ...nothing left in the home folder"

# --- macOS's version, at step 4 (the driver run from the tree as install.sh runs it)
printf '' > "$W/answers"
HOME="$H" AU_TTY="$W/answers" STUB_MACOS='ninety-nine' /bin/bash "$FX/tree-src-$COMMIT/common/driver.sh" install "$IR" \
  --commit "$COMMIT" --line release --version v0.1.0 > "$W/out" 2>&1
RC=$?
same "$RC" 1 "sw_vers in no form Auster reads, at step 4: exit 1"
says "Auster cannot tell which version of macOS this Mac has, so nothing was installed." "  ...it says so in fixed words"
grep -q 'ninety' "$W/out" && bad "  ...it prints what sw_vers gave" || ok "  ...and never prints what sw_vers gave"
same "$(snapshot "$H")" "$before" "  ...nothing left in the home folder"

# --- a folder in builds/ whose name is no recipe id
mkdir -m 700 "$DATA" "$DATA/builds" "$DATA/builds/rnot-a-recipe"
: > "$DATA/.auster-data-root"
printf 'not a descriptor\n' > "$DATA/builds/rnot-a-recipe/serving"
run_install $'no\nno\n' "$IR"
same "$RC" 1 "a folder in builds/ that is no recipe's, the question answered no: exit 1"
says "Auster is ready to install household on this Mac." "  ...it serves no recipe, so the install goes on to the question"
grep -q 'already serves another recipe' "$W/out" && bad "  ...it refused for another recipe" || ok "  ...and does not refuse for another recipe"
grep -q 'not-a-recipe' "$W/out" && bad "  ...it prints the folder's name" || ok "  ...and never prints the folder's name"
done_
