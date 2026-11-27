# T6's rule of ownership (D3.1): before any write, the data root and every folder in it, at any depth, must be this
# account's and nobody else's to write, and no link in it may lead to a folder (those inside an engine's unpacked
# tree point inside it, B3 step 9, and are allowed); otherwise nothing is written. Three writers are held to it: the
# rule file (auu_own, before it writes `tried`, `offer`, `notes.md` and `noted`), the installer (the driver, through
# common/auster's au_root_check) and bin/auster (every command, through the same). A folder others may write deep in
# the data root, a link to a folder, and a data root of another mode each stop them with nothing changed, the folder
# named; a folder of another owner is refused by the same function (its owner given as another account's number).
# Mutants: tests/mutants/T6e (the installer and bin/auster) and T6f (the rule file).
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/records-helpers.sh"
records_env
mkdir -p "$D/engines/$SA/root/lib" "$W/elsewhere-dir"
ln -s lib "$D/engines/$SA/root/lib-link"
own() { ( AU_UPDATE_DIR=$D/_update; . "$ROOT/common/updates.sh"; auu_own ) && echo yes || echo no; }
tree() { au_own_tree "$D" > /dev/null && echo yes || echo no; }

same "$(own):$(tree)" yes:yes "the data root as Auster makes it, with a link to a folder inside an engine's tree: the rule file's and common/auster's rule pass"
chmod 775 "$D/engines/$SA/root/lib"
same "$(own):$(tree)" no:no "a folder deep in an engine's tree that its group may write: both refuse"
same "$(au_own_tree "$D")" "./engines/$SA/root/lib" "and common/auster names it"
chmod 755 "$D/engines/$SA/root/lib"; mkdir "$D/logs/old"; chmod 707 "$D/logs/old"
same "$(own):$(tree)" no:no "a folder in logs/ that others may write: both refuse"
rmdir "$D/logs/old"; ln -s "$W/elsewhere-dir" "$D/builds/$IR/more"
same "$(own):$(tree)" no:no "a link to a folder outside, in a recipe's folder: both refuse"
rm "$D/builds/$IR/more"; ln -s "$W/elsewhere-dir" "$D/store/dir"
same "$(own):$(tree)" no:no "a link to a folder in store/: both refuse"
rm "$D/store/dir"; ln -s "$W/elsewhere-dir/nothing" "$D/store/dangling"; ln -s "$(path_of stopped)" "$D/builds/stopped-link"
same "$(own):$(tree)" yes:yes "a link to nothing and a link to a file are not folders: both pass (a reader takes the link as absent)"
rm "$D/store/dangling" "$D/builds/stopped-link"; chmod 750 "$D"
same "$(own)" no "the data root of mode 0750: the rule file refuses"
chmod 700 "$D"
same "$(AU_UID=$((AU_UID + 1)); tree)" no "every folder another account's: common/auster refuses"
same "$(own):$(tree)" yes:yes "all put back: both pass"

# The rule file: with a folder others may write, --refresh fetches nothing and writes nothing
stub_env
curl_route GET https://raw.githubusercontent.com/macaiport/auster/refs/heads/release/CHANGELOG.md 200 -
rm -f "$D/_update/tried"; mkdir "$D/keys/x"; chmod 777 "$D/keys/x"
before=$(snapshot "$D")
o=$(env AU_UPDATE_DIR="$D/_update" AU_UPDATE_NOW=1800000000 /bin/bash "$ROOT/common/updates.sh" --refresh)
same "$(printf '%s' "$o" | cut -f5):$(ls "$STUB_CURL_DIR/requests" 2>/dev/null | wc -l | tr -d ' ')" "failed:0" "--refresh with keys/x open to all: no request"
same "$(snapshot "$D")" "$before" "  ...and nothing written"
rmdir "$D/keys/x"
cd "$W" || exit 1

# The installer: a data root left by an earlier install, with one folder others may write
. "$TESTS/job-helpers.sh"
. "$TESTS/command-helpers.sh"
install_env
mkdir -m 700 "$DATA" "$DATA/builds" "$DATA/engines" "$DATA/engines/$SA" "$DATA/engines/$SA/root" "$DATA/engines/$SA/root/lib"
: > "$DATA/.auster-data-root"
chmod 770 "$DATA/engines/$SA/root/lib"
before=$(snapshot "$DATA")
run_install $'no\nno\n' "$IR"
same "$RC" 1 "the installer, with a folder its group may write deep in the data root: exit 1"
says "$DATA/engines/$SA/root/lib must be a folder that only tester owns and can write" "it names the folder"
same "$(snapshot "$DATA")" "$before" "  ...and nothing in the data root changed"
grep -qE 'Fetching|Measuring' "$W/out" && bad "it went on to measure the Mac" || ok "it went no further"
rm -rf "$DATA"

# bin/auster: every command, on an installed Mac
cmd_install
mkdir "$DATA/logs/old"; chmod 777 "$DATA/logs/old"
before=$(snapshot "$DATA") calls=$(grep -c '^launchctl' "$STUB_LOG")
for c in stop start restart network 'key add ipad2' 'key revoke ipad' 'people 2' update status; do
  auster $c
  same "$RC" 1 "bin/auster, logs/old open to all, $c: refused"
  outsays "$DATA/logs/old must be a folder that only tester owns and can write" "  ...$c names the folder"
done
ANSWERS=$'yes\nyes\n' auster remove
same "$RC" 1 "  ...remove is refused too: it would write"
same "$(snapshot "$DATA"):$(grep -c '^launchctl' "$STUB_LOG")" "$before:$calls" "  ...and nothing changed, no job touched"
chmod 700 "$DATA/logs/old"
auster stop
same "$RC" 0 "the folder put right: stop works again"
done_
