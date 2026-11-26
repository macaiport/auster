// The recipe's test (docs/plans/v0.1.md, A7), in JavaScript for Automation (BD17). Tested by T58 to T60.
//
//   osascript -l JavaScript common/recipe-test.js <test file> <base URL> <key file> [system prompt file]
//
// It asks each question of the test file of <base URL>/v1/chat/completions, at temperature 0, with curl,
// grades the answers by the rules of scripts/phase-1/quiz.py (grade-lib.js, beside this file), asks the
// speed question (A5) last, and prints the result. The base URL is http(s)://host[:port], with no path.
// The key file's first line that is not blank or a # comment is the key; it is sent in a header read
// from a file of mode 0600 in a fresh folder of mode 0700, which is deleted at the end, and never
// appears on a command line. A system prompt file, when given and not empty, is sent before each
// question, as quiz.py sends it; the speed question is sent alone, as A5 defines it.
//
// The caller starts the engine and waits until it listens (/health 200) before running this. The test
// itself never asks /health and trusts nothing from it: a server whose /health answers 200 and whose
// questions answer HTTP 500 fails. Its clock is `date +%s`, read from the first question to the speed
// question's answer. A question is not asked once that time is over the limit.
//
// Output, on standard output, one line per question in the file's order, then two lines:
//   Q<NN> <PASS|FAIL> <mandatory|optional> <group>: <what happened>
//       what happened: "answered in S s | <the reply's last line, 60 characters at most, with control
//       and format characters shown as ?>", "HTTP <code> in S s", "an answer that cannot be read, in
//       S s", "no answer in S s (curl exit N)", or "not asked, out of time"
//   speed <rate> tok/s (reported only: it never decides the result)
//   speed none (<why>)
//   result <pass|fail|none> <passed>/<questions> mandatory <passed>/<mandatory> secs <elapsed>/<limit>
// The speed is the rate the engine reports for the speed question (timings.predicted_per_second). It is
// the test's own, taken at whatever setting the test ran at; it is not this Mac's baseline (A5, B3 step
// 13), and nothing here writes it anywhere. This program writes no file outside its temporary folder.
//
// Exit codes, with the result line: 0 pass; 1 fail; 3 none (no question had any HTTP answer, such as
// connection refused). Exit 2, with a sentence on standard error and no result line: a usage error, or a
// test that could not be run (its file, the key, the system prompt, a temporary folder, the clock). A
// caller takes a pass only from exit 0 together with a final line that starts "result pass".
//
// The test file, format 1 (tests/fixtures/recipe-test/household-test.json is the household's), is one
// JSON object with exactly these keys, any other key or form refusing the file (exit 2):
//   "auster-test"  1
//   "note"         optional text for people; not read
//   "house_note"   optional text put in place of each {note} in a question (as in questions.json)
//   "temperature"  0, as A7 fixes it; any other value refuses the file
//   "max_tokens"   an integer from 1 to 32768, for each graded question (quiz.py sent 1200)
//   "pass"         {"at_least": N, "within_secs": S}: every mandatory question passes, at least N of
//                  the questions pass, and the whole run, the speed question with it, ends within S
//                  seconds; N from 1 to the number of questions, S from 1 to 3600
//   "questions"    1 to 100 questions, each an object with:
//       "group"      lower-case letters, 1 to 20
//       "mandatory"  true or false, always given
//       "q"          the question; "{note}" is replaced by the house note
//       "kind", "want", "tol", "tail"  as in scripts/phase-1/questions.json; "tail" adds the line that
//                  asks for "Answer: <answer>"; a pattern ("re", "re_full") uses what grade-lib.js
//                  translates from Python's re exactly, and a pattern it cannot translate refuses the file
//       "phase1"     optional: the question's number in phase 1's questions.json; not read
//   "speed"        {"q": the speed question, "max_tokens": 128 for A5's, "temperature": 0}; not graded
ObjC.import('Foundation');
ObjC.import('stdlib');

