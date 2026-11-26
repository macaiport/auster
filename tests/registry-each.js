// Test helper for the registry tests: what common/registry.js prints, for many registry files in one start
// of osascript (each start costs about 0.1 s). It loads the same library and prints the same report.
//
//   osascript -l JavaScript tests/registry-each.js <root> <recipe id, or -> <registry.tsv>...
//
// For each file: a line `file<TAB><path>`, then the lines registry.js prints for it, then `exit<TAB>0`
// when it was read or `exit<TAB>3` when it was not.
ObjC.import('Foundation');

function auLoad(path) {
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
}

function run(argv) {
  eval(auLoad(argv[0] + '/common/registry-lib.js'));
  var recipe = argv[1] === '-' ? null : argv[1], out = [];
  for (var i = 2; i < argv.length; i++) {
    var reg = auRegRead(argv[i]);
    out.push('file\t' + argv[i]);
    out = out.concat(auRegReport(reg, recipe));
    out.push('exit\t' + (reg.ok ? 0 : 3));
  }
  $.NSFileHandle.fileHandleWithStandardOutput.writeData($(out.join('\n') + '\n').dataUsingEncoding($.NSISOLatin1StringEncoding));
}
