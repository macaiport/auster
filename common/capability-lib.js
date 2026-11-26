// Section C of docs/plans/v0.1.md, the capability rules (C1 to C6), in JavaScript for Automation (BD17):
// one function, auCapChoose, over the registry (common/registry-lib.js) and this Mac's figures. It
// chooses the build, the number of people and the context per person (C4), says which way the switch goes
// (C5) and whether there is room on disk (C6), or refuses with this Mac's figures.
//
// Functions and vars only, no run(), and nothing runs when it is loaded. Load registry-lib.js first, then
// this file, each with a direct eval in sloppy code, as registry-lib.js's header shows:
//
//   eval(auLoad(dir + '/registry-lib.js'));
//   eval(auLoad(dir + '/capability-lib.js'));
//
// Every function is pure except auCapReadFile, the only one that touches the disk.
//
// Arithmetic. Every figure is a whole number below 2^53, so it is exact in a Number. Needs are in MiB,
// memory, disk and downloads in bytes. Rounding happens in three places only, each on the safe side:
//   - the cache, cache per token x people x context bytes, is rounded UP to whole MiB (auCapNeeds);
//   - memory is rounded DOWN to whole MiB (auCapFits), which moves no verdict, since every need is whole MiB;
//   - 5% of the volume is rounded UP to whole bytes (auCapDiskFloor).
//
// ---------------------------------------------------------------------------------------------------
// C1, the figures (auCapFigures). Four figures, each from the first of these that has it:
//   1. its test variable, when it matches ^(0|[1-9][0-9]{0,14})$ whole: AU_GPU_MIB, AU_RAM_BYTES,
//      AU_DISK_FREE_BYTES, AU_DISK_TOTAL_BYTES. Anything else in the variable is not used;
//   2. what the caller measured: the GPU limit from the engine's `--list-devices` (auCapListDevices), the
//      memory from `sysctl -n hw.memsize`, free disk and the volume's size from `df -k` (auCapDf). A
//      measurement that was made and refused is never replaced by the `mac` record: no limit is guessed;
//   3. the `mac` record (GPU limit and memory only; disk is never recorded, since it changes).
//
// `--list-devices` (auCapListDevices, T102). The output of llama.cpp b12359, at most 64 KiB:
//
//   Available devices:
//     MTL0: Apple M5 Max (53084 MiB, 53083 MiB free)
//     BLAS: Accelerate (0 MiB, 0 MiB free)
//
// The GPU limit is the first figure of the one line, after `Available devices:`, that is exactly
// `  MTL0: <name> (<total> MiB, <free> MiB free)`. Refused, with a code, when there is no such header
// (`not-list-devices`), no line naming MTL0 (`no-mtl0`), an MTL0 line in any other form, such as the two
// figures swapped (`mtl0-form`), more than one (`mtl0-twice`), or a total of 0 or over 1,048,576 MiB
// (`mtl0-figure`).
//
// `df -k <data root>` (auCapDf, T93): a header line and one line for the volume, in macOS's own form or
// with -P; at most 4,096 bytes. Free disk is the Available column and the volume's size the 1024-blocks
// column, each in KiB and multiplied by 1,024 here; each matched as ^(0|[1-9][0-9]{0,11})$. Anything
// else is refused (`df-form`).
//
// ---------------------------------------------------------------------------------------------------
// The `mac` record, `builds/mac` (D3.1, B3 step 4). Written by the installer at every install and update
// (U2), read here first. Its form, which a writer follows byte for byte:
//
//   auster-record 1
//   gpu-mib<TAB>53084
//   memory-bytes<TAB>68719476736
//   macos<TAB>27.2.1
//   measured<TAB>2026-11-26T15:04:05Z
//   router<TAB>0a:1b:2c:3d:4e:5f
//   keep-awake<TAB>yes
//
// Seven lines, each ending in a newline, exactly these keys in exactly this order, one tab between key
// and value, nothing else. A writer writes it to a temporary file and renames it. The fields:
//
//   gpu-mib        the GPU limit, MiB: the total for MTL0 from --list-devices. ^(0|[1-9][0-9]{0,8})$,
//                  at most 1,048,576 (A3's ceiling for MiB)
//   memory-bytes   `sysctl -n hw.memsize`. ^(0|[1-9][0-9]{0,14})$
//   macos          `sw_vers -productVersion`. ^[1-9][0-9]?\.(0|[1-9][0-9]?)(\.(0|[1-9][0-9]?))?$
//   measured       when the GPU limit and memory were measured, UTC: `date -u +%Y-%m-%dT%H:%M:%SZ`
//   router         the home network's router, by hardware address (BD9, B4 step 5): six bytes, each two
//                  lowercase hex digits, joined by colons. `arp -n` leaves out leading zeros
//                  (`0:11:2:...`); the writer puts them back. Recorded at a first install and by `auster
//                  network` only; an update copies it from the record it replaces
//   keep-awake     `yes` or `no`: the household's answer to the question (BD10, T103)
//
// The reader (auCapParseMac, bound 1,024 bytes): the first line is checked first. `auster-record 1` is
// read on; `auster-record <n>` with a larger number gives state `newer` (Auster refuses, says how to update
// or remove, and leaves the record as it is: D3.1, T95); anything else, a file over 1,024 bytes, one cut
// short (no final newline), a key out of place, a value that fails its pattern or any other byte out of
// place gives state `absent`. A file that is a link is absent too (auCapReadFile).
//
// ---------------------------------------------------------------------------------------------------
// The disk holdings (auCapParseDisk; what the caller lists for the disk rule, C6). Not a record on disk:
// the caller (U2, U6) makes it from `store/`, `engines/` and every recipe's descriptors. At most 256 KiB:
//
//   auster-disk 1
//   file<TAB><store|engines>/<sha256><TAB><bytes>      what each file or folder takes on disk
//   partial<TAB><sha256><TAB><bytes>                   bytes of an unfinished download already on disk
//   desc<TAB><recipe id><TAB><serving|kept|failed><TAB><date or -><TAB><build id><TAB><engine sha256>
//       <TAB><model sha256><TAB><template sha256><TAB><system prompt sha256><TAB><test sha256>
//
// One `desc` line for every descriptor of every recipe: its date (the one in its file name, UTC,
// 2026-11-26T15:04:05Z; `-` for `serving`) and the sha256s from its build, engine and model lines. A
// descriptor names store/ of all five and engines/ of the engine. Any line out of form refuses the whole.
//
// ---------------------------------------------------------------------------------------------------
// The rules.
//
//   C2 auCapNeeds(build, people, context) -> { gpuMiB, totalMiB }
//      on the GPU: weights + working buffers + cache per token x people x context (the cache rounded up
//      to MiB); in all: that plus the engine's memory outside the GPU.
//   C3 auCapFits([needs...], figures) -> whether the set, loaded at once, fits: the GPU needs summed, plus
//      1,024 MiB, at most the GPU limit; and memory, less the needs in all summed, at least 12,288 MiB.
//   C4 auCapContext(build, model, recipe, people, figures) -> the largest context per person, in steps of
//      1,024 from the recipe's minimum up to the smaller of its maximum and the model file's own limit
//      (per person, T90), that fits on its own; 0 when none does. The build is chosen in auCapChoose.
//   C5 auCapWay(reg, loaded, build, figures) -> 'side-by-side' when everything loaded, at its setting,
//      plus the build for one person at 8,192, fits; 'in-turn' otherwise, and when nothing is loaded (a
//      first install tests at the household's setting: B3 step 10).
//   C6 auCapDiskFloor(volume bytes) -> the larger of 20 GiB and 5% of the volume. There is room when free
//      disk, less the download, is at least the floor. The download is the model file and the engine
//      archive, each unless store/ holds it, less any part already down. Not counted, since the registry
//      gives no size for them: the engine unpacked into engines/, and the template, system prompt and
//      test from the tree (kilobytes; the floor covers both). With nothing to download the rule still
//      asks for the floor, so a caller that fetches nothing (`auster people`) passes no disk figures.
//      On an update without room,
//      auCapRemovals names earlier builds of this recipe: failed first, then kept, each oldest first, the
//      newest kept last and only on the person's yes; the shortest run from the front of that order that
//      makes room, less any build in it that room does not need. A file counts as freed only when no
//      descriptor that stays, of any recipe, names it, and never when it is the build in use's or the
//      chosen build's.
//
// auCapChoose(reg, recipeId, o) -> result. o is
//   { figures,         auCapFigures' answer
//     people,          the household's number, carried over (C4); null at a first install: the recipe's
//                      default. A number above the recipe's default is lowered to it
//     serving,         the build served, or null at a first install
//     keepBuild,       true for `auster people`: the build served only, at the new setting (B6)
//     loaded,          [{ build, people, context }]: what is loaded now (C5); [] at a first install
//     held, failed,    build ids the recipe's `hold` and `failed/` name (D3.7); the judge adds them
//     holdings }       auCapParseDisk's answer, or null when nothing is on disk
//
// How the build is chosen. Every build in the recipe's latest order is judged (registry-lib.js's hook):
// `held`, `failed`, `fit` (no context fits, C4), and at a first install with disk figures `room` (it fits
// in memory but not on disk, BD13). At a first install the first build with no code wins, so a build with
// no room gives way to the next that fits on disk (BD13), and `room` reports the space it needs. On an
// update, D3.7's rule (auRegRecipeLine) picks against the build served: a later build is never offered
// unless the one served is withdrawn or no longer fits; then the disk rule applies to it, naming builds to
// remove. With keepBuild, only the build served, whatever the registry says of it.
//
// The result: { ok, refused, detail, figures, people, builds, choice, disk, removals, room, needs }
//   ok          true when a build was chosen; refused is then null
//   refused     why not, a code: registry (detail: unreadable or absent), figures (detail: mac then newer,
//               when the `mac` record is of a newer format, whatever else is known; or gpu, memory or
//               disk, then why: missing, or the measurement's code), people (the recipe's
//               default is 0), serving (keepBuild and the build served is not in the registry), fit (no
//               build has a context that fits, whatever else rules it out: needs is the smallest of those
//               ruled out by fit alone), none (nothing appropriate for other
//               reasons: detail lists the codes), room (fits in memory, no room on disk: room says how much)
//   builds      the recipe's builds in order, each registry-lib.js's entry with cap: { context, needs at
//               that context or at the recipe's minimum (null when the model's limit is below it), download }
//   choice      { id, entry, people, context, gpuMiB, totalMiB, way, disk } disk: room, remove or unknown
//   disk        { download, floor, free, freed } when disk figures were given
//   removals    the descriptors to remove, in order, each with yes true when it needs the person's yes
//   room        [{ id, download, freeNeeded }]: builds that fit in memory with no room on disk, and the free
//               bytes each needs (download plus floor): at exit 0 those passed over (BD13); at `room` every
//               one at a first install, the one chosen on an update
//   needs       { id, people, context, gpuMiB, totalMiB, gpuLimitMiB, memoryMiB }: the smallest build at the
//               recipe's minimum, and the GPU limit and memory a Mac needs for it (C3 turned round)
//
// auCapReport(result) -> the lines common/capability.js prints (its header describes them).

