# T97, the engine job's half (V6; the installer's half is t97-install-unpack.sh): at every start a changed file
# in the engine's folder stops it with engine-hash (B4 step 4, AD13): a library changed at the same size, the
# program changed, a file added, a file removed, a link pointed elsewhere. The archive in store/ is unchanged
# throughout, so a job that hashed only the archive would start. The model is not hashed at start. Mutant:
# tests/mutants/T97b.
. "$TESTS/lib.sh"
. "$TESTS/helpers.sh"
. "$TESTS/install-helpers.sh"
. "$TESTS/job-helpers.sh"
job_install
R="$ED/root/llama-stub"

changed() { # LABEL: the engine's folder as the case left it
  [ "$(shasum -a 256 < "$DATA/store/$ESHA" | cut -c1-64)" = "$ESHA" ] && ok "$1: the archive in store/ is unchanged" || bad "$1: the archive changed"
  engine_job; engine_wait
  same "$EJ_CODE" engine-hash "$1: start says engine-hash"
  same "$(starts)" "$NSTARTS" "$1: no engine started"
  engine_job_end
  job_reset
}
{ head -c 10 "$R/libstub.0.dylib"; printf 'X'; tail -c +12 "$R/libstub.0.dylib"; } > "$W/lib"
same "$(stat -f %z "$W/lib")" "$(stat -f %z "$R/libstub.0.dylib")" "the changed library has the same size"
cat "$W/lib" > "$R/libstub.0.dylib"; changed "a library changed at the same size"
printf '# one more line\n' >> "$R/llama-server"; changed "the program changed"
printf 'extra\n' > "$R/libextra.dylib"; changed "a file added"
rm "$R/libstub.0.dylib"; changed "a file removed"
rm "$R/libstub.dylib"; ln -s llama-server "$R/libstub.dylib"; changed "a link pointed elsewhere"

m="$DATA/store/$SA"; chmod 644 "$m"; printf 'X' >> "$m"
engine_job; engine_wait
same "$EJ_CODE" starting "a changed model: the engine still starts (the model is not hashed at start)"
engine_job_end
done_
