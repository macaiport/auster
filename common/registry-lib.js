// The registry reader (docs/plans/v0.1.md, A2 and A3), in JavaScript for Automation (BD17). It reads
// registry.tsv under A3's rules and gives the registry's half of D3.7: which builds a recipe has, in its
// order, and which of them the registry itself rules out (withdrawn, or a trust tier the recipe does not
// allow). Section C's fit, and the Mac's `hold` and `failed/`, come later through the judge hook below.
//
// Functions and vars only, no run(), and nothing runs when it is loaded. Load it with a direct eval in
// sloppy code, so that its declarations land in the caller's scope (that is why the top level holds no
// const or let):
//
//   ObjC.import('Foundation');
//   function auLoad(path) {
//     return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null));
//   }
//   eval(auLoad(dir + '/registry-lib.js'));
//
// What it gives:
//
//   auRegRead(path)              -> reg, or a reg with ok false. The only function here that touches the
//                                   disk: a link, anything but a regular file, or a file over 512 KiB is
//                                   not read at all (D3.1, A3).
//   auRegParse(bytes)            -> reg. `bytes` is the file as a byte string: one character a byte, codes
//                                   0 to 255 (the file decoded as ISO Latin 1), so that every limit is in
//                                   bytes and every raw line can be written back exactly.
//   auRegBuildsFor(reg, recipeId, judge)  -> the recipe's builds in order (also reg.buildsFor(recipeId, judge))
//   auRegFirstAppropriate(list)  -> the first entry of such a list with nothing against it, or null
//   auRegChoose(reg, recipeId, judge)     -> the build the recipe takes (D3.7), or null
//   auRegRecipeState(reg, recipeId)       -> 'ok', 'none', 'unreadable' or 'absent' (below)
//   auRegRecipeLine(reg, recipeId, servingId, judge) -> D3.7's rule against the build served (below)
//   auRegReport(reg, recipeId)   -> the lines common/registry.js prints (its header describes them)
//
// A line is passed over when it fails a pattern or a ceiling, and a `recipe` line also when it has no
// people or its minimum context is over its maximum (A3, settled at V2). The gate fails every such line.
//
// The object auRegParse returns. Every value in it has matched its pattern, except `raw`:
//
//   ok, reason      ok false: not read at all, and every recipe shows `passed over (cannot be read)`.
//                   reason is one of unreadable, too-large, not-a-registry, format, version
//   format, version, bytes          1, 'v0.1.0', the file's size in bytes
//   engines, models, builds         facts by id, from the lines that were read: each is
//                                   { kind, id, line, raw, extra, <one property a field> }, with the
//                                   fields named as AU_REG_KINDS names them; numbers and sizes are
//                                   Numbers, read in base 10, and the rest strings
//   recipes, orders                 by recipe id, the latest `recipe` line read and the latest `order`
//                                   line read: an order is { recipe, builds: [build ids], line, raw }
//   withdrawn                       by build id: { build, reason, known, line, raw }; known says whether
//                                   the reason is one A3 lists. Only the first withdrawal of a build counts
//   passed          every line passed over, in file order: { line, recipes: [recipe ids], reason }.
//                   recipes are those the line belongs to, when they can be told (a build belongs to the
//                   recipes whose order lines name it, an engine or model to its builds' recipes); the
//                   reason is a short sentence of the reader's own, never text from the registry
//   recipeIds       every recipe id a recipe or order line names, read or passed over, first seen first
//   lines           every line, from 1: { n, raw, kind, fields, accepted, reason, extra }. kind is '#'
//                   for a comment, fields null for one; extra counts the fields kept and not read
//
// raw is the line's own bytes, without its newline, as a byte string; write it with
// NSISOLatin1StringEncoding to get the bytes back (a descriptor copies the build, engine and model lines
// this way, T55). A line that is read holds no control character and is UTF-8, so a field after the last
// this version knows may hold any other text.
//
// A build list entry (auRegBuildsFor):
//
//   { id, position, build, engine, model, tier, tierAllowed, withdrawn, why, appropriate }
//
// position counts from 1 in the recipe's latest order line; build, engine and model are the facts; tier is
// the model line's (T53); withdrawn is the withdrawal or null; why lists what rules the build out, as
// codes, and appropriate is why being empty. The registry adds `withdrawn` and `tier`.
//
// The judge hook. auRegBuildsFor(reg, recipeId, judge) calls judge(entry) for each entry, after the
// registry's own codes are in entry.why, and appends what it returns (an array of codes, or nothing).
// Later steps give the codes the registry cannot: `held` (the recipe's `hold`, U6), `failed` (a
// descriptor in `failed/`, BD12: common/auster's au_entry_read reads one since U2, and U3 and U5 give
// the code at an update), `fit` (section C says it does not fit, V3) and `room` (it fits
// in memory but not on disk, C6). Without a judge, appropriate means appropriate as far as the registry
// knows. auRegRecipeLine reads `fit` on the build served: a later build is offered when the one served
// no longer fits (D3.7).
//
// A recipe's state (auRegRecipeState): 'absent' when no recipe or order line names it at all; 'unreadable'
// when no `recipe` line or no `order` line for it was read, or the registry was not read; 'none' when its
// order names builds and the registry rules out every one; 'ok' otherwise. A caller shows both 'absent'
// and 'unreadable' as `passed over (cannot be read)` for a recipe this Mac serves (D3.3).
//
// auRegRecipeLine(reg, recipeId, servingId, judge) -> { state, pick, serving, servingWithdrawn, reasons }:
// D3.7's "which build a recipe takes" against the build served. pick is the build the recipe takes: the
// first appropriate build, except that a build after the one served is never offered unless the one
// served is withdrawn or said not to fit, and then pick is the one served. state is 'same' when pick is
// the build served; 'waiting' when another build is picked; 'withdrawn' when the
// build served is withdrawn and nothing else is appropriate; 'passed over' when nothing is appropriate,
// with reasons listing the codes against each build; or the recipe's state when that is 'unreadable' or
// 'absent'. servingWithdrawn is the withdrawal of the build served, whatever the state, so that `auster
// status` can say so until the recipe serves something else (D3.8). With servingId null (a first install)
// state is 'waiting' when a build is picked.