var AU_CAP_MIB = 1048576;
var AU_CAP_GIB = 1073741824;
var AU_CAP_KIB = 1024;                          // df -k counts in KiB (C1, T93)
var AU_CAP_MARGIN_MIB = 1024;                   // C3.1: Auster's margin on the GPU
var AU_CAP_REST_MIB = 12288;                    // C3.2: 12 GiB for macOS and the household's other apps
var AU_CAP_STEP = 1024;                         // C4: contexts in steps of 1,024
var AU_CAP_SIDE_PEOPLE = 1;                     // C5: the candidate beside the server, for one person
var AU_CAP_SIDE_CONTEXT = 8192;                 //     at 8,192
var AU_CAP_DISK_FLOOR = 20 * AU_CAP_GIB;        // C6: free disk kept: at least 20 GiB
var AU_CAP_DISK_PERCENT = 5;                    //     and at least 5% of the volume
var AU_CAP_FIGURE = /^(0|[1-9][0-9]{0,14})$/;   // C1: a test variable, matched whole
var AU_CAP_VARS = { gpuMiB: 'AU_GPU_MIB', ramBytes: 'AU_RAM_BYTES', diskFree: 'AU_DISK_FREE_BYTES', diskTotal: 'AU_DISK_TOTAL_BYTES' };
var AU_CAP_MAX = { listDevices: 65536, df: 4096, mac: 1024, disk: 262144 };
var AU_CAP_MTL0 = /^  MTL0: .+ \((0|[1-9][0-9]{0,8}) MiB, (0|[1-9][0-9]{0,8}) MiB free\)$/;
var AU_CAP_SHA = /^[0-9a-f]{64}$/;
var AU_CAP_DATE = /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]Z$/;
var AU_CAP_MAC_FIELDS = [   // the mac record's lines after the first, in order: key, pattern, ceiling
  ['gpu-mib', /^(0|[1-9][0-9]{0,8})$/, 1048576],
  ['memory-bytes', AU_CAP_FIGURE],
  ['macos', /^[1-9][0-9]?\.(0|[1-9][0-9]?)(\.(0|[1-9][0-9]?))?$/],
  ['measured', AU_CAP_DATE],
  ['router', /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/],
  ['keep-awake', /^(yes|no)$/]
];

