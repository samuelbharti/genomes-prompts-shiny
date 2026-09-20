# Genomes, Prompts, and Shiny

A talk and a resource site about a family of Shiny applications and packages for
computational biology, built during a 2026 internship on the Shiny team at Posit.

Ten applications and five packages came out of that summer. Each one has its own
repository; this one holds the presentation and the index that points at them
all.

## What is here

| What | Where | How to open |
|---|---|---|
| Resource site | `site/` | <https://www.samuelbharti.com/genomes-prompts-shiny/> |
| The talk, as presented | `deck/story-v2.html` | Open it in a browser |

The site lists every application and package with its source, its documentation,
its DOI and, where one exists, a running deployment. `site/data/apps.json` and
`site/data/packages.json` hold that data, so adding a project means editing one
JSON file rather than any HTML.

The deck is the talk given in September 2026. It is kept as it was delivered, so
it describes the state of the work at that time. Several things it calls
undeployed now run on Connect Cloud, and two packages have become five.

## Building it

You need [Quarto](https://quarto.org) to render the deck, and Python for the
staging script. Nothing else.

```bash
bash scripts/preview-site.sh      # serve the site at localhost:8000
quarto render deck/story-v2.qmd   # rebuild the deck
bash scripts/check-assets.sh      # check every referenced path resolves
```

`site/index.html` fetches `site/data/*.json` at load time, which `file://`
blocks, so double-clicking it shows empty cards. Use the preview script.

`scripts/stage-site.sh` assembles the site, the deck and the assets they
reference into `_deploy/`. Both the preview script and the deploy workflow call
it, so local preview and production cannot drift apart.

## Deploying

Pushing to `main` deploys to GitHub Pages, for changes touching `site/`,
`deck/` or the asset folders. `.github/workflows/deploy-site.yml` runs
`stage-site.sh` and uploads what it produces.

## Preparing a deck for publication

Deck sources carry `::: notes` blocks, which are rehearsal aids written for one
reader, and HTML comments, which Pandoc passes straight through to the output
where anyone can read them in view-source. Neither belongs on a public site.

```bash
uv run scripts/make-public-deck.py deck/story-v2.qmd out.qmd --drop-image photo.jpg
```

The script strips both, turns `embed-resources` off so the page links its assets
instead of inlining 74 MB of video, and refuses to write anything if a single
block survives. Run it against a private source and commit what it produces.

## Licence

Two licences, because this is part software and part writing.

- **MIT** for `scripts/`, `site/`, `.github/` and `deck/custom.scss`. See [LICENSE](LICENSE).
- **CC BY 4.0** for the deck and everything in `assets/`. See [LICENSE-CONTENT.md](LICENSE-CONTENT.md),
  which also records where each image came from.

## Not in this repository

No application code. Every app and package lives in its own repository, listed on
the site. Nothing here needs a server, a database or a running R session beyond
Quarto.

Earlier drafts of the talk are not here either. They were never presented, and
keeping one version of a talk is clearer than keeping six.
