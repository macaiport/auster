// Section C's command line (docs/plans/v0.1.md, C1 to C6), for bash callers. It loads registry-lib.js and
// capability-lib.js from its own folder; the rules, and the forms of the `mac` record and the disk
// holdings, are in capability-lib.js's header.
//
//   osascript -l JavaScript common/capability.js <registry.tsv> <recipe id> [option...]
//
//   --people N                 the household's number of people, 1 to 64, carried over from the launch
//                              line (C4); without it, the recipe's default. Above the default, the default
//   --serving BUILD            the build this recipe serves; without it, a first install
//   --keep-build               only the build served, at the new setting (`auster people`, B6). Needs
//                              --serving
//   --loaded BUILD PEOPLE CONTEXT   a build loaded now, at its setting (C5); may be given more than once
//   --held BUILD, --failed BUILD    a build in the recipe's `hold`, or in `failed/` (D3.7); each may be
//                              given more than once
//   --mac FILE                 the `mac` record
//   --list-devices FILE        the engine's --list-devices output (the GPU limit, measured)
//   --ram BYTES                `sysctl -n hw.memsize` (the memory, measured)
//   --df FILE                  `df -k` of the data root (free disk and the volume's size, measured).
//                              Without it, and without the test variables, the disk rule is not applied
//   --disk FILE                the disk holdings (what store/ and engines/ hold and what names it)
//
// The test variables AU_GPU_MIB, AU_RAM_BYTES, AU_DISK_FREE_BYTES and AU_DISK_TOTAL_BYTES win over
// everything when they match ^(0|[1-9][0-9]{0,14})$ whole (C1).
//
// Exit codes: 0 a build was chosen; 3 refused (the `refused` line says why); 2 usage (an unknown option,
// a value that fails its pattern, an option given twice that may be given once, a file that cannot be
// read, or disk holdings out of form); 1 this program failed.
//
// Output, on standard output: one record a line, fields separated by single tabs, the line's kind first.
// Every value printed is a number, an id or a code of Auster's own, never text from a file. This form is a
// contract with callers built by other versions: a later version may add kinds of line, or fields at the
// end of a line, and never changes or removes one.
//
//   figures   <gpu limit MiB> <memory bytes> <free bytes> <volume bytes> <from> <from> <from> <from>
//             first, always. A figure not known is -. Each from says where its figure came from:
//             test, measured, mac, or -
//   build     <position> <build id> <verdict> <context> <gpu MiB> <in all MiB>
//             one a build in the recipe's latest `order`, in order. verdict is ok, or what rules it
//             out, comma-separated: withdrawn, tier, held, failed, fit, room. context is the largest per
//             person that fits on its own (C4), or - when none does; the needs are at that context, at
//             the recipe's minimum when none fits, or - when the model file's limit is below it
//   choice    <build id> <people> <context> <gpu MiB> <in all MiB> <way> <disk>
//             exit 0 only. way: side-by-side or in-turn (C5; in-turn when nothing is loaded). disk:
//             room; remove (room once the builds in the `remove` lines are removed); unknown (no disk
//             figures were given)
//   refused   <reason> [<detail>]
//             exit 3 only. reason: registry (detail unreadable or absent), figures (detail mac,newer when
//             the `mac` record is of a newer format, whatever else is known; or gpu, memory or disk, a
//             comma, then missing, or the measurement's code: not-list-devices, no-mtl0, mtl0-form,
//             mtl0-twice, mtl0-figure, too-large, unreadable, df-form), people (kept in the vocabulary;
//             not reached here, since the reader passes over a recipe line with no people and --people
//             is at least 1), serving (--keep-build and the build served is not in the registry), fit
//             (no build fits this Mac, whatever else rules it out: see `needs`), none (nothing
//             appropriate, but not for fit alone; detail lists the codes, comma-separated), room (it
//             fits in memory but there is no room on disk: see `room`)
//   disk      <download bytes> <floor bytes> <free bytes> <bytes freed by the removals>
//             when disk figures were given and the rule reached the disk
//   remove    <recipe id> <kept|failed> <date> <build id> <yes|->
//             each descriptor whose removal makes room, in the order the rule names them (C6). yes: the
//             one before the one in use, which goes only on the person's yes
//   room      <build id> <download bytes> <free bytes needed>
//             a build that fits in memory but has no room on disk, one line each, in order: with exit 0
//             those passed over for the one chosen (BD13, a first install); with exit 3 every one at a
//             first install, and on an update the one chosen. free bytes needed is the download plus
//             the floor
//   needs     <build id> <people> <context> <gpu MiB> <in all MiB> <gpu limit MiB> <memory MiB>
//             with `refused fit`: the smallest build at the recipe's minimum context, and the GPU limit
//             and memory a Mac needs for it
//
// Lines come in this order: figures, build, then choice or refused, then disk, remove, room and needs
// where they apply.
ObjC.import('Foundation');
ObjC.import('stdlib');

function auLoad(path) {
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
}

function auWrite(handle, bytes) { // a byte string, written as the bytes it stands for
  if (bytes !== '') handle.writeData($(bytes).dataUsingEncoding($.NSISOLatin1StringEncoding));
}

