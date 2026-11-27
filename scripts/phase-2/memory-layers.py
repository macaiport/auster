# Phase 2 of Auster, measurement B for the local-layer plan (M3a, M10): layers with pointers. The system
# prompt carries an index of topics, each with a pointer; the notes behind each pointer are held here
# (memory-layers.json beside this file), as Auster's layer would hold them. Each question's answer is only
# in one topic's notes. Four conditions:
#   index     the index alone: a right answer should be impossible; does the model say so, or invent one?
#   tool      an open_detail(pointer) tool is offered, and this script serves it as Auster would
#   reminder  no tool; after the first answer the script asks once more with the right topic's notes
#   fetched   the script puts the right topic's notes in the prompt before asking (Auster's own fetching)
# The index is shuffled differently in each run, the same way for every condition. Graded by
# scripts/phase-1/quiz.py, imported as is.
#
#   memory-layers.py <url of /v1/chat/completions> <key file> <label> <system prompt file> [runs] [fixtures]
#   memory-layers.py --reclassify <label>-replies.json [fixtures]   classifies saved first answers again
#
# Prints one line per question and a summary per condition. Writes every exchange in full to
# <label>-replies.json and the counts to <label>-summary.json in the current folder.
import importlib.util, json, os, random, re, sys, time, urllib.error, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("quiz", os.path.join(HERE, "..", "phase-1", "quiz.py"))
quiz = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(quiz)

CONDITIONS = ["index", "tool", "reminder", "fetched"]
MAX_ROUNDS = 4  # tool rounds before the script gives up on a question
TOOL = {"type": "function", "function": {
    "name": "open_detail",
    "description": "Open the household's notes on one topic from the index.",
    "parameters": {"type": "object", "properties": {"pointer": {
        "type": "string", "description": "The topic's pointer, as shown in square brackets in the index."}},
        "required": ["pointer"]}}}
# Without the notes, a reply either says it lacks them (or sends the asker to the topic's notes), invents an
# answer, or gives none (the literal "<answer>"). Read on the Answer line when there is one, else on the whole
# reply. Pointer tags and the index's own words are taken out first, so that "[m3vq] The ferry leaves at 9:30"
# counts as invented and "[n1xr] Bins and recycling" as pointed.
DECLINE = re.compile(r"unknown|not (known|sure|specified|listed|available|stated|given|shown|included|recorded|mentioned|provided|in the)"
                     r"|n/a|\b(don't|do not|doesn't|does not|can't|cannot|unable to) (know|have|see|find|say|tell|access|contain|include"
                     r"|mention|list|open|specify|provide|state|give)|no (information|details|data|record)|(isn't|is not) (listed|shown|included|in)"
                     r"|specify the pointer|\bcheck (there|the|under|its)|need to (check|open|look)|notes (for|on|under|are)", re.I)
TAG = re.compile(r"\[\s*\**\s*[a-z0-9]{4}\s*\**\s*\]", re.I)


def post(url, key, messages, tools=None):
    body = {"messages": messages, "temperature": quiz.TEMPERATURE, "max_tokens": 1200}
    if tools:
        body["tools"] = tools
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=600) as r:
        d = json.load(r)
    return d["choices"][0]["message"], d.get("usage", {}), time.time() - t0


def notes_text(t):
    return f"Notes for {t['name']} [{t['id']}]: " + " ".join(t["notes"])


def unknown_class(text, topics):
    a = quiz.answer_line(text)
    a = (text if a is None else a).lower()
    if DECLINE.search(a):
        return "declined or pointed"
    rest = TAG.sub(" ", a)
    for t in topics:
        for words in (f"{t['name']}: {t['gloss']}", t["name"], t["gloss"]):
            rest = rest.replace(words.lower(), " ")
    rest = re.sub(r"[^a-z0-9]+", " ", rest).strip()
    if rest in ("", "see", "see the notes") or re.search(r"\b(is|are) (under|in|at)$", rest):
        return "declined or pointed"
    return "no answer" if rest == "answer" else "invented"