var AU_REG_MAX = 524288;      // A3: 512 KiB in all. A file over it is not read at all
var AU_REG_LINE_MAX = 1000;   // A3: bytes a line, its newline not counted

// A2 and A3, one pattern a field
var AU_REG_PATTERNS = {
  recipeId: /^r[a-z2-7]{12}$/,
  buildId: /^b[a-z2-7]{12}$/,
  engineId: /^e[a-z2-7]{12}$/,
  modelId: /^m[a-z2-7]{12}$/,
  label: /^[a-z][a-z0-9-]{1,40}$/,
  tiers: /^(publisher|endorsed|third-party)(,(publisher|endorsed|third-party))*$/,
  tier: /^(publisher|endorsed|third-party)$/,
  number: /^(0|[1-9][0-9]{0,8})$/,
  size: /^(0|[1-9][0-9]{0,14})$/,
  platform: /^macos-arm64$/,
  numberedBuild: /^b[0-9]{4,7}$/,
  engineFile: /^llama-b[0-9]{4,7}-bin-macos-arm64\.(tar\.gz|zip)$/,
  repository: /^[A-Za-z0-9][A-Za-z0-9._-]{0,95}\/[A-Za-z0-9][A-Za-z0-9._-]{0,95}$/,
  commit: /^[0-9a-f]{40}$/,
  modelFile: /^[A-Za-z0-9][A-Za-z0-9._-]{0,200}\.gguf$/,
  sha256: /^[0-9a-f]{64}$/,
  licence: /^[a-z0-9.-]{2,30}$/,
  fraction: /^(0(\.[0-9]{1,3})?|1(\.0{1,3})?)$/,
  reason: /^[a-z]{1,20}$/,
  version: /^v(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$/
};

var AU_REG_CEILINGS = { people: 64, context: 1048576, mib: 1048576, cache: 4194304, macos: 99 };

var AU_REG_REASONS = ['security', 'egress', 'quality', 'licence', 'publisher', 'superseded', 'corrected'];

// The record kinds of A3: each field as [name, pattern, ceiling]. An order line is a recipe id and then
// `each` build ids, from one to `most`
var AU_REG_KINDS = {
  engine: { family: 'fact', fields: [
    ['id', 'engineId'], ['platform', 'platform'], ['numberedBuild', 'numberedBuild'], ['file', 'engineFile'],
    ['size', 'size'], ['sha256', 'sha256'], ['macos', 'number', 'macos']] },
  model: { family: 'fact', fields: [
    ['id', 'modelId'], ['repository', 'repository'], ['commit', 'commit'], ['file', 'modelFile'],
    ['size', 'size'], ['sha256', 'sha256'], ['licence', 'licence'], ['tier', 'tier'],
    ['contextLimit', 'number', 'context']] },
  build: { family: 'fact', fields: [
    ['id', 'buildId'], ['engine', 'engineId'], ['model', 'modelId'], ['template', 'sha256'],
    ['systemPrompt', 'sha256'], ['test', 'sha256'], ['weightsMiB', 'number', 'mib'],
    ['buffersMiB', 'number', 'mib'], ['outsideMiB', 'number', 'mib'], ['cachePerToken', 'number', 'cache'],
    ['temperature', 'fraction'], ['topP', 'fraction'], ['macLabel', 'label']] },
  recipe: { family: 'judgement', fields: [
    ['id', 'recipeId'], ['label', 'label'], ['tiers', 'tiers'], ['people', 'number', 'people'],
    ['contextMin', 'number', 'context'], ['contextMax', 'number', 'context']] },
  order: { family: 'judgement', fields: [['recipe', 'recipeId']], each: ['build', 'buildId'], most: 64 },
  withdraw: { family: 'fact', fields: [['build', 'buildId'], ['reason', 'reason']] }
};

function auRegNum(v) { // a field that matched `number` or `size`: base 10 always (A3)
  return parseInt(v, 10);
}

function auRegCount(kind) { // -> [fewest, most] fields a line of this kind has, its kind among them
  var k = AU_REG_KINDS[kind];
  if (k.each) return [k.fields.length + 2, k.fields.length + 1 + k.most];
  return [k.fields.length + 1, k.fields.length + 1];
}

function auRegCheckField(spec, v) { // -> null when the value is good, else what is wrong with it
  if (v === '') return 'is empty';
  if (!AU_REG_PATTERNS[spec[1]].test(v)) return 'fails its pattern';
  if (spec[2] && auRegNum(v) > AU_REG_CEILINGS[spec[2]]) return 'is over its ceiling';
  return null;
}

function auRegUtf8(s) { // a byte string -> whether it is well-formed UTF-8
  var i = 0, n = s.length, c, need, min, cp;
  while (i < n) {
    c = s.charCodeAt(i++);
    if (c < 0x80) continue;
    if (c >= 0xc2 && c <= 0xdf) { need = 1; min = 0x80; cp = c & 0x1f; }
    else if (c >= 0xe0 && c <= 0xef) { need = 2; min = 0x800; cp = c & 0x0f; }
    else if (c >= 0xf0 && c <= 0xf4) { need = 3; min = 0x10000; cp = c & 0x07; }
    else return false;
    while (need-- > 0) {
      if (i >= n) return false;
      c = s.charCodeAt(i++);
      if ((c & 0xc0) !== 0x80) return false;
      cp = cp * 64 + (c & 0x3f);
    }
    if (cp < min || cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff)) return false;
  }
  return true;
}

