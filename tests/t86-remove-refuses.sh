# T86: removal refuses to delete what is not the data root (B8). `auster remove` and `install.sh remove` refuse
# a data root that is a link, or that lacks its marker, and the sentinel file in it survives. The deletion
# itself (au_root_delete) refuses an empty path, /, the home folder, a path through a link, and a data root whose
# marker went away between the two questions; for the first of those it is called directly, with rm replaced by
# a function that only records what it was asked, so that nothing outside the test can ever be deleted. A
# ~/.zprofile that is a link stays a link, and its target unchanged, at the install and at the removal: the line
# is printed instead. Mutant: tests/mutants/T86a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
install_env --zprofile-link
cmd_hook
line='export PATH="$HOME/Library/Application Support/Auster/bin:$PATH"   # added by Auster; auster remove removes this line'
H0=$H

refused() { # LABEL HOME: both ways of removing refuse, and what the data root's place holds is unchanged
  local before
  before=$(snapshot "$2/Library")
  printf 'yes\nyes\n' > "$W/answers"
  HOME="$2" AU_TTY="$W/answers" /bin/bash "$ROOT/common/auster" remove > "$W/out" 2>&1; RC=$?
  same "$RC" 1 "$1: auster remove refuses"
  H=$2 run_install $'yes\nyes\n' remove
  same "$RC" 1 "$1: install.sh remove refuses"
  same "$(snapshot "$2/Library")" "$before" "$1: nothing was changed"
}

# A data root that is a link: to a folder that holds the marker and a sentinel
H1=$(make_home "$W/p1" --data-root-link)
refused "a data root that is a link" "$H1"
[ -L "$H1/$DATA_REL" ] && ok "a data root that is a link: it is still a link" || bad "the link is gone"
same "$(cat "$W/p1/data-root-elsewhere/sentinel")" keep "a data root that is a link: the sentinel survives"

# A data root without its marker
H2=$(make_home "$W/p2")
mkdir -m 700 "$H2/$DATA_REL"; echo keep > "$H2/$DATA_REL/sentinel"
refused "a data root without its marker" "$H2"
same "$(cat "$H2/$DATA_REL/sentinel")" keep "a data root without its marker: the sentinel survives"

# The deletion, called directly with rm replaced: an empty path, /, the home folder, a path through a link
mkdir -p "$W/fakebin"; printf '#!/bin/bash\necho "rm $*" >> "%s/rm-asked"\n' "$W" > "$W/fakebin/rm"; chmod 755 "$W/fakebin/rm"
: > "$W/rm-asked"
(
  PATH="$W/fakebin:$PATH"
  rm() { echo "rm $*" >> "$W/rm-asked"; }
  . "$ROOT/common/auster"
  HOME=$H1
  au_identity > /dev/null || exit 1
  for d in '' / "$H1" "$H1/Library" "$H1/$DATA_REL"; do au_root_delete "$d" > /dev/null; done
  HOME=/ au_root_delete "/Library/Application Support/Auster" > /dev/null
  echo ran > "$W/rm-ran"
)
same "$(cat "$W/rm-ran" 2>/dev/null)" ran "the deletion was called directly, six times"
same "$(cat "$W/rm-asked")" "" "the deletion is never asked of an empty path, /, the home folder, or a data root that is a link"

# An install, with ~/.zprofile a link: the line is printed, not written
cp "$W/zprofile-elsewhere" "$W/zprofile-target-before"
run_install $'no\nyes\nipad\nyes\n' "$IR"
same "$RC" 0 "the install, yes to the line in ~/.zprofile, which is a link"
says "$line" "it prints the line to add"
[ -L "$H/.zprofile" ] && ok "the install: ~/.zprofile is still a link" || bad "~/.zprofile is no longer a link"
cmp -s "$W/zprofile-elsewhere" "$W/zprofile-target-before" && ok "the install: its target is unchanged" || bad "the target changed: $(cat "$W/zprofile-elsewhere")"
printf '%s\n' "$line" >> "$W/zprofile-elsewhere"   # the household adds it, as the install said
cp "$W/zprofile-elsewhere" "$W/zprofile-target-before"
echo keep > "$DATA/sentinel"

# auster remove, the marker taken away between the two questions (answered through a pipe)
mkfifo "$W/tty"
exec 5<> "$W/tty"
HOME="$H" AU_TTY="$W/tty" /bin/bash "$DATA/bin/auster" remove > "$W/out" 2>&1 &
pid=$!
printf 'yes\n' >&5
for i in $(seq 150); do grep -qF "What is left, in" "$W/out" 2>/dev/null && break; sleep 0.1; done
grep -qF "What is left, in" "$W/out" && ok "remove: the first yes, then what is left is listed" || bad "remove: $(cat "$W/out")"
rm -f "$DATA/.auster-data-root"
printf 'yes\n' >&5
for i in $(seq 100); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
kill -0 "$pid" 2>/dev/null && { kill "$pid"; bad "remove did not end"; }
wait "$pid"; RC=$?
exec 5>&-
same "$RC" 1 "remove, its marker gone before the second yes: refused"
says "nothing was deleted" "it says nothing was deleted"
same "$(cat "$DATA/sentinel" 2>/dev/null)" keep "the sentinel in the data root survives"
[ -d "$DATA/store" ] && ok "the data root is there, whole" || bad "the data root was deleted"
says "$line" "remove: it prints the line to take out of ~/.zprofile"
[ -L "$H/.zprofile" ] && ok "remove: ~/.zprofile is still a link" || bad "remove: ~/.zprofile is no longer a link"
cmp -s "$W/zprofile-elsewhere" "$W/zprofile-target-before" && ok "remove: its target is unchanged" || bad "remove: the target changed"
done_
