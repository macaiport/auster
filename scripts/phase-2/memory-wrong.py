# Phase 2 of Auster, measurement A for the local-layer plan (M10): memories that matter but are wrong.
# Each question's answer is only in the "remembered" facts of the system prompt (memory-wrong.json beside
# this file), and each is asked in four conditions: clean, replaced (an older dated fact beside the newer
# one), person (the same attribute for someone else) and near (a neighbouring fact that does not answer).
# The memory list is shuffled differently in each run. Graded by scripts/phase-1/quiz.py, imported as is.
#
#   memory-wrong.py <url of /v1/chat/completions> <key file> <label> <system prompt file> [runs] [fixtures]
#   memory-wrong.py --check [fixtures]     checks, without a server, that every pattern tells its fact apart
#
# Prints one line per request and a summary per condition. Writes every reply in full to
# <label>-replies.json and the counts to <label>-summary.json in the current folder.
import importlib.util, json, os, random, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True
_spec = importlib.util.spec_from_file_location("quiz", os.path.join(HERE, "..", "phase-1", "quiz.py"))
quiz = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(quiz)

CONDITIONS = ["clean", "replaced", "person", "near"]
# The facts' own dates ("From 1 October") and today's are taken out of a reply before grading, so that the
# 1 of "1 October" is never read as an answer of 1.
DATES = re.compile(r"\b(?:the )?1(?:st)?(?: of)? (?:march|october)\b|\b(?:march|october) 1(?:st)?\b|\b26 november(?: 2026)?\b", re.I)


def scrub(text):
    return DATES.sub("[date]", text)


def load(path):
    return json.load(open(path or os.path.join(HERE, "memory-wrong.json")))


def facts_for(item, cond):
    if cond == "clean":
        return [item["fact"]]
    if cond == "replaced":
        return [item["replaced"]["fact"], item["fact"]]
    return [item["fact"], item[cond]["fact"]]


def check(data):
    """Every pattern must find its own fact and none of the others, the filler or the date line."""
    bad = 0
    others = data["filler"] + [data["today"], data["header"]]
    for n, item in enumerate(data["questions"], 1):
        texts = {"correct": item["fact"], **{c: item[c]["fact"] for c in CONDITIONS[1:]}}
        wants = {"correct": item["want"], **{c: item[c]["want"] for c in CONDITIONS[1:]}}
        for name, want in wants.items():
            for tname, text in texts.items():
                hit = re.search(want, scrub(text).lower()) is not None
                if hit != (name == tname):
                    bad += 1
                    print(f"Q{n:02d}: pattern {name} {'finds' if hit else 'misses'} fact {tname}: {text}")
            for o in others:
                if re.search(want, scrub(o).lower()):
                    bad += 1
                    print(f"Q{n:02d}: pattern {name} finds: {o}")
    print(f"check: {len(data['questions'])} questions, {bad} problems")
    return bad == 0


def verdict(item, cond, text):
    t = scrub(text)
    good = quiz.grade({"kind": item["kind"], "want": item["want"]}, t)
    if cond == "clean":
        return "correct" if good else "miss"
    wrong = quiz.grade({"kind": item["kind"], "want": item[cond]["want"]}, t)
    if good and wrong:
        return "both"
    return "correct" if good else "wrong fact" if wrong else "miss"


def main():
    if sys.argv[1] == "--check":
        sys.exit(0 if check(load(sys.argv[2] if len(sys.argv) > 2 else None)) else 1)
    url, keyfile, label, sysfile = sys.argv[1:5]
    runs = int(sys.argv[5]) if len(sys.argv) > 5 else 3
    data = load(sys.argv[6] if len(sys.argv) > 6 else None)
    if not check(data):
        sys.exit(1)
    key = open(keyfile).read().strip()
    base = open(sysfile).read().strip()
    records = []
    for run in range(1, runs + 1):
        for cond in CONDITIONS:
            for n, item in enumerate(data["questions"], 1):
                lines = data["filler"] + facts_for(item, cond)
                random.Random(f"A-{run}-{n}-{cond}").shuffle(lines)
                system = f"{base}\n\n{data['today']}\n\n{data['header']}\n" + "\n".join("- " + x for x in lines)
                try:
                    text, think, tokens, secs = quiz.ask(url, key, system, item["q"] + quiz.TAIL)
                    v = verdict(item, cond, text)
                except Exception as e:  # recorded, so that one failed request does not lose the run
                    text, think, tokens, secs, v = f"(error: {e})", 0, 0, 0.0, "error"
                has_line = quiz.answer_line(text) is not None
                records.append({"run": run, "cond": cond, "n": n, "verdict": v, "answer_line": has_line,
                                "secs": round(secs, 2), "tokens": tokens, "reasoning_chars": think,
                                "facts": lines, "reply": text})
                last = text.strip().splitlines()[-1][:60] if text.strip() else "(empty)"
                print(f"{label} r{run} {cond:8s} Q{n:02d} {v:10s} {secs:5.1f}s {tokens:4d} tok | {last}", flush=True)
    json.dump(records, open(f"{label}-replies.json", "w"), indent=1)
    summary = {}
    for cond in CONDITIONS:
        rs = [r for r in records if r["cond"] == cond]
        s = {"per_run_correct": [sum(r["verdict"] == "correct" for r in rs if r["run"] == k) for k in range(1, runs + 1)],
             "asked": len(rs)}
        for v in ("correct", "wrong fact", "both", "miss", "error"):
            s[v] = sum(r["verdict"] == v for r in rs)
        s["miss_without_answer_line"] = sum(r["verdict"] == "miss" and not r["answer_line"] for r in rs)
        s["tokens"] = sum(r["tokens"] for r in rs)
        s["secs"] = round(sum(r["secs"] for r in rs), 1)
        summary[cond] = s
        print(f"{label} {cond:8s}: correct {s['correct']}/{s['asked']} (runs {', '.join(map(str, s['per_run_correct']))}), "
              f"wrong fact {s['wrong fact']}, both {s['both']}, miss {s['miss']} "
              f"({s['miss_without_answer_line']} without an Answer line), errors {s['error']}")
    json.dump(summary, open(f"{label}-summary.json", "w"), indent=1)


if __name__ == "__main__":
    main()
