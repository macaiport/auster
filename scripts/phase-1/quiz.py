# Phase 1 of Auster: household questions with one checkable answer each (questions.json beside this
# file), asked of a running server at temperature 0 (or QUIZ_TEMPERATURE) and graded by this program. A probe for "does this
# build answer worse", not a benchmark.
#
#   quiz.py <url of /v1/chat/completions> <key file> <label> [system prompt file] [questions file]
#   quiz.py --regrade <label>-replies.json [questions file]
#
# Prints one line per question and a summary per group. Writes every reply in full to <label>-replies.json
# in the current folder, so that a grade can be checked by hand.
import json, os, re, sys, time, urllib.request

TAIL = "\n\nEnd your reply with a final line of the form: Answer: <answer>"
TEMPERATURE = float(os.environ.get("QUIZ_TEMPERATURE", "0"))


def ask(url, key, system, q):
    msgs = ([{"role": "system", "content": system}] if system else []) + [{"role": "user", "content": q}]
    body = json.dumps({"messages": msgs, "temperature": TEMPERATURE, "max_tokens": 1200}).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=600) as r:
        d = json.load(r)
    m = d["choices"][0]["message"]
    return (m.get("content") or ""), len(m.get("reasoning_content") or ""), d.get("usage", {}).get("completion_tokens", 0), time.time() - t0


def answer_line(text):
    # the text after the last "Answer:", which may share a line with an earlier one
    if "Answer:" not in text:
        return None
    return text.rsplit("Answer:", 1)[1].strip().split("\n")[0].lower().rstrip(".").replace("**", "").strip()


def grade(item, text):
    kind, want = item["kind"], item.get("want")
    reply = text.strip()
    low = reply.lower().rstrip(".").strip()
    if kind == "exact":
        return low == want
    if kind == "three":
        items = [x.strip().rstrip(".") for x in reply.split("\n")[0].split(",")]
        return len(items) == 3 and all(re.fullmatch(r"[A-Za-z][A-Za-z \-]{1,30}", x) for x in items)
    if kind == "upper":
        letters = [c for c in reply if c.isalpha()]
        return bool(letters) and all(c.isupper() for c in letters) and want in reply
    if kind == "json":
        s = re.sub(r"^```(json)?\s*|\s*```$", "", reply)
        try:
            d = json.loads(s)
        except ValueError:
            return False
        return isinstance(d, dict) and all(k in d for k in want)
    if kind == "maxwords":
        return len(reply.split()) <= want[0] and want[1] in low
    if kind == "re_full":
        return re.fullmatch(want, low) is not None
    a = answer_line(text)
    if a is None:
        return False
    if kind == "num":
        a = a.replace(",", "")
        if "=" in a:
            a = a.rsplit("=", 1)[1]  # "1260 / 12 = 105": the value after the last "="
        m = re.match(r"\s*(\d+)\s+(\d+)\s*/\s*(\d+)", a)  # a mixed number such as 2 1/4
        f = re.match(r"\s*(\d+)\s*/\s*(\d+)", a)  # a fraction such as 9/4
        if m and int(m.group(3)):
            v = int(m.group(1)) + int(m.group(2)) / int(m.group(3))
        elif f and int(f.group(2)):
            v = int(f.group(1)) / int(f.group(2))
        else:
            n = re.findall(r"-?\d+(?:\.\d+)?", a)
            if not n:
                return False
            v = float(n[0])
        return abs(v - want) <= item.get("tol", 0.51)
    if kind == "time":
        return want in a.replace(".", ":")
    if kind == "yesno":
        return a.startswith(want)
    if kind == "re":
        return re.search(want, a) is not None
    return want in a  # "word"


def regrade(path_replies, path_questions):
    """Grade saved replies again, after a change to the grader, without asking the model again."""
    data = json.load(open(path_questions)); replies = json.load(open(path_replies))
    ok = 0
    for r in replies:
        good = grade(data["questions"][r["n"] - 1], r["reply"])
        ok += good
        if good != r["pass"]:
            print(f"  Q{r['n']:02d} was {'PASS' if r['pass'] else 'FAIL'}, now {'PASS' if good else 'FAIL'}")
    print(f"{path_replies}: {ok}/{len(replies)} correct after regrading")


def main():
    if sys.argv[1] == "--regrade":
        return regrade(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "questions.json"))
    url, keyfile, label = sys.argv[1:4]
    system = open(sys.argv[4]).read() if len(sys.argv) > 4 and sys.argv[4] != "-" else None
    path = sys.argv[5] if len(sys.argv) > 5 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "questions.json")
    data = json.load(open(path))
    key = open(keyfile).read().strip()
    groups, replies = {}, []
    ok = tokens = think = 0
    secs = 0.0
    for i, item in enumerate(data["questions"], 1):
        q = item["q"].replace("{note}", data.get("house_note", ""))
        text, rc, n, t = ask(url, key, system, q + (TAIL if item.get("tail") else ""))
        good = grade(item, text)
        ok += good; tokens += n; secs += t; think += rc
        g = groups.setdefault(item["group"], [0, 0]); g[0] += good; g[1] += 1
        replies.append({"n": i, "group": item["group"], "pass": good, "secs": round(t, 2), "tokens": n, "reply": text})
        last = text.strip().splitlines()[-1][:60] if text.strip() else "(empty)"
        print(f"{label} Q{i:02d} {item['group']:7s} {'PASS' if good else 'FAIL'} {t:5.1f}s {n:4d} tok | {last}")
    json.dump(replies, open(f"{label}-replies.json", "w"), indent=1)
    print(f"{label}: " + ", ".join(f"{g} {a}/{b}" for g, (a, b) in groups.items()))
    print(f"{label}: {ok}/{len(data['questions'])} correct, {tokens} tokens written in {secs:.0f} s, {think} characters of reasoning")


if __name__ == "__main__":
    main()
