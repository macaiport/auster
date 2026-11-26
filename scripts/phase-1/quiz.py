# Phase 1 of Auster: a small fixed quiz of household questions with exact answers, asked of a running
# server at temperature 0, graded by the program. A sanity probe for "does this build answer worse",
# not a benchmark: 15 questions are too few to rank models that are close.
#
#   quiz.py <url of /v1/chat/completions> <key file> <label> [system prompt file]
import json, re, sys, time, urllib.request

QUESTIONS = [
    ("A recipe for 4 people needs 300 g of rice. How many grams for 10 people?", "num", 750),
    ("Dinner must be on the table at 18:30. The chicken needs 1 hour 45 minutes in the oven, including a 15 minute rest after it comes out. At what time must it go in? Give the time as HH:MM in 24-hour form.", "time", "16:45"),
    ("Convert 350 degrees Fahrenheit to Celsius, rounded to the nearest whole number.", "num", 177),
    ("Our home insurance costs 1260 a year. How much is that per month?", "num", 105),
    ("A train leaves at 08:47 and arrives at 11:12 the same day. How many minutes is the journey?", "num", 145),
    ("A bill of 96 is split between 3 adults and 2 children. Each child pays half of what each adult pays. How much does each adult pay?", "num", 24),
    ("What is 15% of 240?", "num", 36),
    ("A bottle holds 1.5 litres and a glass holds 250 ml. How many full glasses can be poured?", "num", 6),
    ("If today is Wednesday, what day of the week is it 10 days from now?", "word", "saturday"),
    ("How many minutes are there in 3.5 hours?", "num", 210),
    ("A car uses 6 litres of fuel per 100 km. How many litres does it need for 250 km?", "num", 15),
    ("A school term starts on Monday 2 March and lasts 6 weeks. On what date does the last Friday of the term fall? Give the answer as day and month, for example 9 April.", "word", "10 april"),
    ("Three children share 20 sweets equally and the rest go back in the jar. How many go back in the jar?", "num", 2),
    ("Reply with only the word yes, in lower case.", "exact", "yes"),
    ("Name exactly three vegetables, separated by commas, and nothing else.", "three", None),
]
TAIL = "\n\nEnd your reply with a final line of the form: Answer: <answer>"

def ask(url, key, system, q):
    msgs = ([{"role": "system", "content": system}] if system else []) + [{"role": "user", "content": q}]
    body = json.dumps({"messages": msgs, "temperature": 0, "max_tokens": 1200}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=600) as r:
        d = json.load(r)
    m = d["choices"][0]["message"]
    return (m.get("content") or ""), len(m.get("reasoning_content") or ""), d.get("usage", {}).get("completion_tokens", 0), time.time() - t0

def grade(kind, want, text):
    if kind == "exact":
        return text.strip().lower().rstrip(".") == want
    if kind == "three":
        items = [x.strip().rstrip(".") for x in text.strip().split("\n")[0].split(",")]
        return len(items) == 3 and all(re.fullmatch(r"[A-Za-z][A-Za-z \-]{1,30}", x) for x in items)
    if "Answer:" not in text: return False
    # the text after the last "Answer:", which may share a line with an earlier one
    a = text.rsplit("Answer:", 1)[1].strip().split("\n")[0].lower().rstrip(".").replace("**", "")
    if kind == "num":
        n = re.findall(r"-?\d+(?:[.,]\d+)?", a.replace(",", "") if a.count(",") and "." not in a else a)
        return bool(n) and abs(float(n[0].replace(",", ".")) - want) < 0.51
    if kind == "time":
        return want in a.replace(".", ":")
    return want in a

url, keyfile, label = sys.argv[1:4]
system = open(sys.argv[4]).read() if len(sys.argv) > 4 else None
key = open(keyfile).read().strip()
ok = 0; tokens = 0; secs = 0.0; think = 0
for i, (q, kind, want) in enumerate(QUESTIONS, 1):
    prompt = q if kind in ("exact", "three") else q + TAIL
    text, rc, n, t = ask(url, key, system, prompt)
    good = grade(kind, want, text)
    ok += good; tokens += n; secs += t; think += rc
    last = text.strip().splitlines()[-1][:70] if text.strip() else "(empty)"
    print(f"{label} Q{i:02d} {'PASS' if good else 'FAIL'} {t:5.1f}s {n:4d} tok | {last}")
print(f"{label}: {ok}/{len(QUESTIONS)} correct, {tokens} tokens written in {secs:.0f} s, {think} characters of reasoning")
