// The recipe's test grader (docs/plans/v0.1.md, A7), in JavaScript for Automation (BD17): the grading
// rules of scripts/phase-1/quiz.py, grade() and answer_line(), carried over rule for rule. T59 checks it
// against quiz.py's verdicts on phase 1's saved replies (tests/fixtures/phase-1/) and on constructed
// cases (tests/fixtures/recipe-test/grader-cases.json).
//
// Pure functions, no run(). Load it with a direct eval in sloppy code, so that its declarations land in
// the caller's scope; that is why everything at the top level is a function or a var, never const/let:
//
//   eval(auLoad(dir + '/grade-lib.js'));
//   auGrade(item, reply)    -> true or false; item is a question as in questions.json (kind, want, tol)
//   auAnswerLine(reply)     -> the answer after the last "Answer:", or null
//   AU_ANSWER_TAIL          -> the text quiz.py adds to a question whose "tail" is true
//
// Python's meaning is kept where it differs from JavaScript's: whitespace is what str.isspace() calls
// whitespace (strip, split, \s), \d is any Unicode decimal digit and int()/float() read such digits,
// characters are code points, json.loads takes NaN, Infinity and -Infinity, and a regular expression's
// . and $ mean what they mean in Python. auPyRe translates a pattern from Python's re to JavaScript and
// refuses (throws) what it cannot translate exactly: \w, \W, \b, \B, \S inside [...], backreferences
// (a group that took no part fails in Python and matches empty in JavaScript), and every (?...) group
// other than (?:...), lookahead and lookbehind.

var AU_ANSWER_TAIL = '\n\nEnd your reply with a final line of the form: Answer: <answer>';

// Python's str.isspace() characters, as the body of a [...] class
var AU_PY_WS = '\\t-\\r\\x1c-\\x20\\x85\\xa0\\u1680\\u2000-\\u200a\\u2028\\u2029\\u202f\\u205f\\u3000';

function auPyStrip(s) { // str.strip()
  return s.replace(new RegExp('^[' + AU_PY_WS + ']+|[' + AU_PY_WS + ']+$', 'gu'), '');
}

function auPyRstripDots(s) { // str.rstrip(".")
  return s.replace(/\.+$/, '');
}

function auPySplit(s) { // str.split() with no argument
  return s.split(new RegExp('[' + AU_PY_WS + ']+', 'u')).filter(function (x) { return x !== ''; });
}

function auPyReplaceAll(s, from, to) { // str.replace(from, to)
  return s.split(from).join(to);
}

function auNdToAscii(s) { // Unicode decimal digits as 0-9, as int() and float() read them
  return s.replace(/\p{Nd}/gu, function (d) {
    // decimal digits come in runs of whole tens, 0 to 9 in order: find where this run starts
    var cp = d.codePointAt(0), start = cp;
    if (cp <= 0x39) return d;
    while (start > 0 && /\p{Nd}/u.test(String.fromCodePoint(start - 1))) start--;
    return String((cp - start) % 10);
  });
}

