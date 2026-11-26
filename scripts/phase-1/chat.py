# Phase 1 of Auster: ask the server one question as a person would, streamed, and time the first
# token, the first word of the answer and the whole answer.
#   chat.py <url of /v1/chat/completions> <key file> <system prompt file or -> <question>
import json, sys, time, urllib.request
url, keyfile, sysfile, question = sys.argv[1:5]
key = open(keyfile).read().strip()
msgs = [{"role": "user", "content": question}]
if sysfile != "-": msgs.insert(0, {"role": "system", "content": open(sysfile).read()})
body = json.dumps({"messages": msgs, "stream": True, "temperature": 0.7, "top_p": 0.95, "max_tokens": 1500}).encode()
req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})
t0 = time.time(); first = None; first_answer = None; reasoning = []; answer = []; n = 0
with urllib.request.urlopen(req, timeout=300) as r:
    for raw in r:
        line = raw.decode().strip()
        if not line.startswith("data: ") or line == "data: [DONE]": continue
        d = json.loads(line[6:]); ch = (d.get("choices") or [{}])[0].get("delta", {})
        rc, c = ch.get("reasoning_content"), ch.get("content")
        if (rc or c) and first is None: first = time.time() - t0
        if c and first_answer is None: first_answer = time.time() - t0
        if rc: reasoning.append(rc)
        if c: answer.append(c)
        if rc or c: n += 1
t = time.time() - t0
print(f"first token {first:.2f} s; first word of the answer {first_answer if first_answer is None else round(first_answer, 2)} s; done {t:.2f} s; {n} chunks")
print("reasoning:", len("".join(reasoning)), "chars:", "".join(reasoning)[:160].replace("\n", " "))
print("answer:", "".join(answer)[:400].replace("\n", " "))