def ask(url, key, base, header, topics, item, cond, order):
    """One question in one condition. Returns the record, with every request's reply."""
    byid = {t["id"]: t for t in topics}
    right = byid[item["topic"]]
    system = f"{base}\n\n{header}\n" + "\n".join(f"- [{t['id']}] {t['name']}: {t['gloss']}" for t in order)
    if cond == "fetched":
        system += "\n\n" + notes_text(right)
    msgs = [{"role": "system", "content": system}, {"role": "user", "content": item["q"] + quiz.TAIL}]
    rec = {"replies": [], "calls": [], "tokens": 0, "prompt_tokens": 0, "secs": 0.0, "requests": 0}

    def send(tools=None):
        m, usage, secs = post(url, key, msgs, tools)
        rec["tokens"] += usage.get("completion_tokens", 0)
        rec["prompt_tokens"] += usage.get("prompt_tokens", 0)
        rec["secs"] += secs
        rec["requests"] += 1
        rec["replies"].append({"content": m.get("content") or "", "tool_calls": m.get("tool_calls") or [],
                               "reasoning_chars": len(m.get("reasoning_content") or "")})
        return m

    final = ""
    if cond == "tool":
        for _ in range(MAX_ROUNDS):
            m = send([TOOL])
            tcs = m.get("tool_calls") or []
            if not tcs:
                final = m.get("content") or ""
                break
            msgs.append({"role": "assistant", "content": m.get("content") or "", "tool_calls": tcs})
            for tc in tcs:
                name = tc["function"]["name"]
                try:
                    pointer = json.loads(tc["function"]["arguments"] or "{}").get("pointer")
                except (ValueError, AttributeError):
                    pointer = None
                p = str(pointer).strip().strip("[]").strip().lower()
                if name != "open_detail":
                    result = f"There is no tool named {name}."
                elif p in byid:
                    result = notes_text(byid[p])
                else:
                    result = f"No topic has the pointer {pointer!r}."
                rec["calls"].append({"name": name, "pointer": pointer, "found": name == "open_detail" and p in byid})
                msgs.append({"role": "tool", "tool_call_id": tc.get("id", ""), "name": name, "content": result})
        else:
            rec["gave_up"] = True
        rec["called"] = bool(rec["calls"])
        rec["opened_right"] = any(c["found"] and str(c["pointer"]).strip().strip("[]").strip().lower() == right["id"]
                                  for c in rec["calls"])
    else:
        m = send()
        final = m.get("content") or ""
        if cond in ("index", "reminder"):
            rec["first_class"] = "correct" if quiz.grade(item, final) else unknown_class(final, topics)
        if cond == "reminder":
            # No tool, so the first answer cannot have used the notes: the reminder is always sent.
            rec["first_answer"] = quiz.answer_line(final)
            msgs.append({"role": "assistant", "content": final or "(no answer)"})
            msgs.append({"role": "user", "content": f"These details exist for topic {right['name']}: "
                                                    + " ".join(right["notes"]) + " Check them before you answer." + quiz.TAIL})
            final = send().get("content") or ""
            rec["final_answer"] = quiz.answer_line(final)
    rec["correct"] = quiz.grade(item, final)
    rec["final"] = final
    rec["secs"] = round(rec["secs"], 2)
    return rec


def reclassify(path, fixtures):
    """Classify the saved first answers again, after a change to the classifier, without asking the model again."""
    data = json.load(open(fixtures or os.path.join(HERE, "memory-layers.json")))
    records = json.load(open(path))
    for r in records:
        if r["cond"] in ("index", "reminder") and "error" not in r:
            first = r["replies"][0]["content"]
            r["first_class"] = "correct" if quiz.grade(data["questions"][r["n"] - 1], first) else unknown_class(first, data["topics"])
    json.dump(records, open(path, "w"), indent=1)
    summarize(records, max(r["run"] for r in records), path.removesuffix("-replies.json"))


