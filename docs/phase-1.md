# Phase 1 log: the household assistant, by hand

Everything done by hand on the development Mac, in order, with what was measured. Phase 2 turns this
list into the installer (`SPEC.md`, phase 1, exit criterion 5). The Mac is a Mac Studio, M5 Max, 64 GB,
macOS 27.2.1.

**Rule for this phase: the checks Auster will make are made by hand first, and nobody's word is taken
for them.** That includes the owner's. Before each download or measurement the step below is run again
and its numbers recorded.

## Step 0. The checks before anything is fetched (2026-11-26, 03:40)

| | Check | Measured | Verdict |
|---|---|---|---|
| 1 | Free disk | 422.2 GB free now; 459.0 GB counting what macOS can clear; 1,995 GB in all | Room for every candidate at once (about 142 GB), leaving about 280 GB |
| 2 | Memory | 64 GB installed. 53,084 MiB (55.7 GB) usable by the GPU, all of it free. The system reports 84% of memory free | Room for model A at any of its sizes |
| 3 | Nothing competing | No game, no Wine, no model running; the processor 98% idle. **Another project's session on this Mac was busy** | Fine for a download. A measurement waits until that session is idle |
| 4 | The publisher still offers the pinned file | `Magistral-Small-2509-Q4_K_M.gguf` at commit `429b90d8…`: size 14,334,432,256 and hash `d3a024d2…a43434`, both equal to what was recorded | Pass |
| 5 | The engine | llama.cpp 0.3.0 installed; 1.0.0 on offer | To be updated before the first measurement |
| 6 | Port and jobs | Nothing listens on 8080; no Auster launch job exists | Pass |
| 7 | Staying up | The Mac does not sleep when idle. Restart after a power cut is off. FileVault is on. SSH answers | Fine for phase 1's measurements. The restart question is the plan's AD15 |

What this step showed about the check Auster needs:

- **"Free" has two readings.** macOS reported 37 GB more as available once it counts what it can clear.
  The rule has to say which it uses. Earlier the same day the two readings were 63.5 GB and 98.6 GB.
- **Free disk changes without Auster doing anything.** It went from 64 GB to 422 GB in a few hours
  because the owner cleared space. A figure taken at the question can be wrong by the download, which is
  why the plan works room out again before the download starts (D3.6 step 3).
- **The publisher is asked before the download, not trusted from a note.** The size and hash matched,
  a few hours after they were first read.
- **Another project on the same Mac matters to a measurement and not to a download.** Auster cannot see
  that for a household; the guide should say when measurements are worth taking.

## Sizes of the candidates

| | Build | Size |
|---|---|---|
| A | Magistral Small 2509, Q4_K_M (Mistral's own GGUF) | 14.3 GB |
| A | the same, Q8_0 | 25.1 GB |
| A | the same for MLX, 4-bit (a third party's build) | 14.1 GB |
| B | Mistral Small 4, IQ3_S | 44.4 GB |
| C | Apertus 70B Instruct 2509, Q4_K_M | 43.7 GB |

Nothing has been downloaded yet.