function auRegPass(ln, reason) {
  ln.accepted = false;
  ln.reason = reason;
}

function auRegFact(ln) { // a line that was read -> its fact or judgement, with its fields named
  var k = AU_REG_KINDS[ln.kind], f = ln.fields, o = { kind: ln.kind, line: ln.n, raw: ln.raw, extra: ln.extra }, i;
  for (i = 0; i < k.fields.length; i++) {
    var spec = k.fields[i];
    o[spec[0]] = (spec[1] === 'number' || spec[1] === 'size') ? auRegNum(f[i + 1]) : f[i + 1];
  }
  if (k.each) {
    o.builds = [];
    for (i = k.fields.length + 1; i < f.length && i <= k.fields.length + k.most; i++)
      if (o.builds.indexOf(f[i]) < 0) o.builds.push(f[i]);
  }
  if (ln.kind === 'recipe') o.tiers = o.tiers.split(',');
  if (ln.kind === 'withdraw') o.known = AU_REG_REASONS.indexOf(o.reason) >= 0;
  return o;
}

function auRegCheckLine(ln, last) { // the checks a line takes on its own; sets ln.accepted or ln.reason
  var raw = ln.raw;
  if (raw.length > AU_REG_LINE_MAX) return auRegPass(ln, 'over 1000 bytes');
  if (ln.kind === '#') return;
  if (last) return auRegPass(ln, 'no newline at the end of the file');
  if (/[\x00-\x08\x0a-\x1f\x7f]/.test(raw)) return auRegPass(ln, 'holds a CR or another control character');
  if (!auRegUtf8(raw)) return auRegPass(ln, 'not UTF-8');
  if (raw === '') return auRegPass(ln, 'an empty line');
  var k = AU_REG_KINDS.hasOwnProperty(ln.kind) ? AU_REG_KINDS[ln.kind] : null;
  if (!k) return auRegPass(ln, 'a kind this version does not know');
  var count = auRegCount(ln.kind), f = ln.fields, i, bad;
  if (f.length < count[0]) return auRegPass(ln, 'too few fields (' + f.length + ' of ' + count[0] + ')');
  for (i = 1; i < f.length && i < count[1]; i++) {
    var spec = i <= k.fields.length ? k.fields[i - 1] : k.each;
    bad = auRegCheckField(spec, f[i]);
    if (bad) return auRegPass(ln, 'field ' + (i + 1) + ' (' + spec[0] + ') ' + bad);
  }
  if (ln.kind === 'recipe') {   // A3, settled at V2: at least one person, and the minimum context at most the maximum
    if (auRegNum(f[4]) < 1) return auRegPass(ln, 'field 5 (people) is 0: a recipe has at least one person');
    if (auRegNum(f[5]) > auRegNum(f[6])) return auRegPass(ln, 'field 6 (contextMin) is over field 7 (contextMax)');
  }
  ln.extra = Math.max(0, f.length - count[1]);
  ln.accepted = true;
}