function auLoad(p) { // a UTF-8 text file -> its text, or null
  var s = $.NSString.stringWithContentsOfFileEncodingError(p, $.NSUTF8StringEncoding, null);
  return s.isNil() ? null : ObjC.unwrap(s);
}

function auSelfDir() { // the folder this program is in, out of osascript's own arguments
  var a = ObjC.deepUnwrap($.NSProcessInfo.processInfo.arguments), i, p = '';
  for (i = 1; i < a.length; i++) {
    if (a[i] === '-l' || a[i] === '-s') { i++; continue; }
    if (a[i] === '-i') continue;
    p = a[i]; break;
  }
  if (p.charAt(0) !== '/') p = ObjC.unwrap($.NSFileManager.defaultManager.currentDirectoryPath) + '/' + p;
  return ObjC.unwrap($(p).stringByDeletingLastPathComponent);
}

var AU_GRADER = auLoad(auSelfDir() + '/grade-lib.js');
if (AU_GRADER !== null) eval(AU_GRADER);   // Auster's own grade-lib.js, beside this file
var AU_TMP = null;

function auWrite(fh, s) { fh.writeData($(s).dataUsingEncoding($.NSUTF8StringEncoding)); }
function auSay(s) { auWrite($.NSFileHandle.fileHandleWithStandardOutput, s + '\n'); }
function auWarn(s) { auWrite($.NSFileHandle.fileHandleWithStandardError, 'recipe-test: ' + s + '\n'); }

function auTask(args) { // runs args[0], found on PATH, with no shell -> {status, out}
  var t = $.NSTask.alloc.init, p = $.NSPipe.pipe;
  t.launchPath = '/usr/bin/env';
  t.arguments = args;
  t.standardInput = $.NSFileHandle.fileHandleWithNullDevice;
  t.standardOutput = p;
  t.standardError = $.NSFileHandle.fileHandleWithNullDevice;
  t.launch;
  var d = p.fileHandleForReading.readDataToEndOfFile;
  while (t.running) $.NSThread.sleepForTimeInterval(0.002);   // waitUntilExit costs some 60 ms a call
  var s =$.NSString.alloc.initWithDataEncoding(d, $.NSUTF8StringEncoding);
  return { status: t.terminationStatus, out: s.isNil() ? '' : ObjC.unwrap(s) };
}

function auNow() { // seconds, by `date +%s`, so that a test's stub clock governs it
  var r = auTask(['date', '+%s']), s = r.out.replace(/\n$/, '');
  if (r.status !== 0 || !/^[0-9]+$/.test(s)) throw new Error('date +%s gave no time');
  return Number(s);
}

function auInt(v, lo, hi) { return typeof v === 'number' && Math.floor(v) === v && v >= lo && v <= hi; }

function auKeys(o, what, required, optional) { // o must be an object holding these keys and no others
  if (o === null || typeof o !== 'object' || Array.isArray(o)) throw new Error(what + ' is not an object');
  Object.keys(o).forEach(function (k) {
    if (required.indexOf(k) < 0 && optional.indexOf(k) < 0) throw new Error(what + ' has a key it may not have: ' + JSON.stringify(k));
  });
  required.forEach(function (k) {
    if (!Object.prototype.hasOwnProperty.call(o, k)) throw new Error(what + ' has no ' + JSON.stringify(k));
  });
}