function auCapDivUp(x, d) { var r = x % d; return (x - r) / d + (r ? 1 : 0); }   // exact below 2^53
function auCapDivDown(x, d) { return (x - x % d) / d; }

function auCapReadFile(path, max) { // -> { ok, bytes, big, reason }: at most max + 1 bytes, as a byte string
  var fm = $.NSFileManager.defaultManager;
  var attrs = fm.attributesOfItemAtPathError(path, null);   // a link is not followed
  if (attrs.isNil() || ObjC.unwrap(attrs.objectForKey('NSFileType')) !== 'NSFileTypeRegular') return { ok: false, reason: 'unreadable' };
  var h = $.NSFileHandle.fileHandleForReadingAtPath(path);
  if (h.isNil()) return { ok: false, reason: 'unreadable' };
  var data = h.readDataOfLength(max + 1);
  h.closeFile;
  var s = data.length ? ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSISOLatin1StringEncoding)) : '';
  if (typeof s !== 'string') return { ok: false, reason: 'unreadable' };
  return { ok: true, bytes: s.length > max ? s.slice(0, max) : s, big: s.length > max, reason: null };
}

// --- C1 ---------------------------------------------------------------------------------------------

function auCapListDevices(text, big) { // -> { gpuMiB, why }: why null when the limit was found
  if (big || typeof text !== 'string') return { gpuMiB: null, why: big ? 'too-large' : 'unreadable' };
  var lines = text.split('\n'), header = -1, found = [], i, m;
  for (i = 0; i < lines.length; i++) {
    if (header < 0 && lines[i] === 'Available devices:') header = i;
    if (lines[i].indexOf('MTL0') >= 0) found.push(i);
  }
  if (header < 0) return { gpuMiB: null, why: 'not-list-devices' };
  if (!found.length) return { gpuMiB: null, why: 'no-mtl0' };
  if (found.length > 1) return { gpuMiB: null, why: 'mtl0-twice' };
  m = found[0] > header ? AU_CAP_MTL0.exec(lines[found[0]]) : null;
  if (!m) return { gpuMiB: null, why: 'mtl0-form' };
  var total = parseInt(m[1], 10);
  if (total < 1 || total > 1048576) return { gpuMiB: null, why: 'mtl0-figure' };
  return { gpuMiB: total, why: null };
}