function auRegIdOf(kind, f) { // the id a fact line defines, when its field matches the kind's id pattern
  var p = { engine: 'engineId', model: 'modelId', build: 'buildId' }[kind];
  return p && f && f.length > 1 && AU_REG_PATTERNS[p].test(f[1]) ? f[1] : null;
}

function auRegParse(bytes) {
  var reg = { ok: false, reason: null, format: null, version: null, bytes: bytes.length,
    engines: {}, models: {}, builds: {}, recipes: {}, orders: {}, withdrawn: {}, passed: [],
    recipeIds: [], lines: [] };
  reg.buildsFor = function (recipeId, judge) { return auRegBuildsFor(reg, recipeId, judge); };
  if (bytes.length > AU_REG_MAX) { reg.reason = 'too-large'; return reg; }
  var parts = bytes.split('\n');
  var terminated = parts[parts.length - 1] === '';
  if (terminated) parts.pop();

  // The first line: auster-registry, the format, the version. Fields after the version are not read
  var h = parts.length ? parts[0] : null, hf = h === null ? [] : h.split('\t');
  if (h === null || (parts.length === 1 && !terminated) || h.length > AU_REG_LINE_MAX ||
      /[\x00-\x08\x0a-\x1f\x7f]/.test(h) || !auRegUtf8(h) || hf.length < 3 || hf[0] !== 'auster-registry') {
    reg.reason = 'not-a-registry'; return reg;
  }
  if (hf[1] !== '1') { reg.reason = 'format'; return reg; }
  if (!AU_REG_PATTERNS.version.test(hf[2])) { reg.reason = 'version'; return reg; }
  reg.ok = true; reg.format = 1; reg.version = hf[2];
  reg.lines.push({ n: 1, raw: h, kind: 'auster-registry', fields: hf, accepted: true, reason: null, extra: hf.length - 3 });

  var i, ln, f, id;
  for (i = 1; i < parts.length; i++) {
    var raw = parts[i];
    ln = { n: i + 1, raw: raw, kind: raw.charAt(0) === '#' ? '#' : null, fields: null, accepted: false, reason: null, extra: 0 };
    if (ln.kind !== '#') { ln.fields = raw.split('\t'); ln.kind = ln.fields[0]; }
    auRegCheckLine(ln, i === parts.length - 1 && !terminated);
    reg.lines.push(ln);
  }

  // Facts: each id is defined once, by the first line that names it as its own; a later one is passed
  // over, and so is a line that names an id whose own line was passed over, or that no line defines
  var first = {};
  for (i = 1; i < reg.lines.length; i++) {
    ln = reg.lines[i]; id = auRegIdOf(ln.kind, ln.fields);
    if (id === null) continue;
    if (!(id in first)) first[id] = ln; else if (ln.accepted) auRegPass(ln, 'id defined twice (first on line ' + first[id].n + ')');
  }
  function named(kind, ref) { // -> null when ref is a fact that was read, else why not
    var map = { engine: reg.engines, model: reg.models, build: reg.builds }[kind];
    if (map.hasOwnProperty(ref)) return null;
    return 'names ' + kind + ' ' + ref + (first[ref] ? ', whose line was passed over' : ', which no line defines');
  }
  function each(kind, fn) {
    for (var j = 1; j < reg.lines.length; j++) if (reg.lines[j].accepted && reg.lines[j].kind === kind) fn(reg.lines[j]);
  }
  each('engine', function (l) { reg.engines[l.fields[1]] = auRegFact(l); });
  each('model', function (l) { reg.models[l.fields[1]] = auRegFact(l); });
  each('build', function (l) {
    var why = named('engine', l.fields[2]) || named('model', l.fields[3]);
    if (why) auRegPass(l, why); else reg.builds[l.fields[1]] = auRegFact(l);
  });
  each('withdraw', function (l) {
    var why = named('build', l.fields[1]);
    if (!why && reg.withdrawn[l.fields[1]]) why = 'build ' + l.fields[1] + ' already withdrawn on line ' + reg.withdrawn[l.fields[1]].line;
    if (why) auRegPass(l, why); else reg.withdrawn[l.fields[1]] = auRegFact(l);
  });
  var hasRecipe = {}, anyRecipe = {};
  for (i = 1; i < reg.lines.length; i++) {
    ln = reg.lines[i];
    if (ln.kind === 'recipe' && ln.fields.length > 1) { anyRecipe[ln.fields[1]] = true; if (ln.accepted) hasRecipe[ln.fields[1]] = true; }
  }
  each('order', function (l) {
    var r = l.fields[1], why = null, j;
    if (!hasRecipe[r]) why = 'names recipe ' + r + (anyRecipe[r] ? ', whose recipe lines were all passed over' : ', which no recipe line defines');
    var top = Math.min(l.fields.length, AU_REG_KINDS.order.most + 2);
    for (j = 2; !why && j < top; j++) why = named('build', l.fields[j]);
    if (why) auRegPass(l, why);
  });

  // Judgements: the latest line read for a recipe decides
  each('recipe', function (l) { var r = auRegFact(l); reg.recipes[r.id] = r; });
  each('order', function (l) { var o = auRegFact(l); reg.orders[o.recipe] = o; });

  // Which recipes each passed-over line belongs to, from every line whatever became of it
  var recipesOfBuild = {}, buildsOfPart = {}, seen = {};
  function add(map, key, v) { (map[key] = map[key] || []).indexOf(v) < 0 && map[key].push(v); }
  for (i = 1; i < reg.lines.length; i++) {
    f = reg.lines[i].fields;
    if (!f || f.length < 2) continue;
    if ((f[0] === 'recipe' || f[0] === 'order') && AU_REG_PATTERNS.recipeId.test(f[1]) && !seen[f[1]]) {
      seen[f[1]] = true; reg.recipeIds.push(f[1]);
    }
    if (f[0] === 'order' && AU_REG_PATTERNS.recipeId.test(f[1]))
      for (var j = 2; j < f.length; j++) if (AU_REG_PATTERNS.buildId.test(f[j])) add(recipesOfBuild, f[j], f[1]);
    if (f[0] === 'build' && AU_REG_PATTERNS.buildId.test(f[1]) && f.length > 3) {
      add(buildsOfPart, f[2], f[1]); add(buildsOfPart, f[3], f[1]);
    }
  }
  for (i = 1; i < reg.lines.length; i++) {
    ln = reg.lines[i];
    if (!ln.reason) continue;
    var rs = [], fl = ln.fields;
    if (fl && fl.length > 1) {
      if ((ln.kind === 'recipe' || ln.kind === 'order') && AU_REG_PATTERNS.recipeId.test(fl[1])) rs = [fl[1]];
      else if ((ln.kind === 'build' || ln.kind === 'withdraw') && AU_REG_PATTERNS.buildId.test(fl[1])) rs = (recipesOfBuild[fl[1]] || []).slice();
      else if ((ln.kind === 'engine' && AU_REG_PATTERNS.engineId.test(fl[1])) || (ln.kind === 'model' && AU_REG_PATTERNS.modelId.test(fl[1])))
        (buildsOfPart[fl[1]] || []).forEach(function (b) { (recipesOfBuild[b] || []).forEach(function (r) { if (rs.indexOf(r) < 0) rs.push(r); }); });
    }
    reg.passed.push({ line: ln.n, recipes: rs, reason: ln.reason });
  }
  return reg;
}