function auReadTest(path) { // the test file -> the test, or throws a sentence
  var text = auLoad(path), t;
  if (text === null) throw new Error('cannot read the test file ' + path);
  try { t = JSON.parse(text); } catch (e) { throw new Error('the test file is not JSON'); }
  auKeys(t, 'the test file', ['auster-test', 'temperature', 'max_tokens', 'pass', 'questions', 'speed'], ['note', 'house_note']);
  if (t['auster-test'] !== 1) throw new Error('the test file is format ' + JSON.stringify(t['auster-test']) + ', not 1');
  if (t.note !== undefined && typeof t.note !== 'string') throw new Error('the test file\'s note is not text');
  if (t.house_note !== undefined && typeof t.house_note !== 'string') throw new Error('the test file\'s house note is not text');
  if (t.temperature !== 0) throw new Error('the test file asks for temperature ' + JSON.stringify(t.temperature) + '; the recipe\'s test runs at 0');
  if (!auInt(t.max_tokens, 1, 32768)) throw new Error('the test file\'s max_tokens is not from 1 to 32768');
  if (!Array.isArray(t.questions) || t.questions.length < 1 || t.questions.length > 100) throw new Error('the test file needs 1 to 100 questions');
  t.questions.forEach(function (q, i) { auCheckQuestion(q, 'question ' + (i + 1)); });
  auKeys(t.pass, 'the pass rule', ['at_least', 'within_secs'], []);
  if (!auInt(t.pass.at_least, 1, t.questions.length)) throw new Error('the pass rule\'s at_least is not from 1 to the number of questions');
  if (!auInt(t.pass.within_secs, 1, 3600)) throw new Error('the pass rule\'s within_secs is not from 1 to 3600');
  auKeys(t.speed, 'the speed question', ['q', 'max_tokens', 'temperature'], []);
  if (typeof t.speed.q !== 'string' || t.speed.q === '') throw new Error('the speed question has no text');
  if (!auInt(t.speed.max_tokens, 1, 32768)) throw new Error('the speed question\'s max_tokens is not from 1 to 32768');
  if (t.speed.temperature !== 0) throw new Error('the speed question asks for temperature ' + JSON.stringify(t.speed.temperature) + '; A5 fixes 0');
  return t;
}

function auCheckQuestion(q, what) { // one question's form, as auGrade reads it
  auKeys(q, what, ['group', 'mandatory', 'q', 'kind'], ['phase1', 'want', 'tol', 'tail']);
  if (typeof q.group !== 'string' || !/^[a-z]{1,20}$/.test(q.group)) throw new Error(what + '\'s group is not 1 to 20 lower-case letters');
  if (typeof q.mandatory !== 'boolean') throw new Error(what + '\'s mandatory is not true or false');
  if (typeof q.q !== 'string' || q.q === '') throw new Error(what + ' has no text');
  if (q.phase1 !== undefined && !auInt(q.phase1, 1, 1000000)) throw new Error(what + '\'s phase1 is not a question number');
  if (q.tail !== undefined && typeof q.tail !== 'boolean') throw new Error(what + '\'s tail is not true or false');
  if (q.tol !== undefined && (q.kind !== 'num' || typeof q.tol !== 'number' || !(q.tol >= 0))) throw new Error(what + '\'s tol is not a number for a num question');
  var w = q.want, ok;
  switch (q.kind) {
    case 'exact': case 'upper': case 'time': case 'yesno': case 'word': ok = typeof w === 'string' && w !== ''; break;
    case 'three': ok = w === undefined; break;
    case 'json': ok = Array.isArray(w) && w.length > 0 && w.every(function (k) { return typeof k === 'string'; }); break;
    case 'maxwords': ok = Array.isArray(w) && w.length === 2 && auInt(w[0], 1, 1000) && typeof w[1] === 'string' && w[1] !== ''; break;
    case 'num': ok = typeof w === 'number' && isFinite(w); break;
    case 're': case 're_full':
      ok = typeof w === 'string' && w !== '';
      if (ok) {
        try { new RegExp(auPyRe(w), 'u'); } catch (e) { throw new Error(what + '\'s pattern cannot be used: ' + e.message); }
      }
      break;
    default: throw new Error(what + '\'s kind is not one the grader knows: ' + JSON.stringify(q.kind));
  }
  if (!ok) throw new Error(what + '\'s want is not of the form its kind ' + q.kind + ' needs');
}