function auCapDf(text, big) { // -> { free, total, why }: bytes
  var bad = { free: null, total: null, why: 'df-form' };
  if (big || typeof text !== 'string') return bad;
  var lines = text.split('\n');
  if (lines.length === 3 && lines[2] === '') lines.pop();
  if (lines.length !== 2) return bad;
  if (!/^Filesystem +1024-blocks +Used +Available +Capacity( +iused +ifree +%iused)? +Mounted on$/.test(lines[0])) return bad;
  var k = '(0|[1-9][0-9]{0,11})';
  var m = new RegExp('^\\S.*? +' + k + ' +' + k + ' +' + k + ' +[0-9]{1,3}%( +[0-9]+ +[0-9]+ +[0-9]{1,3}%)? +/.*$').exec(lines[1]);
  if (!m || /[\x00-\x1f\x7f]/.test(lines[1])) return bad;
  return { free: parseInt(m[3], 10) * AU_CAP_KIB, total: parseInt(m[1], 10) * AU_CAP_KIB, why: null };
}

function auCapParseMac(bytes, big) { // -> { state: ok, absent or newer, gpuMiB, ramBytes, macos, measured, router, keepAwake }
  var absent = { state: 'absent' };
  if (typeof bytes !== 'string') return absent;
  var nl = bytes.indexOf('\n'), head = /^auster-record ([1-9][0-9]{0,8})$/.exec(nl < 0 ? bytes : bytes.slice(0, nl));
  if (!head) return absent;
  if (head[1] !== '1') return { state: 'newer' };
  if (big || bytes.length > AU_CAP_MAX.mac || bytes.charAt(bytes.length - 1) !== '\n') return absent;
  var lines = bytes.slice(0, -1).split('\n');
  if (lines.length !== AU_CAP_MAC_FIELDS.length + 1) return absent;
  var v = {}, i, f, spec;
  for (i = 0; i < AU_CAP_MAC_FIELDS.length; i++) {
    spec = AU_CAP_MAC_FIELDS[i]; f = lines[i + 1].split('\t');
    if (f.length !== 2 || f[0] !== spec[0] || !spec[1].test(f[1])) return absent;
    if (spec[2] && parseInt(f[1], 10) > spec[2]) return absent;
    v[spec[0]] = f[1];
  }
  return { state: 'ok', gpuMiB: parseInt(v['gpu-mib'], 10), ramBytes: parseInt(v['memory-bytes'], 10), macos: v.macos,
    measured: v.measured, router: v.router, keepAwake: v['keep-awake'] === 'yes' };
}