function run(argv) {
  var all = ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments);
  var self = all[all.length - argv.length - 1];
  var dir = self.lastIndexOf('/') >= 0 ? self.slice(0, self.lastIndexOf('/')) : '.';
  var err = $.NSFileHandle.fileHandleWithStandardError;
  var libs = [auLoad(dir + '/registry-lib.js'), auLoad(dir + '/capability-lib.js')];
  if (typeof libs[0] !== 'string' || typeof libs[1] !== 'string') {
    auWrite(err, 'capability.js: cannot read its libraries in ' + dir + '\n');
    $.exit(1);
  }
  eval(libs[0]);   // Auster's own library files, from this program's folder (registry-lib.js says why eval)
  eval(libs[1]);

  function usage(why) {
    auWrite(err, 'capability.js: ' + why + '\nusage: osascript -l JavaScript capability.js <registry.tsv> <recipe id> [--people N] ' +
      '[--serving BUILD] [--keep-build] [--loaded BUILD PEOPLE CONTEXT]... [--held BUILD]... [--failed BUILD]... ' +
      '[--mac FILE] [--list-devices FILE] [--ram BYTES] [--df FILE] [--disk FILE]\n');
    $.exit(2);
  }
  var P = AU_REG_PATTERNS, PEOPLE = /^[1-9][0-9]?$/, CONTEXT = /^(0|[1-9][0-9]{0,6})$/;
  if (argv.length < 2) usage('a registry and a recipe id are needed');
  if (!P.recipeId.test(argv[1])) usage('the recipe id fails its pattern');
  var o = { people: null, serving: null, keepBuild: false, loaded: [], held: [], failed: [], holdings: null };
  var files = {}, ram = null, once = {}, i = 2;
  function next(pattern, what) {
    if (i >= argv.length) usage(what + ' is missing');
    var v = argv[i++];
    if (pattern && !pattern.test(v)) usage(what + ' fails its pattern');
    return v;
  }
  while (i < argv.length) {
    var a = argv[i++];
    if (/^--(people|serving|keep-build|mac|list-devices|ram|df|disk)$/.test(a)) {
      if (once[a]) usage(a + ' is given twice');
      once[a] = true;
    }
    if (a === '--people') { o.people = parseInt(next(PEOPLE, 'people'), 10); if (o.people > 64) usage('people is over 64'); }
    else if (a === '--serving') o.serving = next(P.buildId, 'the build served');
    else if (a === '--keep-build') o.keepBuild = true;
    else if (a === '--loaded') {
      var lb = next(P.buildId, 'a loaded build'), lp = parseInt(next(PEOPLE, 'its people'), 10), lc = parseInt(next(CONTEXT, 'its context'), 10);
      if (lp > 64 || lc > 1048576) usage('a loaded setting is over its ceiling');
      o.loaded.push({ build: lb, people: lp, context: lc });
    }
    else if (a === '--held') o.held.push(next(P.buildId, 'a held build'));
    else if (a === '--failed') o.failed.push(next(P.buildId, 'a failed build'));
    else if (a === '--ram') ram = parseInt(next(AU_CAP_FIGURE, 'the memory'), 10);
    else if (a === '--mac' || a === '--list-devices' || a === '--df' || a === '--disk') files[a.slice(2)] = next(null, a.slice(2));
    else usage('unknown option ' + (/^[-a-z]{1,20}$/.test(a) ? a : '(not shown)'));
  }
  if (o.keepBuild && !o.serving) usage('--keep-build needs --serving');

  var maxOf = { mac: AU_CAP_MAX.mac, 'list-devices': AU_CAP_MAX.listDevices, df: AU_CAP_MAX.df, disk: AU_CAP_MAX.disk }, got = {};
  for (var k in files) {
    got[k] = auCapReadFile(files[k], maxOf[k]);
    if (!got[k].ok && k !== 'mac') usage('cannot read the ' + k + ' file');
  }
  var mac = null, measured = { gpuMiB: null, gpuWhy: null, ramBytes: ram, diskFree: null, diskTotal: null, diskWhy: null };
  if (got.mac) mac = got.mac.ok ? auCapParseMac(got.mac.bytes, got.mac.big) : { state: 'absent' };
  if (got['list-devices']) {
    var ld = auCapListDevices(got['list-devices'].bytes, got['list-devices'].big);
    measured.gpuMiB = ld.gpuMiB; measured.gpuWhy = ld.why;
  }
  if (got.df) {
    var df = auCapDf(got.df.bytes, got.df.big);
    measured.diskFree = df.free; measured.diskTotal = df.total; measured.diskWhy = df.why;
  }
  if (got.disk) {
    o.holdings = auCapParseDisk(got.disk.bytes, got.disk.big);
    if (!o.holdings.ok) usage('the disk holdings are out of form');
  }
  o.figures = auCapFigures(ObjC.deepUnwrap($.NSProcessInfo.processInfo.environment), measured, mac);

  var reg = auRegRead(argv[0]);
  var r = auCapChoose(reg, argv[1], o);
  auWrite($.NSFileHandle.fileHandleWithStandardOutput, auCapReport(r).join('\n') + '\n');
  $.exit(r.ok ? 0 : 3);
}
