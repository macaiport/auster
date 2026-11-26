# macAIport / Auster — local AI on Apple Silicon, one recipe per use

> **Public version, edited 2026-11-26 from the owner's concept note of 2026-11-25.** The naming and
> funding sections and the references to other projects are kept privately. This is the starting
> concept, not the current plan: where it differs from `SPEC.md`, `SPEC.md` is newer. Its review found,
> for one, that the 119B model does not fit a 64 GB Mac at 4 bits.

**Pitch:** The free AI stack already exists — engines, weights, clients — but assembling it is a weekend of Terminal work. This project cobbles the pieces together the way 1launcher does for Windows games: curated recipes, one-line installs, double-clickable results, no CrossOver-equivalent tax. Built on the pattern proven at [macgameport/1launcher](https://github.com/macgameport/1launcher).

---

## Concept mapping (validated by 1launcher)

| 1launcher / macgameport | Auster equivalent |
|---|---|
| Per-game folder: wrapper, patches, install guide, findings | Per-recipe folder: model + quant + server config + client setup |
| Installer fetches each piece from its publisher (Wine, DXMT, Steam) | Installer fetches engine (LM Studio / Ollama / MLX) + weights from verified publisher repos, pinned checksums |
| Binary patches; builds double-clickable .app with game's icon | Builds "Brain" .app: server running, menu-bar status, no Terminal |
| 14unch3r: one window lists games, starts what you click | Launcher lists models, loads/swaps what you click, shows RAM headroom |
| Game settings matched to processor / machine capability | Model + quant + context matched to unified memory tier and bandwidth |
| Daily version check; one-click re-run of installer across games | Model/engine update checks; one-click refresh; checksum re-verification |

## Why this is a real gap

- Running *one model* locally is approachable (LM Studio, Ollama). Running a *household utility* — always-on server, fixed hostname, per-user keys, iPad clients, fail-over, escalation tier — is where lay users die.
- All components are free; the assembly is the product. Same insight as "free stack, no CrossOver."
- Target user: someone who wants a household AI server and has nobody at home to build one.

## Honest differences from game porting

- **Faster churn:** new model families monthly; license quirks per model (Mistral modified-MIT MaaS clause, etc.). Requires a recipe registry the project controls.
- **Quiet failure modes:** a game that won't launch is obvious; a too-aggressive quant silently degrading answers is not. Recipes must pin known-good quants, not just known-good binaries.
- **Trust tiers as a feature:** provenance curation (fully-auditable models like Apertus vs. open-weight-only vs. trust-requires-sandbox) becomes product value, mirroring the Qwen/Cohere exfiltration concern. Default: curated allowlist; unlisted models unsupported.
- **Refusal UX:** 16GB MacBook owners will ask for the 1T-parameter model. The capability matcher must refuse gracefully and point to the right tier — disappointment, not crash.

## Recipe roster (launch set — small and curated)

Each recipe = one folder, mirroring 1launcher's per-game layout:

| Recipe | Stack | Target machines |
|---|---|---|
| `household-assistant/` | Mistral Small 4 (4-bit) + LM Studio server + Open WebUI PWA + per-user keys | 64–128GB Macs |
| `coders-companion/` | Devstral Small + Cline/Continue glue + localhost endpoint config | 32GB+ Macs |
| `kids-homework-box/` | Small fast model + locked-down Open WebUI, no network egress | Any 16GB+ Mac |
| `audit-tower/` | Apertus 70B 4-bit — fully open stack for trust-critical use | 64GB+ Macs |
| `brain-cluster/` *(later)* | Multi-Mac MLX distributed for >512GB aggregate | 2× Studio households |

Recipe folder format:
```
<recipe-name>/
  README.md            # what it is, what it needs, known findings
  install.md           # the one-liner, what it does step by step
  install.sh           # fetches pieces, verifies checksums, builds .app
  config/              # server settings, quant pins, client templates
  findings.md          # field notes: measured tok/s, RAM headroom, quirks
```

## Capability matrix (stub — the core recommender)

| Unified memory | Recommended tier | Example |
|---|---|---|
| 16GB | ≤7B dense / ≤4B MoE, short context | Gemma-class |
| 32GB | 14–30B dense / 30B-class MoE | Devstral Small |
| 64GB | 40–70B dense 4-bit, 119B MoE 4-bit tight | Apertus 70B, Mistral Small 4 (constrained) |
| 128GB | 119B MoE 4-bit + resident extras + multi-user | Mistral Small 4 full household stack |
| 256GB+ | 400B-class 4-bit / multi-model resident | M7 Max class machines |

Rules to encode: GPU-addressable ≈ ⅔–¾ of total on macOS; KV cache grows with users×context; resident vs. load-on-demand; headroom margin; refuse beyond tier.

## Launcher ("14unch3r" analog) — v0.2 scope

- One window: installed recipes, model status, RAM headroom meter, per-user key status
- Menu-bar presence showing "Brain: running"
- Update check: recipe registry version vs. local; one-click refresh (re-verify checksums)
- Explicitly NOT in v0.2: fine-tuning, distillation pipelines, multi-machine clustering

## Distribution & trust

- Same posture as 1launcher: contains no model weights, fetches from official publisher repos, pinned checksums; transparent daily check, opt-out honored
- Recipes pin: engine version, model revision hash, quant variant — known-good triads only
- Unlisted models = unsupported by design

## Open questions

1. Engine choice per recipe: LM Studio vs. MLX vs. Ollama — standardize or per-recipe?
2. Fail-over (second Mac standby) in v0.1 or deferred?
3. Installer path: Homebrew formula vs. signed .pkg vs. curl|bash?
4. Recipe registry: in-repo table vs. versioned JSON polled by launcher?
5. Licensing: recipe code MIT/Apache; stance on MaaS-clause models (Mistral) in a self-hosting tool?

## Roadmap sketch

- **v0.1** — `household-assistant` + `coders-companion` recipes, one-line installs, README/findings culture carried over verbatim
- **v0.2** — Launcher window + capability matrix enforcement + update checks
- **v0.3** — `kids-homework-box` + `audit-tower`, trust-tier labeling
- **v0.4** — Multi-user hardening (keys, throttling), optional escalation-tier hook (generic OpenAI-compatible endpoint — Lumo API lands here)
- **later** — `brain-cluster` recipes; contribution guidelines