def main():
    if sys.argv[1] == "--reclassify":
        return reclassify(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else None)
    url, keyfile, label, sysfile = sys.argv[1:5]
    runs = int(sys.argv[5]) if len(sys.argv) > 5 else 3
    data = json.load(open(sys.argv[6] if len(sys.argv) > 6 else os.path.join(HERE, "memory-layers.json")))
    key = open(keyfile).read().strip()
    base = open(sysfile).read().strip()
    records = []
    for run in range(1, runs + 1):
        for cond in CONDITIONS:
            for n, item in enumerate(data["questions"], 1):
                order = list(data["topics"])
                random.Random(f"B-{run}-{n}").shuffle(order)
                try:
                    rec = ask(url, key, base, data["header"], data["topics"], item, cond, order)
                except (urllib.error.URLError, OSError, KeyError, ValueError) as e:
                    body = e.read().decode(errors="replace")[:500] if isinstance(e, urllib.error.HTTPError) else ""
                    rec = {"error": f"{e} {body}".strip(), "correct": False, "secs": 0.0, "tokens": 0, "requests": 0, "final": ""}
                rec.update({"run": run, "cond": cond, "n": n, "index_order": [t["id"] for t in order]})
                records.append(rec)
                extra = ""
                if cond == "tool" and "error" not in rec:
                    extra = f" calls {[c['pointer'] for c in rec['calls']]} right {rec['opened_right']}"
                elif "first_class" in rec:
                    extra = f" first: {rec['first_class']}"
                last = rec["final"].strip().splitlines()[-1][:50] if rec.get("final", "").strip() else "(empty)"
                tag = "ERROR" if "error" in rec else "PASS" if rec["correct"] else "FAIL"
                print(f"{label} r{run} {cond:8s} Q{n:02d} {tag} {rec['secs']:5.1f}s {rec['tokens']:4d} tok{extra} | "
                      f"{rec.get('error', last)}", flush=True)
    json.dump(records, open(f"{label}-replies.json", "w"), indent=1)
    summarize(records, runs, label)


def summarize(records, runs, label):
    summary = {}
    for cond in CONDITIONS:
        rs = [r for r in records if r["cond"] == cond]
        ok = [r for r in rs if "error" not in r]
        s = {"asked": len(rs), "errors": len(rs) - len(ok),
             "correct": sum(r["correct"] for r in rs),
             "per_run_correct": [sum(r["correct"] for r in rs if r["run"] == k) for k in range(1, runs + 1)],
             "mean_secs": round(sum(r["secs"] for r in ok) / max(len(ok), 1), 2),
             "mean_tokens": round(sum(r["tokens"] for r in ok) / max(len(ok), 1), 1),
             "mean_requests": round(sum(r["requests"] for r in ok) / max(len(ok), 1), 2)}
        if cond in ("index", "reminder"):
            for c in ("correct", "declined or pointed", "invented", "no answer"):
                s["first_" + c] = sum(r.get("first_class") == c for r in ok)
        if cond == "reminder":
            s["kept_wrong_first_answer"] = sum(not r["correct"] and r.get("first_answer") is not None
                                               and r.get("first_answer") == r.get("final_answer") for r in ok)
        if cond == "tool":
            s["called"] = sum(r["called"] for r in ok)
            s["opened_right"] = sum(r["opened_right"] for r in ok)
            s["correct_when_opened_right"] = sum(r["correct"] for r in ok if r["opened_right"])
            s["correct_without_a_call"] = sum(r["correct"] for r in ok if not r["called"])
            s["gave_up"] = sum(bool(r.get("gave_up")) for r in ok)
        summary[cond] = s
        print(f"{label} {cond:8s}: " + ", ".join(f"{k} {v}" for k, v in s.items()))
    json.dump(summary, open(f"{label}-summary.json", "w"), indent=1)


if __name__ == "__main__":
    main()