function auRegRead(path) {
  var none = function (why) { var r = auRegParse(''); r.reason = why; r.bytes = 0; return r; };
  var attrs = $.NSFileManager.defaultManager.attributesOfItemAtPathError(path, null);
  if (attrs.isNil() || ObjC.unwrap(attrs.objectForKey('NSFileType')) !== 'NSFileTypeRegular') return none('unreadable');
  if (attrs.fileSize > AU_REG_MAX) return none('too-large');
  var data = $.NSData.dataWithContentsOfFile(path);
  if (data.isNil()) return none('unreadable');
  if (data.length > AU_REG_MAX) return none('too-large');
  return auRegParse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSISOLatin1StringEncoding)) || '');
}

function auRegBuildsFor(reg, recipeId, judge) {
  var out = [];
  if (!reg.ok || !reg.recipes[recipeId] || !reg.orders[recipeId]) return out;
  var recipe = reg.recipes[recipeId];
  var ids = reg.orders[recipeId].builds;
  for (var i = 0; i < ids.length; i++) {
    if (!reg.builds.hasOwnProperty(ids[i])) continue;
    var b = reg.builds[ids[i]];
    var e = { id: b.id, position: out.length + 1, build: b, engine: reg.engines[b.engine], model: reg.models[b.model] };
    e.tier = e.model.tier;
    e.tierAllowed = recipe.tiers.indexOf(e.tier) >= 0;
    e.withdrawn = reg.withdrawn[b.id] || null;
    e.why = [];
    if (e.withdrawn) e.why.push('withdrawn');
    if (!e.tierAllowed) e.why.push('tier');
    if (judge) e.why = e.why.concat(judge(e) || []);
    e.appropriate = e.why.length === 0;
    out.push(e);
  }
  return out;
}

