// The JavaScript half of tools/check-registry (docs/plans/v0.1.md, A3 and D3.9). It reads the registry
// with common/registry-lib.js, the reader every Mac uses, and asks the questions that need the file's
// lines; tools/check-registry runs it and checks the assets. Run that, not this.
//
//   osascript -l JavaScript tools/check-registry.js <root> <registry.tsv> [--release FILE] [--tag vX.Y.Z]
//
// Output: `fail<TAB><what>` for each failure, and `asset<TAB><sha256><TAB><build id><TAB><what>` for
// each template, system prompt and test a build line names (template, system-prompt, test). Exit 0,
// or 2 for usage. A failure names line numbers, fields and ids that match their patterns, and never
// prints the registry's own text.
// U9 (2026-11-28): two more kinds, which tools/check-registry passes over and tools/release-gate reads (D3.9,
// T39), each from lines that were read, so every value has matched its pattern:
//   uses<TAB>engine<TAB><id><TAB><numbered build><TAB><file><TAB><size><TAB><sha256>
//   uses<TAB>model<TAB><id><TAB><repository><TAB><commit><TAB><file><TAB><size><TAB><sha256>
//       once each, for every engine and model that a build not withdrawn uses (the publisher's answer);
//   engine-of<TAB><build id><TAB><engine id>   for every build, withdrawn or not (an engine no released build used).
ObjC.import('Foundation');
ObjC.import('stdlib');

function auLoad(path) {
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
}