function auCapFigures(env, measured, mac) {
  // env: the environment, names to strings. measured: { gpuMiB, gpuWhy, ramBytes, diskFree, diskTotal,
  // diskWhy }, a figure null when not measured, a why set when a measurement was made and refused. mac:
  // auCapParseMac's answer, or null.
  // -> { gpuMiB, ramBytes, diskFree, diskTotal, macNewer, from: { same keys: test, measured, mac or - },
  //    why: { same keys: why a figure is missing: missing, or the measurement's code } }
  var out = { gpuMiB: null, ramBytes: null, diskFree: null, diskTotal: null, macNewer: !!mac && mac.state === 'newer', from: {}, why: {} };
  var m = measured || {}, rec = mac && mac.state === 'ok' ? mac : {};
  function take(key, why, recorded) {
    var v = env ? env[AU_CAP_VARS[key]] : undefined;
    out.from[key] = '-';
    if (typeof v === 'string' && AU_CAP_FIGURE.test(v)) { out[key] = parseInt(v, 10); out.from[key] = 'test'; return; }
    if (typeof m[key] === 'number') { out[key] = m[key]; out.from[key] = 'measured'; return; }
    if (why) { out.why[key] = why; return; }   // measured and refused: never guessed from the record
    if (typeof recorded === 'number') { out[key] = recorded; out.from[key] = 'mac'; return; }
    out.why[key] = 'missing';
  }
  take('gpuMiB', m.gpuWhy, rec.gpuMiB);
  take('ramBytes', null, rec.ramBytes);
  take('diskFree', m.diskWhy);
  take('diskTotal', m.diskWhy);
  return out;
}

// --- C2 to C5 ---------------------------------------------------------------------------------------

function auCapNeeds(build, people, context) {
  var cacheMiB = auCapDivUp(build.cachePerToken * people * context, AU_CAP_MIB);   // rounded up, here only
  var gpu = build.weightsMiB + build.buffersMiB + cacheMiB;
  return { gpuMiB: gpu, totalMiB: gpu + build.outsideMiB };
}

function auCapFits(needs, figures) {
  var gpu = 0, total = 0, i;
  for (i = 0; i < needs.length; i++) { gpu += needs[i].gpuMiB; total += needs[i].totalMiB; }
  var ramMiB = auCapDivDown(figures.ramBytes, AU_CAP_MIB);
  if (!(gpu + AU_CAP_MARGIN_MIB <= figures.gpuMiB)) return false;   // C3.1, on the GPU
  if (!(ramMiB - total >= AU_CAP_REST_MIB)) return false;           // C3.2, for the rest of the Mac
  return true;
}

function auCapTop(model, recipe) { // the largest context per person the recipe and the model file allow:
  return Math.min(recipe.contextMax, model.contextLimit);   // the file's limit is per person (T90)
}

function auCapContext(build, model, recipe, people, figures) {
  var best = 0, n, top = auCapTop(model, recipe);
  for (n = recipe.contextMin; n <= top; n += AU_CAP_STEP)
    if (auCapFits([auCapNeeds(build, people, n)], figures)) best = n;
  return best;
}

function auCapWay(reg, loaded, build, figures) {
  if (!loaded || !loaded.length) return 'in-turn';
  var needs = [], i;
  for (i = 0; i < loaded.length; i++) {
    if (!reg.builds.hasOwnProperty(loaded[i].build)) return 'in-turn';   // figures unknown: the safe way
    needs.push(auCapNeeds(reg.builds[loaded[i].build], loaded[i].people, loaded[i].context));
  }
  needs.push(auCapNeeds(build, AU_CAP_SIDE_PEOPLE, AU_CAP_SIDE_CONTEXT));
  return auCapFits(needs, figures) ? 'side-by-side' : 'in-turn';
}