function auBaseUrl(s) { // http(s)://host[:port], one trailing / allowed -> the URL of chat completions
  var u = s.replace(/\/$/, '');
  if (!/^https?:\/\/([A-Za-z0-9.-]+|\[[0-9A-Fa-f:.]+\])(:[0-9]{1,5})?$/.test(u)) throw new Error('the base URL is not http(s)://host[:port]');
  return u + '/v1/chat/completions';
}

function auReadKey(path) { // the first line of the key file that is a key; the key is never printed
  var text = auLoad(path), lines, i, k;
  if (text === null) throw new Error('cannot read the key file ' + path);
  lines = text.split('\n');
  for (i = 0; i < lines.length; i++) {
    k = lines[i].replace(/^[ \t\r]+|[ \t\r]+$/g, '');
    if (k === '' || k.charAt(0) === '#') continue;
    if (!/^[\x21-\x7e]+$/.test(k)) throw new Error('the key file\'s key is not printable ASCII');
    return k;
  }
  throw new Error('the key file holds no key');
}

function auTempDir() { // a fresh folder of mode 0700 in TMPDIR (mktemp -d)
  var env = ObjC.deepUnwrap($.NSProcessInfo.processInfo.environment);
  var base = (env.TMPDIR || '/tmp').replace(/\/+$/, '');
  var r = auTask(['mktemp', '-d', base + '/auster-test.XXXXXX']), d = r.out.replace(/\n$/, '');
  if (r.status !== 0 || d === '') throw new Error('cannot make a temporary folder in ' + (base || '/'));
  return d;
}

function auAsk(ctx, messages, maxTokens, maxTime) { // one request -> {kind: answer|http|unreadable|none, ...}
  var req = AU_TMP + '/request.json', ans = AU_TMP + '/answer.json', fm = $.NSFileManager.defaultManager;
  var body = JSON.stringify({ messages: messages, temperature: 0, max_tokens: maxTokens });
  if (!$(body).writeToFileAtomicallyEncodingError(req, true, $.NSUTF8StringEncoding, null)) throw new Error('cannot write ' + req);
  fm.removeItemAtPathError(ans, null);
  var r = auTask(['curl', '-q', '-s', '-o', ans, '-w', '%{http_code}', '--max-time', String(maxTime),
    '-H', 'Content-Type: application/json', '-H', '@' + ctx.header, '--data-binary', '@' + req, ctx.url]);
  if (r.status !== 0 || !/^[1-5][0-9][0-9]$/.test(r.out)) return { kind: 'none', curl: r.status };
  if (r.out !== '200') return { kind: 'http', code: r.out };
  var text = auLoad(ans), d, m, rate = null;
  if (text === null) return { kind: 'unreadable' };
  try { d = JSON.parse(text); } catch (e) { return { kind: 'unreadable' }; }
  m = d && d.choices && d.choices[0] && d.choices[0].message;
  if (!m || typeof m !== 'object') return { kind: 'unreadable' };
  if (d.timings && typeof d.timings.predicted_per_second === 'number' && isFinite(d.timings.predicted_per_second)) rate = d.timings.predicted_per_second;
  return { kind: 'answer', text: typeof m.content === 'string' ? m.content : '', rate: rate };
}

function auExcerpt(text) { // quiz.py's last line, at most 60 characters, nothing that steers a terminal
  var s = auPyStrip(text);
  if (s === '') return '(empty)';
  var lines = s.split(/\r\n|[\n\r\v\f\x1c-\x1e\x85\u2028\u2029]/);
  return Array.from(lines[lines.length - 1]).slice(0, 60).join('').replace(/[\p{C}]/gu, '?');
}

