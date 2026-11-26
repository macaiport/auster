# T52, the registry's half: order 1 withdrawn with `superseded`, held, failed here, or not fitting: order 2
# is chosen. A corrected build of the same files, ordered first: it is chosen (A3, D3.7, D3.8). Held,
# failed and fit come from the judge hook registry-lib.js describes, which U6 (`hold`), U2 (`failed/`)
# and V3 (section C) fill. Left to later steps: that moving to the corrected build downloads nothing
# (U5, the plan's mutant (b), "download again for the same sha256"), and its calm words (U8); here, that
# it names the very engine and model lines of the build it corrects, and that its reason is a known one.
# Mutant: tests/mutants/T52a.
. "$TESTS/lib.sh"
. "$TESTS/registry-helpers.sh"
W=$(mktemp -d "${TMPDIR%/}/t52.XXXXXX")
BC=bsyn3jk2ujtyp     # the corrected order 1: the same files, the memory outside the GPU 500 MiB, not 484

extend "$REG/good-v0.1.0.tsv" "$W/superseded.tsv" "$(rec withdraw $B1 superseded)"
o=$(reader "$W/superseded.tsv" "$HH")
same "$(kind "$o" build | head -1 | cut -f3,4):$(taken "$o")" "withdrawn${T}superseded:$B2" "order 1 withdrawn, superseded: order 2 is chosen"

corrected=$(sed -n 5p "$REG/good-v0.1.0.tsv" | sed "s/^build${T}$B1/build${T}$BC/; s/${T}484${T}/${T}500${T}/")
extend "$REG/good-v0.1.0.tsv" "$W/corrected.tsv" "$corrected" "$(rec order $HH $BC $B2)" "$(rec withdraw $B1 corrected)"
o=$(reader "$W/corrected.tsv" "$HH")
same "$(passed_lines "$o")" "" "the corrected registry: every line read"
same "$(taken "$o")" "$BC" "the corrected build, ordered first, is chosen"
same "$(kind "$o" build | cut -f5,13 | tr '\t\n' ' ')" "$BC 500 $B2 432 " "its figure is the corrected one, and order 1 is no longer in the order"
a=$(reader "$REG/good-v0.1.0.tsv" "$HH")
same "$(kind "$o" raw | awk -F'\t' '$2 == "'$BC'" && $3 != "build"' | cut -f3-)" \
  "$(kind "$a" raw | awk -F'\t' '$2 == "'$B1'" && $3 != "build"' | cut -f3-)" "it names the same engine and model lines, byte for byte, as order 1"

got=$(jxa "
var sup = auRegRead(argv[0]), cor = auRegRead(argv[1]), good = auRegRead(argv[2]), R = '$HH';
function says(code) { return function (e) { return e.id === '$B1' ? [code] : []; }; }
function id(e) { return e ? e.id : 'none'; }
var w = cor.withdrawn['$B1'];
return [id(auRegChoose(sup, R)), id(auRegChoose(good, R, says('held'))), id(auRegChoose(good, R, says('failed'))),
  id(auRegChoose(good, R, says('fit'))), id(auRegChoose(good, R)), id(auRegChoose(cor, R)),
  w.reason + ' ' + w.known, auRegRecipeLine(cor, R, '$B1').state + ' ' + id(auRegRecipeLine(cor, R, '$B1').pick)].join(' ');
" "$W/superseded.tsv" "$W/corrected.tsv" "$REG/good-v0.1.0.tsv")
same "$got" "$B2 $B2 $B2 $B2 $B1 $BC corrected true waiting $BC" \
  "superseded, held, failed, not fitting: order 2; with none of these order 1; corrected: the new build, a known reason, waiting"
done_