// --- C6 ---------------------------------------------------------------------------------------------

function auCapParseDisk(bytes, big) { // -> { ok, files: { path: bytes }, partial: { sha256: bytes }, descs: [] }
  var bad = { ok: false, files: {}, partial: {}, descs: [] };
  if (big || typeof bytes !== 'string' || bytes.charAt(bytes.length - 1) !== '\n') return bad;
  var lines = bytes.slice(0, -1).split('\n'), out = { ok: true, files: {}, partial: {}, descs: [] }, i, f;
  if (lines[0] !== 'auster-disk 1') return bad;
  for (i = 1; i < lines.length; i++) {
    f = lines[i].split('\t');
    if (f[0] === 'file' && f.length === 3 && /^(store|engines)\/[0-9a-f]{64}$/.test(f[1]) && AU_CAP_FIGURE.test(f[2]) &&
        !out.files.hasOwnProperty(f[1])) out.files[f[1]] = parseInt(f[2], 10);
    else if (f[0] === 'partial' && f.length === 3 && AU_CAP_SHA.test(f[1]) && AU_CAP_FIGURE.test(f[2]) &&
        !out.partial.hasOwnProperty(f[1])) out.partial[f[1]] = parseInt(f[2], 10);
    else if (f[0] === 'desc' && f.length === 10 && AU_REG_PATTERNS.recipeId.test(f[1]) && /^(serving|kept|failed)$/.test(f[2]) &&
        (f[2] === 'serving' ? f[3] === '-' : AU_CAP_DATE.test(f[3])) && AU_REG_PATTERNS.buildId.test(f[4]) &&
        f.slice(5).every(function (s) { return AU_CAP_SHA.test(s); }))
      out.descs.push({ recipe: f[1], kind: f[2], date: f[3], build: f[4], files: auCapFilesOf(f[5], f[6], f[7], f[8], f[9]) });
    else return bad;
  }
  return out;
}

function auCapFilesOf(engine, model, template, systemPrompt, test) { // what a descriptor names (D3.1, A5)
  return ['store/' + engine, 'engines/' + engine, 'store/' + model, 'store/' + template, 'store/' + systemPrompt, 'store/' + test];
}

function auCapEntryFiles(e) {
  return auCapFilesOf(e.engine.sha256, e.model.sha256, e.build.template, e.build.systemPrompt, e.build.test);
}

function auCapDownload(e, holdings) { // bytes a build fetches: its model file and engine archive, less what is on disk
  var d = 0;
  [[e.model.sha256, e.model.size], [e.engine.sha256, e.engine.size]].forEach(function (f) {
    if (holdings.files.hasOwnProperty('store/' + f[0])) return;
    d += Math.max(0, f[1] - (holdings.partial[f[0]] || 0));
  });
  return d;
}

function auCapDiskFloor(total) {
  return Math.max(AU_CAP_DISK_FLOOR, auCapDivUp(total * AU_CAP_DISK_PERCENT, 100));
}

function auCapFreed(holdings, removed, protect) { // bytes freed by removing these descriptors
  var keep = {}, seen = {}, n = 0, i;
  for (i = 0; i < holdings.descs.length; i++)
    if (removed.indexOf(holdings.descs[i]) < 0) holdings.descs[i].files.forEach(function (p) { keep[p] = true; });
  for (i = 0; i < removed.length; i++) removed[i].files.forEach(function (p) {
    if (keep[p] || protect[p] || seen[p]) return;
    seen[p] = true; n += holdings.files[p] || 0;
  });
  return n;
}

function auCapRemovals(recipeId, holdings, protect, free, floor, download) { // -> { names, freed } or null
  function byDate(a, b) { return a.date < b.date ? -1 : a.date > b.date ? 1 : 0; }
  function of(kind) { return holdings.descs.filter(function (d) { return d.recipe === recipeId && d.kind === kind; }).sort(byDate); }
  var failed = of('failed'), kept = of('kept'), order = failed.concat(kept), set = [], i, j;
  var room = function (s) { return free + auCapFreed(holdings, s, protect) - download >= floor; };
  for (i = 0; i < order.length && !room(set); i++) set.push(order[i]);
  if (!room(set)) return null;
  for (j = set.length - 2; j >= 0; j--) {   // the last one made room; drop any other that room does not need
    var without = set.slice(0, j).concat(set.slice(j + 1));
    if (room(without)) set = without;
  }
  var newest = kept.length ? kept[kept.length - 1] : null;
  return { names: set.map(function (d) { return { desc: d, yes: d === newest }; }), freed: auCapFreed(holdings, set, protect) };
}

