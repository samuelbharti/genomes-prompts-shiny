# Genomes, Prompts, and Shiny

A talk about a family of Shiny applications and packages for computational
biology, built during a 2026 internship on the Shiny team at Posit.

**[Open the deck](https://www.samuelbharti.com/genomes-prompts-shiny/)**

Based on the talk given in September 2026, kept current since.

## What the talk covers

Ten applications and five packages came out of that summer. Some are tools a
researcher uses directly: exploring a hundred million single-cell perturbation
profiles, reviewing a variant across eighteen public databases, ranking
candidate genes against cited evidence. Others sit underneath and solve the
problems that kept recurring: validating biological identifiers, talking to
external services that all fail differently, rendering large scientific figures
in a browser.

Each project has its own repository. The gallery at
[posit-dev/shiny-showcase-bioinformatics](https://github.com/posit-dev/shiny-showcase-bioinformatics)
indexes them all and links to a running deployment of each one.

## Building it

You need [Quarto](https://quarto.org). Nothing else.

```bash
quarto render index.qmd        # rebuild the deck
bash scripts/stage-site.sh     # assemble what Pages serves, into _deploy/
bash scripts/check-assets.sh   # gate it before publishing, see below
```

The deck links its images and clips rather than inlining them. Inlining seven
demo recordings produced a 74 MB page. That suits a borrowed laptop and not a
website, and linking them brings the page itself to about 65 KB. `assets/`
therefore has to travel with the deck, which is what the staging script is
for.

`index.html` and `index_files/` are committed, because the deploy workflow stages
and uploads rather than rendering. Re-render and commit both when the source
changes.

## Deploying

Pushing to `main` deploys to GitHub Pages when the deck or its assets change.
`.github/workflows/deploy-site.yml` runs `stage-site.sh` and uploads the result.

## Preparing a deck for publication

Deck sources tend to carry `::: notes` blocks, which are rehearsal aids written
for one reader, and HTML comments. Pandoc passes those straight through to the
output, where anyone can read them in view-source. Neither belongs on a public
site.

```bash
uv run scripts/make-public-deck.py source.qmd index.qmd --drop-image photo.jpg
```

The script strips both, turns `embed-resources` off, and refuses to write
anything if a single block survives. This deck was produced that way.

## Licence

Two licences, because this is part software and part writing.

- **MIT** for `scripts/`, `.github/` and `custom.scss`. See [LICENSE](LICENSE).
- **CC BY 4.0** for the deck and for `assets/`, with one exception:
  `assets/app-thumbnails/` is rendered from a Posit repository that carries no
  licence, so those ten images are reproduced here rather than relicensed. See
  [LICENSE-CONTENT.md](LICENSE-CONTENT.md) for the exception in full and for
  where every image came from.

## Not in this repository

No application code. Every application and package lives in its own repository,
listed in the gallery linked above.

No catalogue either. Duplicating that gallery here would mean maintaining a
second index of the same projects, and the copy is the one that goes stale.

No memes and no team photograph. The meme templates are third-party images with
no licence to redistribute them, and the photograph shows seven identifiable
people who were never asked. Both are gitignored, so neither can arrive here by
accident.