function auMain(argv) {
  if (argv.length < 3 || argv.length > 4) {
    auWarn('usage: osascript -l JavaScript recipe-test.js <test file> <base URL> <key file> [system prompt file]');
    return 2;
  }
  if (AU_GRADER === null) { auWarn('cannot read grade-lib.js beside this program'); return 2; }
  var test, url, key, system = '';
  try {
    test = auReadTest(argv[0]);
    url = auBaseUrl(argv[1]);
    key = auReadKey(argv[2]);
    if (argv.length === 4) {
      system = auLoad(argv[3]);
      if (system === null) throw new Error('cannot read the system prompt ' + argv[3]);
    }
  } catch (e) { auWarn(e.message); return 2; }

  AU_TMP = auTempDir();
  var ctx = { url: url, header: AU_TMP + '/key-header' };
  if (!$.NSFileManager.defaultManager.createFileAtPathContentsAttributes(ctx.header,
    $('Authorization: Bearer ' + key + '\n').dataUsingEncoding($.NSUTF8StringEncoding), $({ NSFilePosixPermissions: 384 }))) {
    throw new Error('cannot write the key header in ' + AU_TMP);
  }

  var limit = test.pass.within_secs, note = test.house_note === undefined ? '' : test.house_note;
  var t0 = auNow(), last = t0, answered = 0, passed = 0, mandatory = 0, mandatoryPassed = 0;
  test.questions.forEach(function (item, i) {
    var head = 'Q' + (i < 9 ? '0' : '') + (i + 1) + ' ', kind = item.mandatory ? 'mandatory' : 'optional', ok = false, said;
    if (item.mandatory) mandatory++;
    if (last - t0 > limit) {
      said = 'not asked, out of time';
    } else {
      var messages = system ? [{ role: 'system', content: system }] : [];
      messages.push({ role: 'user', content: item.q.split('{note}').join(note) + (item.tail ? AU_ANSWER_TAIL : '') });
      var a = auAsk(ctx, messages, test.max_tokens, Math.max(1, limit - (last - t0) + 1));
      var now = auNow(), secs = now - last;
      last = now;
      if (a.kind === 'answer') { ok = auGrade(item, a.text); said = 'answered in ' + secs + ' s | ' + auExcerpt(a.text); }
      else if (a.kind === 'http') said = 'HTTP ' + a.code + ' in ' + secs + ' s';
      else if (a.kind === 'unreadable') said = 'an answer that cannot be read, in ' + secs + ' s';
      else said = 'no answer in ' + secs + ' s (curl exit ' + a.curl + ')';
      if (a.kind !== 'none') answered++;
    }
    if (ok) { passed++; if (item.mandatory) mandatoryPassed++; }
    auSay(head + (ok ? 'PASS ' : 'FAIL ') + kind + ' ' + item.group + ': ' + said);
  });

  if (last - t0 > limit) auSay('speed none (not asked, out of time)');
  else {
    var s = auAsk(ctx, [{ role: 'user', content: test.speed.q }], test.speed.max_tokens, Math.max(1, limit - (last - t0) + 1));
    last = auNow();
    if (s.kind === 'answer' && s.rate !== null) auSay('speed ' + s.rate.toFixed(1) + ' tok/s (reported only: it never decides the result)');
    else auSay('speed none (' + (s.kind === 'answer' ? 'no rate in the answer' : s.kind === 'http' ? 'HTTP ' + s.code : s.kind === 'unreadable' ? 'an answer that cannot be read' : 'no answer') + ')');
  }

  var elapsed = last - t0, n = test.questions.length, verdict;
  if (answered === 0) verdict = 'none';
  else if (mandatoryPassed === mandatory && passed >= test.pass.at_least && elapsed <= limit) verdict = 'pass';
  else verdict = 'fail';
  auSay('result ' + verdict + ' ' + passed + '/' + n + ' mandatory ' + mandatoryPassed + '/' + mandatory + ' secs ' + elapsed + '/' + limit);
  return verdict === 'pass' ? 0 : verdict === 'fail' ? 1 : 3;
}

function run(argv) {
  var code;
  try { code = auMain(argv); }
  catch (e) { auWarn('stopped: ' + e.message); code = 2; }
  finally { if (AU_TMP !== null) $.NSFileManager.defaultManager.removeItemAtPathError(AU_TMP, null); }
  $.exit(code);
}
