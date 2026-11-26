// The registry reader's command line (docs/plans/v0.1.md, A3), for bash callers. It loads
// registry-lib.js from its own folder; the rules are there.
//
//   osascript -l JavaScript common/registry.js <registry.tsv> [recipe id]
//
// Exit codes: 0 the registry was read; 3 it was not read at all (a missing or unreadable file, a link,
// anything but a regular file, over 512 KiB, a first line that is not `auster-registry`, a format other
// than 1, a version that fails its pattern), so that every recipe shows `passed over (cannot be read)`;
// 2 usage (no file, more than two arguments, a recipe id that fails its pattern); 1 this program failed.
//
// Output, on standard output: one record a line, fields separated by single tabs, the line's kind first.
// Every value printed has matched its pattern, except the line in `raw`, which is the registry's own
// bytes. This form is a contract with callers built by other versions: a later version may add kinds
// of line, or fields at the end of a line, and never changes or removes one.
//
//   unread    <reason>                 exit 3 only, first. reason: unreadable, too-large,
//                                      not-a-registry, format, version
//   registry  <format> <version>       exit 0 only, first: 1 and v0.1.0
//   recipe    <recipe id> <state> <passed> <label> <tiers> <people> <context min> <context max>
//             state: ok, none, unreadable or absent (registry-lib.js says what each means); passed:
//             how many lines passed over belong to it; label to context max are its latest `recipe`
//             line's fields, or - each when no recipe line of it was read. With exit 3 and a recipe id,
//             that recipe is printed as unreadable
//   build     <position> <verdict> <withdrawal> <13 build fields> <7 engine fields> <9 model fields>
//             position counts from 1 in the recipe's latest `order` line. verdict is ok, or what the
//             registry rules out, comma-separated: withdrawn, tier. withdrawal is the reason when it is
//             one A3 lists, `other` for any other reason, and - when the build is not withdrawn. Then
//             the build line's fields 2 to 14 (fields 5 to 17 here), the engine line's 2 to 8 (18 to 24)
//             and the model line's 2 to 10 (25 to 33), as the registry gives them, numbers in base 10
//   raw       <build id> <build|engine|model> <the line>
//             the registry line of that build, its engine or its model, byte for byte, fields after the
//             last this version knows included (T55). The line is everything after the third tab
//   passed    <line number> <recipe ids> <reason>
//             a line passed over: the recipes it belongs to, comma-separated, or - when that cannot be
//             told; the reason is a short sentence of the reader's own
//
// With no recipe id: `registry`, then a `recipe` line for every recipe id that a recipe or order line
// names, first seen first, then every `passed` line. With a recipe id: `registry`, that recipe's
// `recipe` line, its `build` lines in order, three `raw` lines for each build in the same order, then
// the `passed` lines that belong to it.
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
  var lib = auLoad(dir + '/registry-lib.js');
  if (typeof lib !== 'string') { auWrite(err, 'registry.js: cannot read ' + dir + '/registry-lib.js\n'); $.exit(1); }
  eval(lib);
  if (argv.length < 1 || argv.length > 2 || (argv.length === 2 && !AU_REG_PATTERNS.recipeId.test(argv[1]))) {
    auWrite(err, 'usage: osascript -l JavaScript registry.js <registry.tsv> [recipe id]\n');
    $.exit(2);
  }
  var reg = auRegRead(argv[0]);
  var lines = auRegReport(reg, argv.length === 2 ? argv[1] : null);
  auWrite($.NSFileHandle.fileHandleWithStandardOutput, lines.join('\n') + '\n');
  $.exit(reg.ok ? 0 : 3);
}
