# Auster — local AI on Apple Silicon, one recipe per use

The free pieces for running AI at home already exist: engines, open model weights, clients. Putting
them together takes a weekend in Terminal. Auster aims to do that assembly once, as curated recipes.
A pasted line installs a recipe, and the result is something a household can leave running.

**Status: building the first release (v0.1.0). Nothing is released yet, so nothing here can be installed
yet.** The first recipe, a household assistant, installed from zero on the development Mac on 2026-11-28,
and its installer and built-in update are tested; the release is next.

Auster began from the pattern of [1launcher](https://github.com/macgameport/1launcher), which does
the same for Windows games on the Mac, and stands on its own from there. The name is Latin for the south wind.

This is an independent project. It is not affiliated with, endorsed by or supported by Mistral AI, the
Swiss AI Initiative, Apple, Hugging Face or the llama.cpp project, and their names and trademarks
belong to them.

## What it is meant to do

- **A recipe is one folder:** a use, a model, the exact file to fetch, the engine and its settings, and
  the findings measured on real Macs.
- **Auster contains no model weights.** Each file comes from its publisher and must match a size and a
  checksum recorded here before it is used.
- **Models come from a short list.** A model that is not on it is unsupported by design.
- **It looks at the Mac it is on and adapts.** What fits in memory, how a model is swapped and how many
  earlier builds stay on disk are worked out on that Mac.
- **It updates itself, on your word:** one small check a day, a plain account of what changed,
  and nothing downloaded or installed without a yes.

## Principles

- Each platform gets the engine that is best on it, decided by measurement.
- Fewest parts on the household's Mac.
- Nothing is fetched or installed without a yes, and nothing about the household is sent anywhere.
- A claim about what runs where is a measurement, with the Mac it was measured on.

## Measured so far

On one Mac only, so far: a Mac Studio with an Apple M5 Max and 64 GB of memory, on macOS 27, with
llama.cpp's engine `b12359`, from 2026-11-26 to 2026-11-28. The household assistant's two builds, in the
order Auster tries them:

| Build | File | Writing, one person (empty context / at 16K) | Two people at once, each | Memory at 32K of context |
|---|---|---|---|---|
| Mistral Small 4, Unsloth's UD-IQ3_S | 44.4 GB | 81 / 50 tokens a second | 60 tokens a second | about 41.8 GiB |
| Magistral Small 2509, Mistral's Q4_K_M | 14.3 GB | 38 / 31 tokens a second | 31 tokens a second | about 18.3 GiB |

The first install from zero, on 2026-11-28, took 24 min 47 s with the 44.4 GB download; the recipe's
test passed 12 of 12, and the server answered its check on the home network at 75 tokens a second. How
each figure was measured: [docs/phase-1.md](docs/phase-1.md) ("The three side by side") and
[docs/phase-2.md](docs/phase-2.md) (section 13).

## Where to read

| File | What |
|---|---|
| [SPEC.md](SPEC.md) | The phases and where things stand |
| [docs/concept.md](docs/concept.md) | The starting concept |
| [docs/shortlist.md](docs/shortlist.md) | The engines and models considered, with sizes and sources |
| [docs/plans/v0.1.md](docs/plans/v0.1.md) | The plan for the first release, reviewed before it was built, with what was built |
| [docs/phase-1.md](docs/phase-1.md) | The household assistant built by hand first, and what was measured |
| [docs/phase-2.md](docs/phase-2.md) | The facts the first release rests on, and its first real install |
| [CHANGELOG.md](CHANGELOG.md) | What each release changed, once there is one |

See also the [security policy](SECURITY.md), the [code of conduct](CODE_OF_CONDUCT.md) and
[how to contribute](CONTRIBUTING.md).

## Licence

Auster's own files are under the [MIT licence](LICENSE). Each model and engine has its own licence,
which its recipe names.