function auRegFirstAppropriate(list) {
  for (var i = 0; i < list.length; i++) if (list[i].appropriate) return list[i];
  return null;
}

function auRegChoose(reg, recipeId, judge) {
  return auRegFirstAppropriate(auRegBuildsFor(reg, recipeId, judge));
}

function auRegRecipeState(reg, recipeId) {
  if (!reg.ok) return 'unreadable';
  if (reg.recipeIds.indexOf(recipeId) < 0) return 'absent';
  if (!reg.recipes[recipeId] || !reg.orders[recipeId]) return 'unreadable';
  return auRegFirstAppropriate(auRegBuildsFor(reg, recipeId)) ? 'ok' : 'none';
}

function auRegRecipeLine(reg, recipeId, servingId, judge) {
  var out = { state: auRegRecipeState(reg, recipeId), pick: null, serving: null, servingWithdrawn: null, reasons: [] };
  if (servingId && reg.ok && reg.withdrawn[servingId]) out.servingWithdrawn = reg.withdrawn[servingId];
  if (out.state === 'unreadable' || out.state === 'absent') return out;
  var list = auRegBuildsFor(reg, recipeId, judge), s = null, i;
  for (i = 0; i < list.length; i++) if (list[i].id === servingId) s = list[i];
  var pick = auRegFirstAppropriate(list);
  out.pick = pick; out.serving = s;
  if (!pick) {
    out.state = out.servingWithdrawn ? 'withdrawn' : 'passed over';
    list.forEach(function (e) { e.why.forEach(function (w) { if (out.reasons.indexOf(w) < 0) out.reasons.push(w); }); });
  }
  else if (pick.id === servingId) out.state = 'same';
  else if (s && pick.position > s.position && !s.withdrawn && s.why.indexOf('fit') < 0) { out.state = 'same'; out.pick = s; }
  else out.state = 'waiting';
  return out;
}

