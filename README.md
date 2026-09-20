# Genomes, Prompts, and Shiny

A talk about a family of Shiny applications and packages for computational
biology, built during a 2026 internship on the Shiny team at Posit.

**[Open the deck](https://www.samuelbharti.com/genomes-prompts-shiny/)**

Based on the talk given in September 2026, kept current since.

## What the talk covers

Ten applications and five packages came out of that summer. Some are tools a
researcher uses directly: exploring a hundred million single-cell perturbation
profiles, reviewing a variant across a dozen public databases, ranking candidate
genes against cited evidence. Others sit underneath and solve the problems that
kept recurring: validating biological identifiers, talking to external services
that all fail differently, rendering large scientific figures in a browser.

Each project has its own repository. The gallery at
[posit-dev/shiny-showcase-bioinformatics](https://github.com/posit-dev/shiny-showcase-bioinformatics)
indexes them all and links to a running deployment of each one.

## Building it

You need [Quarto](https://quarto.org). Nothing else.

```bash
quarto render index.qmd        # rebuild the deck
bash scripts/stage-site.sh     # assemble what Pages serves, into _deploy/
bash scripts/check-assets.sh   # check every referenced path resolves
```

The deck links its images and clips rather than inlining them. Inlining seven
demo recordings produced a 74 MB page, which suits a borrowed laptop and not a
website; linking them brings the page itself to about 50 KB. `assets/` therefore
has to travel with the deck, which is what the staging script is for.

`index.html` and `index_files/` are committed, because the deploy workflow stages
and uploads rather than rendering. Re-render and commit both when the source
changes.

## Deploying

Pushing to `main` deploys to GitHub Pages when the deck or its assets change.
`.github/workflows/deploy-site.yml` runs `stage-site.sh` and uploads the result.

## Preparing a deck for publication

Deck sources tend to carry `::: notes` blocks, which are rehearsal aids written
for one reader, and HTML comments, which Pandoc passes straight through to the
output where anyone can read them in view-source. Neither belongs on a public
site.

```bash
uv run scripts/make-public-deck.py source.qmd index.qmd --drop-image photo.jpg
```

The script strips both, turns `embed-resources` off, and refuses to write
anything if a single block survives. This deck was produced that way.

## Licence

Two licences, because this is part software and part writing.

- **MIT** for `scripts/`, `.github/` and `custom.scss`. See [LICENSE](LICENSE).
- **CC BY 4.0** for the deck and everything in `assets/`. See
  [LICENSE-CONTENT.md](LICENSE-CONTENT.md), which also records where each image
  came from.

## Not in this repository

No application code. Every application and package lives in its own repository,
listed in the gallery linked above.

No catalogue either. Duplicating that gallery here would mean maintaining a
second index of the same projects, and the copy is the one that goes stale.
