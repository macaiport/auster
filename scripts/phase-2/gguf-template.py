# Phase 2 of Auster: takes a model file's own chat template out into a file, for assets/ (plan A4, A6).
# Reads only the GGUF header's metadata, in order, and stops at its end: no tensor is read, the model is
# not loaded and no engine is started. Runs on the development Mac only, never on a household's.
#
#   gguf-template.py <model.gguf> <out file>    writes tokenizer.chat_template byte for byte, as the file
#                                               carries it (no newline added), and refuses an existing
#                                               out file
#   gguf-template.py <model.gguf>               writes nothing
#
# Prints, to stdout, the GGUF version, the architecture, the file's context limit, the template's length
# in bytes and its sha256.
import hashlib, os, struct, sys

SCALARS = {0: "<B", 1: "<b", 2: "<H", 3: "<h", 4: "<I", 5: "<i", 6: "<f", 7: "<?", 10: "<Q", 11: "<q", 12: "<d"}


class Reader:
    def __init__(self, f):
        self.f = f

    def take(self, n):
        b = self.f.read(n)
        if len(b) != n:
            sys.exit("gguf-template: the file ends inside its metadata")
        return b

    def unpack(self, fmt):
        return struct.unpack(fmt, self.take(struct.calcsize(fmt)))[0]

    def string(self):
        return self.take(self.unpack("<Q"))

    def value(self, t):
        if t in SCALARS:
            return self.unpack(SCALARS[t])
        if t == 8:
            return self.string()
        if t == 9:
            et, n = self.unpack("<I"), self.unpack("<Q")
            for _ in range(n):          # read through, keep nothing: a vocabulary is 100,000+ strings
                self.value(et)
            return None
        sys.exit("gguf-template: unknown value type %d" % t)


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit("usage: gguf-template.py <model.gguf> [out file]")
    out = sys.argv[2] if len(sys.argv) == 3 else None
    if out and os.path.lexists(out):
        sys.exit("gguf-template: %s exists" % out)
    meta = {}
    with open(sys.argv[1], "rb") as f:
        r = Reader(f)
        if r.take(4) != b"GGUF":
            sys.exit("gguf-template: not a GGUF file")
        version = r.unpack("<I")
        if version not in (2, 3):
            sys.exit("gguf-template: GGUF version %d" % version)
        r.unpack("<Q")                  # tensor count
        for _ in range(r.unpack("<Q")):
            key = r.string().decode("utf-8")
            meta[key] = r.value(r.unpack("<I"))
        end = f.tell()
    arch = meta.get("general.architecture", b"").decode("utf-8")
    tpl = meta.get("tokenizer.chat_template")
    print("gguf version %d, metadata ends at byte %d" % (version, end))
    print("architecture %s, context limit %s" % (arch, meta.get(arch + ".context_length")))
    if tpl is None:
        print("no tokenizer.chat_template")
        sys.exit(1)
    print("tokenizer.chat_template: %d bytes, sha256 %s" % (len(tpl), hashlib.sha256(tpl).hexdigest()))
    if out:
        with open(out, "xb") as o:
            o.write(tpl)


main()