function auRegReport(reg, recipeId) {
  var out = [], T = '\t';
  if (!reg.ok) {
    out.push('unread' + T + reg.reason);
    if (recipeId) out.push(['recipe', recipeId, 'unreadable', 0, '-', '-', '-', '-', '-'].join(T));
    return out;
  }
  out.push(['registry', reg.format, reg.version].join(T));
  function passedOf(r) { return reg.passed.filter(function (p) { return p.recipes.indexOf(r) >= 0; }); }
  function recipeLine(r) {
    var c = reg.recipes[r], st = auRegRecipeState(reg, r), n = passedOf(r).length;
    if (!c) return ['recipe', r, st, n, '-', '-', '-', '-', '-'].join(T);
    return ['recipe', r, st, n, c.label, c.tiers.join(','), c.people, c.contextMin, c.contextMax].join(T);
  }
  var K = AU_REG_KINDS;
  function fieldsOf(kind, o) { return K[kind].fields.map(function (s) { return String(o[s[0]]); }); }
  if (!recipeId) {
    reg.recipeIds.forEach(function (r) { out.push(recipeLine(r)); });
    reg.passed.forEach(function (p) { out.push(['passed', p.line, p.recipes.join(',') || '-', p.reason].join(T)); });
    return out;
  }
  out.push(recipeLine(recipeId));
  var list = auRegBuildsFor(reg, recipeId);
  list.forEach(function (e) {
    var w = e.withdrawn ? (e.withdrawn.known ? e.withdrawn.reason : 'other') : '-';
    out.push(['build', e.position, e.appropriate ? 'ok' : e.why.join(','), w]
      .concat(fieldsOf('build', e.build), fieldsOf('engine', e.engine), fieldsOf('model', e.model)).join(T));
  });
  list.forEach(function (e) {
    out.push(['raw', e.id, 'build', e.build.raw].join(T));
    out.push(['raw', e.id, 'engine', e.engine.raw].join(T));
    out.push(['raw', e.id, 'model', e.model.raw].join(T));
  });
  passedOf(recipeId).forEach(function (p) { out.push(['passed', p.line, p.recipes.join(','), p.reason].join(T)); });
  return out;
}
