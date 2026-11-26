# Auster — local AI on Apple Silicon, one recipe per use

The free pieces for running AI at home already exist: engines, open model weights, clients. Putting
them together takes a weekend in Terminal. Auster aims to do that assembly once, as curated recipes.
A pasted line installs a recipe, and the result is something a household can leave running.

**Status: planning. Nothing here can be installed yet.** This repository holds the plan and the
research behind it. The first recipe, a household assistant, is being built by hand before it is
packaged.

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

## Where to read

| File | What |
|---|---|
| [SPEC.md](SPEC.md) | The phases and where things stand |
| [docs/concept.md](docs/concept.md) | The starting concept |
| [docs/shortlist.md](docs/shortlist.md) | The engines and models considered, with sizes and sources |
| [docs/plans/v0.1.md](docs/plans/v0.1.md) | The plan for the first release: a draft, one section written and reviewed |
| [docs/phase-1.md](docs/phase-1.md) | What has been done by hand so far, and what was measured |
| [CHANGELOG.md](CHANGELOG.md) | What each release changed, once there is one |

See also the [security policy](SECURITY.md), the [code of conduct](CODE_OF_CONDUCT.md) and
[how to contribute](CONTRIBUTING.md).

## Licence

Auster's own files are under the [MIT licence](LICENSE). Each model and engine has its own licence,
which its recipe names.
