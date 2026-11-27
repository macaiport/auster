# Phase 2 of Auster: serves one household build on 127.0.0.1, runs the memory measurements against it
# (memory-wrong.py for A, memory-layers.py for B), and stops the engine, whatever happens. The engine is
# served exactly as in docs/phase-2.md, section 9. Replies and logs go to the phase 1 workspace's
# runs/p2-memory-2/.
#
#   memory-run.py <order1|order2> [A] [B] [runs]
import os, socket, subprocess, sys, time, urllib.error, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
P1 = os.path.expanduser("~/Library/Developer/Auster/phase-1")
OUT = os.path.join(P1, "runs", "p2-memory-2")
PORT = 18131
BUILDS = {
    "order1": ["-m", "store/Mistral-Small-4-119B-2603-UD-IQ3_S.gguf"],
    "order2": ["-m", "store/Magistral-Small-2509-Q4_K_M.gguf",
               "--chat-template-file", "store/templates/mistralai-Ministral-3-14B-Reasoning-2512.jinja"],
}
COMMON = ["-c", "131072", "-np", "4", "--fit", "off", "-ngl", "all", "--jinja", "--offline", "--no-slots",
          "--host", "127.0.0.1", "--port", str(PORT), "--api-key-file", "keys/keys.txt"]
SCRIPTS = {"A": "memory-wrong.py", "B": "memory-layers.py"}


def healthy():
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/health", timeout=5) as r:
            return r.status == 200
    except (urllib.error.URLError, OSError):
        return False


def main():
    build = sys.argv[1]
    which = [a for a in sys.argv[2:] if a in SCRIPTS] or ["A", "B"]
    runs = next((a for a in sys.argv[2:] if a.isdigit()), "3")
    with socket.socket() as s:
        if s.connect_ex(("127.0.0.1", PORT)) == 0:
            sys.exit(f"port {PORT} is already in use")
    os.makedirs(OUT, exist_ok=True)
    log = open(os.path.join(OUT, f"{build}-server.log"), "a")
    engine = subprocess.Popen([os.path.join(P1, "engine", "llama-b12359", "llama-server")] + BUILDS[build] + COMMON,
                              cwd=P1, stdout=log, stderr=subprocess.STDOUT)
    try:
        t0 = time.time()
        while not healthy():
            if engine.poll() is not None:
                sys.exit(f"the engine stopped while loading (exit {engine.returncode}); see {build}-server.log")
            if time.time() - t0 > 900:
                sys.exit("the engine did not become healthy in 15 minutes")
            time.sleep(2)
        print(f"{build}: engine ready in {time.time() - t0:.0f} s", flush=True)
        for m in which:
            subprocess.run([sys.executable, "-I", os.path.join(HERE, SCRIPTS[m]),
                            f"http://127.0.0.1:{PORT}/v1/chat/completions", os.path.join(P1, "keys", "a"),
                            f"{build}-{m}", os.path.join(P1, "store", "household-system.txt"), runs],
                           cwd=OUT, check=False)
    finally:
        engine.terminate()
        try:
            engine.wait(60)
        except subprocess.TimeoutExpired:
            engine.kill()
            engine.wait()
        print(f"{build}: engine stopped (exit {engine.returncode})", flush=True)


if __name__ == "__main__":
    main()