function run(argv) {
  var out = [], err = $.NSFileHandle.fileHandleWithStandardError;
  function usage() {
    err.writeData($('usage: check-registry.js <root> <registry.tsv> [--release FILE] [--tag vX.Y.Z]\n').dataUsingEncoding($.NSUTF8StringEncoding));
    $.exit(2);
  }
  if (argv.length < 2) usage();
  var lib = auLoad(argv[0] + '/common/registry-lib.js');
  if (typeof lib !== 'string') usage();
  eval(lib);
  var file = argv[1], release = null, tag = null, i;
  for (i = 2; i < argv.length; i += 2) {
    if (i + 1 >= argv.length) usage();
    if (argv[i] === '--release') release = argv[i + 1];
    else if (argv[i] === '--tag') tag = argv[i + 1];
    else usage();
  }
  function fail(what) { out.push('fail\t' + what); }
  function anyId(v) { return /^[rbemk][a-z2-7]{12}$/.test(v) ? v : 'an id'; }
  function finish() {
    if (out.length) $.NSFileHandle.fileHandleWithStandardOutput.writeData($(out.join('\n') + '\n').dataUsingEncoding($.NSUTF8StringEncoding));
    $.exit(0);
  }
  var NAMES = { unreadable: 'cannot be read (missing, a link, or not a regular file)', 'too-large': 'is over 512 KiB (524,288 bytes)',
    'not-a-registry': 'does not begin with a whole line `auster-registry<TAB>1<TAB>v<a>.<b>.<c>`',
    format: 'is not in format 1', version: 'has a version that fails its pattern' };

  var reg = auRegRead(file);
  if (!reg.ok) { fail('the registry ' + NAMES[reg.reason] + ', so no Mac reads it'); finish(); }

  // Each line: what a Mac passes over fails here too, and so does a field a Mac would keep and not read
  if (reg.lines[0].fields.length !== 3) fail('line 1: ' + reg.lines[0].fields.length + ' fields, the first line has 3');
  for (i = 1; i < reg.lines.length; i++) {
    var ln = reg.lines[i];
    if (ln.reason && ln.reason.indexOf('id defined twice') !== 0) fail('line ' + ln.n + ': ' + ln.reason);
    else if (ln.accepted && ln.extra > 0) {
      var c = auRegCount(ln.kind);
      fail('line ' + ln.n + ': too many fields (' + ln.fields.length + ' of ' + (c[0] === c[1] ? '' : 'at most ') + c[1] + ')');
    }
  }

  // No id defined twice, whatever the kinds of the two lines
  var first = {};
  for (i = 1; i < reg.lines.length; i++) {
    var f = reg.lines[i].fields;
    if (!f || f.length < 2 || !AU_REG_KINDS.hasOwnProperty(f[0]) || AU_REG_KINDS[f[0]].family !== 'fact' || f[0] === 'withdraw') continue;
    var key = f[1];
    if (key in first) fail('line ' + reg.lines[i].n + ': ' + anyId(f[1]) + ' defined twice (first on line ' + first[key] + ')');
    else first[key] = reg.lines[i].n;
  }

  // Every order names builds of its own recipe: a build in no other recipe's order, and named once
  var recipeOfBuild = {};
  for (i = 1; i < reg.lines.length; i++) {
    ln = reg.lines[i];
    if (!ln.accepted || ln.kind !== 'order') continue;
    var o = auRegFact(ln), named = {};
    for (var j = 2; j < ln.fields.length && j < auRegCount('order')[1]; j++) {
      var b = ln.fields[j];
      if (named[b]) fail('line ' + ln.n + ': names build ' + b + ' twice');
      named[b] = true;
      if (recipeOfBuild[b] && recipeOfBuild[b].recipe !== o.recipe)
        fail('line ' + ln.n + ': build ' + b + ' is already in the order of recipe ' + recipeOfBuild[b].recipe + ' (line ' + recipeOfBuild[b].line + ')');
      else if (!recipeOfBuild[b]) recipeOfBuild[b] = { recipe: o.recipe, line: ln.n };
    }
  }

  if (tag !== null) {
    if (!AU_REG_PATTERNS.version.test(tag)) fail('the tag is not of the form vX.Y.Z');
    else if (reg.version !== tag) fail('line 1: the version ' + reg.version + ' is not the tag ' + tag);
    if (reg.format !== 1) fail('line 1: the format is not 1');
  }

  if (release !== null) {
    var old = auRegRead(release);
    if (!old.ok) fail('the release\'s registry ' + NAMES[old.reason]);
    else {
      var vn = reg.version.slice(1).split('.'), vo = old.version.slice(1).split('.'), newer = false;
      for (i = 0; i < 3; i++) {
        if (auRegNum(vn[i]) !== auRegNum(vo[i])) { newer = auRegNum(vn[i]) > auRegNum(vo[i]); break; }
      }
      if (!newer) fail('line 1: the version ' + reg.version + ' is not newer than the release\'s ' + old.version);
      var records = function (r) { return r.lines.filter(function (l) { return l.n > 1 && l.kind !== '#'; }); };
      var was = records(old), now = records(reg), at = 0, matched = {};
      was.forEach(function (w) {
        for (var k = at; k < now.length; k++) if (now[k].raw === w.raw) { matched[now[k].n] = true; at = k + 1; return; }
        var what = AU_REG_KINDS.hasOwnProperty(w.kind) && w.fields.length > 1 ? w.kind + ' ' + anyId(w.fields[1]) : 'a record';
        fail('line ' + w.n + ' of the release (' + what + ') is missing, changed or moved');
      });
      // A later judgement is added below the earlier ones for its recipe, never above
      now.forEach(function (l, k) {
        if (matched[l.n] || (l.kind !== 'recipe' && l.kind !== 'order') || l.fields.length < 2) return;
        for (var m = k + 1; m < now.length; m++)
          if (matched[now[m].n] && now[m].kind === l.kind && now[m].fields[1] === l.fields[1]) {
            fail('line ' + l.n + ': a new ' + l.kind + ' line above the release\'s line ' + now[m].n + ' for the same recipe');
            return;
          }
      });
    }
  }

  // The assets a build names, for tools/check-registry to find by hash
  for (i = 1; i < reg.lines.length; i++) {
    f = reg.lines[i].fields;
    if (!f || f[0] !== 'build' || f.length < 7 || !AU_REG_PATTERNS.buildId.test(f[1])) continue;
    [['template', 4], ['system-prompt', 5], ['test', 6]].forEach(function (a) {
      if (AU_REG_PATTERNS.sha256.test(f[a[1]])) out.push(['asset', f[a[1]], f[1], a[0]].join('\t'));
    });
  }

  // For tools/release-gate (U9): the files each build uses, and each build's engine
  var told = {};
  Object.keys(reg.builds).forEach(function (b) {
    var bl = reg.builds[b], e = reg.engines[bl.engine], m = reg.models[bl.model];
    out.push(['engine-of', b, bl.engine].join('\t'));
    if (reg.withdrawn.hasOwnProperty(b)) return;
    if (!told[e.id]) { told[e.id] = true; out.push(['uses', 'engine', e.id, e.numberedBuild, e.file, e.size, e.sha256].join('\t')); }
    if (!told[m.id]) { told[m.id] = true; out.push(['uses', 'model', m.id, m.repository, m.commit, m.file, m.size, m.sha256].join('\t')); }
  });
  finish();
}
