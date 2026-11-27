# T101: installing a second, different recipe on a Mac that serves one refuses with exit 1, says why, and
# changes no record (BD14); the records of the recipe served are built directly, as D6 says. With it, the
# data root's own refusals before anything is written (B1, D3.1): a data root that is a link, and one with
# no marker, are left as they were. Mutant: tests/mutants/T101a.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
install_env
mkdir -m 700 "$DATA" "$DATA/builds" "$DATA/builds/$IR2" "$DATA/store" "$DATA/keys"
: > "$DATA/.auster-data-root"
{ printf 'auster-descriptor 1\n'; grep '^build' "$FX/registry.tsv" | head -n 1 | sed "s/$IB1/$IB3/"
  grep '^engine' "$FX/registry.tsv"; grep '^model' "$FX/registry.tsv" | head -n 1
  printf 'launch\t4\t32768\t8484\t%064d\t36.9\n' 0; } > "$DATA/builds/$IR2/serving"
printf 'auster-record 1\ngpu-mib\t53084\nmemory-bytes\t68719476736\nmacos\t27.2\nmeasured\t2026-11-26T15:04:05Z\nrouter\t00:00:5e:00:53:01\nkeep-awake\tno\n' > "$DATA/builds/mac"
before=$(snapshot "$H")

run_install $'no\nno\n' "$IR"
same "$RC" 1 "a second recipe: exit 1"
says "This Mac already serves another recipe ($IR2), and this version of Auster serves one recipe on a Mac." "it says why"
grep -q 'Auster is ready to install' "$W/out" && bad "it went on to the question" || ok "it asks nothing"
same "$(snapshot "$H")" "$before" "no record changed, and nothing else in the home folder"
same "$(requests | cut -d' ' -f2 | tr '\n' ' ')" "$API/heads/release $CODELOAD/$COMMIT " "nothing fetched but the commit and its tree"

# The data root a link: refused, the link and what it points at untouched
H2=$(make_home "$W/h2" --data-root-link)
b2=$(snapshot "$W/h2")
Hs=$H; H=$H2
run_install $'no\nno\n' "$IR"
H=$Hs
same "$RC" 1 "a data root that is a link: exit 1"
says "is a link. Auster's data root must be a folder of its own; nothing was changed." "a data root that is a link: it says why"
same "$(snapshot "$W/h2")" "$b2" "a data root that is a link: it and what it points at are as they were"

# A folder there with no marker: not Auster's, so refused
rm -rf "$DATA"; mkdir -m 700 "$DATA"; printf 'kept\n' > "$DATA/notes"
before=$(snapshot "$H")
run_install $'no\nno\n' "$IR"
same "$RC" 1 "a data root with no marker: exit 1"
says "is not Auster's data root (it has no .auster-data-root); nothing was changed." "a data root with no marker: it says why"
same "$(snapshot "$H")" "$before" "a data root with no marker: as it was"
done_