// --- C4, the choice ---------------------------------------------------------------------------------

function auCapEntry(reg, id) { // a build defined in the registry, as an entry, whatever its recipe's order says
  if (!reg.builds.hasOwnProperty(id)) return null;
  var b = reg.builds[id];
  return { id: id, position: 0, build: b, engine: reg.engines[b.engine], model: reg.models[b.model], why: [] };
}

function auCapRefuse(out, code, detail) {
  out.ok = false; out.refused = code; out.detail = detail || [];
  return out;
}

function auCapOnly(list, code) { // the entries ruled out by this code alone, in order
  return list.filter(function (e) { return e.why.length === 1 && e.why[0] === code; });
}

function auCapChoose(reg, recipeId, o) {
  var out = { ok: false, refused: null, detail: [], figures: o.figures, people: null, builds: [], choice: null,
    disk: null, removals: [], room: [], needs: null };
  var st = auRegRecipeState(reg, recipeId);
  if (st === 'unreadable' || st === 'absent') return auCapRefuse(out, 'registry', [st]);
  var f = o.figures;
  if (f.macNewer) return auCapRefuse(out, 'figures', ['mac', 'newer']);   // D3.1: never misread a newer record
  if (f.gpuMiB === null) return auCapRefuse(out, 'figures', ['gpu', f.why.gpuMiB]);
  if (f.ramBytes === null) return auCapRefuse(out, 'figures', ['memory', f.why.ramBytes]);
  var dw = f.why.diskFree || f.why.diskTotal;
  if (dw && dw !== 'missing') return auCapRefuse(out, 'figures', ['disk', dw]);
  var disk = f.diskFree !== null && f.diskTotal !== null;
  var recipe = reg.recipes[recipeId], first = !o.serving;
  var holdings = o.holdings || { files: {}, partial: {}, descs: [] };
  var people = o.people === null || o.people === undefined ? recipe.people : Math.min(o.people, recipe.people);
  out.people = people;
  if (people < 1) return auCapRefuse(out, 'people');
  var floor = disk ? auCapDiskFloor(f.diskTotal) : null;

  function judge(e) {
    var codes = [], n = auCapContext(e.build, e.model, recipe, people, f);
    var runs = auCapTop(e.model, recipe) >= recipe.contextMin;
    e.cap = { context: n, needs: n ? auCapNeeds(e.build, people, n) : runs ? auCapNeeds(e.build, people, recipe.contextMin) : null,
      download: auCapDownload(e, holdings) };
    if ((o.held || []).indexOf(e.id) >= 0) codes.push('held');
    if ((o.failed || []).indexOf(e.id) >= 0) codes.push('failed');
    if (!n) codes.push('fit');
    if (n && first && disk && f.diskFree - e.cap.download < floor) codes.push('room');   // BD13
    return codes;
  }

  var list = auRegBuildsFor(reg, recipeId, judge), pick = null, fitOnly;
  out.builds = list;
  if (o.keepBuild) {   // `auster people`: the build served, at the new setting, whatever else is said of it
    var own = auCapEntry(reg, o.serving);
    if (!own) return auCapRefuse(out, 'serving');
    judge(own);
    if (own.cap.context) pick = own;
    fitOnly = [own];
  } else {
    if (o.serving) pick = auRegRecipeLine(reg, recipeId, o.serving, judge).pick;
    else pick = auRegFirstAppropriate(list);
    if (!pick) pick = auCapOnly(list, 'room')[0] || null;   // fits in memory: the disk rule below says why it cannot be fetched
    fitOnly = auCapOnly(list, 'fit');
  }
  var noneFits = o.keepBuild || (list.length > 0 && list.every(function (e) { return e.why.indexOf('fit') >= 0; }));
  if (!pick && noneFits) {   // nothing fits this Mac: say what the smallest of those ruled out by fit alone needs
    var can = fitOnly.filter(function (e) { return e.cap.needs; }).sort(function (a, b) {
      return a.cap.needs.totalMiB - b.cap.needs.totalMiB || a.cap.needs.gpuMiB - b.cap.needs.gpuMiB || a.position - b.position;
    });
    if (can.length) out.needs = { id: can[0].id, people: people, context: recipe.contextMin, gpuMiB: can[0].cap.needs.gpuMiB,
      totalMiB: can[0].cap.needs.totalMiB, gpuLimitMiB: can[0].cap.needs.gpuMiB + AU_CAP_MARGIN_MIB,
      memoryMiB: can[0].cap.needs.totalMiB + AU_CAP_REST_MIB };
    return auCapRefuse(out, 'fit');
  }
  if (!pick) {
    var codes = [];
    list.forEach(function (e) { e.why.forEach(function (w) { if (codes.indexOf(w) < 0) codes.push(w); }); });
    return auCapRefuse(out, 'none', codes);
  }

  function roomOf(e) { return { id: e.id, download: e.cap.download, freeNeeded: e.cap.download + floor }; }
  if (first) {   // BD13: the builds before the one chosen that fit in memory and gave way for lack of disk
    for (var i = 0; i < list.length && list[i] !== pick; i++)
      if (list[i].why.length === 1 && list[i].why[0] === 'room') out.room.push(roomOf(list[i]));
  }

  var verdict = disk ? null : 'unknown';
  if (disk) {
    var dl = pick.cap.download, protect = {}, r = null;
    out.disk = { download: dl, floor: floor, free: f.diskFree, freed: 0 };
    if (f.diskFree - dl >= floor) verdict = 'room';
    else if (!first) {   // an update: the earlier builds whose removal makes room
      auCapEntryFiles(pick).forEach(function (p) { protect[p] = true; });
      auCapEntryFiles(auCapEntry(reg, o.serving) || pick).forEach(function (p) { protect[p] = true; });
      r = auCapRemovals(recipeId, holdings, protect, f.diskFree, floor, dl);
      if (r) { verdict = 'remove'; out.removals = r.names; out.disk.freed = r.freed; }
    }
  }
  if (!verdict) {   // at a first install every build that fits in memory, on an update the one chosen
    out.room = first ? auCapOnly(list, 'room').map(roomOf) : [roomOf(pick)];
    return auCapRefuse(out, 'room');
  }
  out.ok = true;
  out.choice = { id: pick.id, entry: pick, people: people, context: pick.cap.context, gpuMiB: pick.cap.needs.gpuMiB,
    totalMiB: pick.cap.needs.totalMiB, way: auCapWay(reg, o.loaded, pick.build, f), disk: verdict };
  return out;
}