function auPyRe(pattern) { // a pattern for Python's re -> the source of a JavaScript 'u' expression
  var out = '', i = 0, inClass = false, classStart = -1, c, e;
  var punct = '^$\\.*+?()[]{}|/';
  while (i < pattern.length) {
    c = pattern[i];
    if (c === '\\') {
      e = pattern[i + 1];
      if (e === undefined) throw new Error('a pattern ends in \\');
      i += 2;
      if (e === 'd') out += '\\p{Nd}';
      else if (e === 'D') out += '\\P{Nd}';
      else if (e === 's') out += inClass ? AU_PY_WS : '[' + AU_PY_WS + ']';
      else if (e === 'S') {
        if (inClass) throw new Error('\\S inside [...] is not translated');
        out += '[^' + AU_PY_WS + ']';
      } else if (e === 'A' && !inClass) out += '^';
      else if (e === 'Z' && !inClass) out += '$';
      else if ('ntrfv'.indexOf(e) >= 0) out += '\\' + e;
      else if (e === 'x' || e === 'u') out += '\\' + e;
      else if (/[A-Za-z0-9_]/.test(e)) throw new Error('\\' + e + ' is not translated');
      else if (inClass) out += (e === ']' || e === '\\' || e === '^' || e === '-') ? '\\' + e : e;
      else out += punct.indexOf(e) >= 0 ? '\\' + e : e;
      continue;
    }
    if (inClass) {
      if (c === ']' && i > classStart) { inClass = false; out += ']'; }
      else if (c === ']') out += '\\]';   // Python: a ] first in a class is itself
      else if (c === '[') out += '\\[';
      else out += c;
      i++;
      continue;
    }
    if (c === '[') {
      inClass = true; out += '['; i++;
      if (pattern[i] === '^') { out += '^'; i++; }
      classStart = i;
      continue;
    }
    if (c === '(' && pattern[i + 1] === '?') {
      var g = pattern.slice(i, i + 4);
      if (!/^\(\?[:=!]/.test(g) && !/^\(\?<[=!]/.test(g)) throw new Error(g + ' is not translated');
      out += c; i++;
      continue;
    }
    if (c === '.') out += '[^\\n]';
    else if (c === '$') out += '(?=\\n?$)';
    else out += c;
    i++;
  }
  if (inClass) throw new Error('a [...] is not closed');
  return out;
}

function auReSearch(pattern, s) { return new RegExp(auPyRe(pattern), 'u').exec(s); }   // re.search
function auReMatch(pattern, s) { return new RegExp('^(?:' + auPyRe(pattern) + ')', 'u').exec(s); }   // re.match
function auReFullmatch(pattern, s) { return new RegExp('^(?:' + auPyRe(pattern) + ')$', 'u').exec(s); }   // re.fullmatch

function auPyJsonLoads(s) { // json.loads: JSON.parse, with NaN, Infinity and -Infinity taken as values
  var out = '', i = 0, inString = false, c;
  while (i < s.length) {
    c = s[i];
    if (inString) {
      out += c; i++;
      if (c === '\\' && i < s.length) { out += s[i]; i++; }
      else if (c === '"') inString = false;
      continue;
    }
    if (c === '"') { inString = true; out += c; i++; continue; }
    if (s.startsWith('-Infinity', i)) { out += 'null'; i += 9; continue; }
    if (s.startsWith('Infinity', i)) { out += 'null'; i += 8; continue; }
    if (s.startsWith('NaN', i)) { out += 'null'; i += 3; continue; }
    out += c; i++;
  }
  return JSON.parse(out);
}

function auAnswerLine(text) { // quiz.py answer_line(): the text after the last "Answer:"
  var at = text.lastIndexOf('Answer:');
  if (at < 0) return null;
  var a = auPyStrip(text.slice(at + 'Answer:'.length)).split('\n')[0].toLowerCase();
  return auPyStrip(auPyReplaceAll(auPyRstripDots(a), '**', ''));
}

function auGrade(item, text) { // quiz.py grade()
  var kind = item.kind, want = item.want;
  var reply = auPyStrip(text);
  var low = auPyStrip(auPyRstripDots(reply.toLowerCase()));
  var i;
  if (kind === 'exact') return low === want;
  if (kind === 'three') {
    var items = reply.split('\n')[0].split(',').map(function (x) { return auPyRstripDots(auPyStrip(x)); });
    return items.length === 3 && items.every(function (x) { return auReFullmatch('[A-Za-z][A-Za-z \\-]{1,30}', x) !== null; });
  }
  if (kind === 'upper') {
    var letters = Array.from(reply).filter(function (ch) { return /\p{L}/u.test(ch); });
    return letters.length > 0 && letters.every(function (ch) { return /\p{Lu}/u.test(ch); }) && reply.indexOf(want) >= 0;
  }
  if (kind === 'json') {
    var s = reply.replace(new RegExp(auPyRe('^```(json)?\\s*|\\s*```$'), 'gu'), '');
    var d;
    try { d = auPyJsonLoads(s); } catch (err) { return false; }
    if (d === null || typeof d !== 'object' || Array.isArray(d)) return false;
    for (i = 0; i < want.length; i++) if (!Object.prototype.hasOwnProperty.call(d, want[i])) return false;
    return true;
  }
  if (kind === 'maxwords') return auPySplit(reply).length <= want[0] && low.indexOf(want[1]) >= 0;
  if (kind === 're_full') return auReFullmatch(want, low) !== null;
  var a = auAnswerLine(text);
  if (a === null) return false;
  if (kind === 'num') {
    a = auPyReplaceAll(a, ',', '');
    if (a.indexOf('=') >= 0) a = a.slice(a.lastIndexOf('=') + 1);   // "1260 / 12 = 105": the value after the last "="
    var m = auReMatch('\\s*(\\d+)\\s+(\\d+)\\s*/\\s*(\\d+)', a);   // a mixed number such as 2 1/4
    var f = auReMatch('\\s*(\\d+)\\s*/\\s*(\\d+)', a);   // a fraction such as 9/4
    var v, n;
    var num = function (g) { return Number(auNdToAscii(g)); };
    if (m && num(m[3])) v = num(m[1]) + num(m[2]) / num(m[3]);
    else if (f && num(f[2])) v = num(f[1]) / num(f[2]);
    else {
      n = auReSearch('-?\\d+(?:\\.\\d+)?', a);
      if (!n) return false;
      v = Number(auNdToAscii(n[0]));
    }
    return Math.abs(v - want) <= (item.tol !== undefined ? item.tol : 0.51);
  }
  if (kind === 'time') return auPyReplaceAll(a, '.', ':').indexOf(want) >= 0;
  if (kind === 'yesno') return a.startsWith(want);
  if (kind === 're') return auReSearch(want, a) !== null;
  return a.indexOf(want) >= 0;   // "word"
}
