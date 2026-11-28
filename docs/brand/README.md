# Auster's mark and app icon

The mark is a gear whose inside is a shell's growth rings, with a pearl where the rings meet. Auster is
Latin for the south wind, and the name sounds like oyster; the gear is the works. Chosen 2026-11-28.

## What is here

| Folder | What |
|---|---|
| `mark/` | The mark by itself, as SVG |
| `app-icon/` | A macOS app icon made from it, with the drawings it was made from |

How the files are named:

- **south:** the rings meet at the bottom. This is the main mark.
- **side:** the rings meet at the lower left. It goes with "Auster Build", the technical site.
- **bold:** a cut with fewer teeth and rings, for 64 pixels and smaller, where the detailed one blurs.
- **light** is for light backgrounds and **dark** for dark ones.

| | On light | On dark |
|---|---|---|
| Lines | `#1f2a30` | `#e8e4da` |
| Pearl | `#1f5f7a` | `#8fc3d9` |
| Icon tile | `#f4f1ea` | `#1f2a30` |

## The app icon

- `Auster-dark.icns` is the dark tile and `Auster-light.icns` the light one. Each holds every size from
  16 to 1024 pixels; the sizes up to 64 use the bold cut.
- `app-icon-…-1024.png` is the largest size as a plain picture. The four SVG files are the drawings.
- An `.icns` file has one look. Having macOS change the icon between light and dark is done with a
  different kind of file, made in Apple's Icon Composer. That has not been made, and how it behaves was
  not checked here.
- **Nothing uses the icon yet.** It is kept here, not under `assets/`, because every file under
  `assets/` is checked against the registry. Wiring it into an app belongs to the installer's plan.

## Not here

The logos with lettering ("Auster Works" and "Auster Build") stay with the website until the licences
of the typefaces they are set in are settled.

## Where these come from

A script kept with the website's source draws all of them, and that copy is the original. Change the
script there and copy the results here; do not edit these files by hand.

The mark and the icon come under this repository's MIT licence, like everything else here. They are art,
not a brand identity, and no trademark is sought (the owner, 2026-11-28).
