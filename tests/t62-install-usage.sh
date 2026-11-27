# T62: usage errors exit 2 and fetch nothing: no argument, the recipe's label instead of its id, r$(touch f),
# a malformed id, a word too many, and --check without an id. A well-formed id that the registry does not
# hold: exit 1, after the tree is fetched, and nothing written (B2, B3). Mutants: tests/mutants/T62a, T62b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir "$W/cwd"; cd "$W/cwd" || exit 1
before=$(snapshot "$H")

usage() { # LABEL -> after the run: exit 2, the usage, nothing fetched, nothing written, no file f
  same "$RC" 2 "$1: exit 2"
  says "usage: install.sh <recipe id>" "$1: prints the usage"
  same "$(requests)" "" "$1: nothing fetched"
  same "$(snapshot "$H")" "$before" "$1: the home folder as it was"
  same "$(ls -A "$W/cwd")" "" "$1: no file made where it ran"
}
run_install ''; usage "no argument"
run_install '' household; usage "the label instead of the id"
says "must be a recipe id" "the label: says a recipe id is wanted"
run_install '' 'r$(touch f)'; usage 'r$(touch f)'
run_install '' rylaqjysaozx; usage "an id one character short"
run_install '' RYLAQJYSAOZX5; usage "an id in capitals"
run_install '' rylaqjysaozx1; usage "an id with a digit base32 has not"
run_install '' "$IR" extra; usage "a word too many"
run_install '' --check; usage "--check without an id"
run_install '' update now; usage "update with a word after it"

run_install '' raaaaaaaaaaaa
same "$RC" 1 "a well-formed id the registry does not hold: exit 1"
says "This version of Auster has no recipe raaaaaaaaaaaa." "it says the version has no such recipe"
same "$(requests | sed 's/ .*//' | sort -u)" GET "only GETs were sent"
same "$(requests | cut -d' ' -f2 | sed 's|/[^/]*$||' | sort -u | tr '\n' ' ')" "$API/heads $CODELOAD " "and only to GitHub's API and the tree"
same "$(snapshot "$H")" "$before" "it wrote nothing in the home folder"
done_