// --- The report ------------------------------------------------------------------------------------

function auCapReport(r) {
  var T = '\t', out = [], f = r.figures;
  function v(x) { return x === null || x === undefined ? '-' : String(x); }
  out.push(['figures', v(f.gpuMiB), v(f.ramBytes), v(f.diskFree), v(f.diskTotal),
    f.from.gpuMiB, f.from.ramBytes, f.from.diskFree, f.from.diskTotal].join(T));
  r.builds.forEach(function (e) {
    var c = e.cap || {}, n = c.needs || null;
    out.push(['build', e.position, e.id, e.why.length ? e.why.join(',') : 'ok', c.context ? c.context : '-',
      n ? n.gpuMiB : '-', n ? n.totalMiB : '-'].join(T));
  });
  if (r.ok) {
    var c = r.choice;
    out.push(['choice', c.id, c.people, c.context, c.gpuMiB, c.totalMiB, c.way, c.disk].join(T));
  } else out.push(['refused', r.refused].concat(r.detail.length ? [r.detail.join(',')] : []).join(T));
  if (r.disk) out.push(['disk', r.disk.download, r.disk.floor, r.disk.free, r.disk.freed].join(T));
  r.removals.forEach(function (x) {
    out.push(['remove', x.desc.recipe, x.desc.kind, x.desc.date, x.desc.build, x.yes ? 'yes' : '-'].join(T));
  });
  r.room.forEach(function (x) { out.push(['room', x.id, x.download, x.freeNeeded].join(T)); });
  if (r.needs) {
    var s = r.needs;
    out.push(['needs', s.id, s.people, s.context, s.gpuMiB, s.totalMiB, s.gpuLimitMiB, s.memoryMiB].join(T));
  }
  return out;
}
