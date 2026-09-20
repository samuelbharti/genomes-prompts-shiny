# Genomes, Prompts, and Shiny

A talk about a family of Shiny applications and packages for computational
biology, built during a 2026 internship on the Shiny team at Posit.

**[Open the deck](https://www.samuelbharti.com/genomes-prompts-shiny/)**

Based on the talk given in August 2026, kept current since.

## What the talk covers

Ten applications and five packages came out of that summer. Some are tools a
researcher opens and uses. The rest sit underneath them, solving the problems
that kept turning up across all of them.

## Resources

Everything below is open source. The ten applications are deployed as well, and
the [live gallery](https://posit-shiny-showcase-bioinformatics.share.connect.posit.cloud/)
opens each one in a browser.

### Ten applications

| Project | What it does |
|---|---|
| [tahoe-explorer](https://github.com/samuelbharti/tahoe-explorer) | Plan a reanalysis of Tahoe-100M before spending the compute |
| [plotomics-live](https://github.com/samuelbharti/plotomics-live) | Twenty-six biological figures, each rendered two ways |
| [variant-reviewer](https://github.com/samuelbharti/variant-reviewer) | One variant across eighteen public databases |
| [genescout](https://github.com/samuelbharti/genescout) | Evidence-review workbench for candidate genes |
| [gene-list-builder](https://github.com/samuelbharti/gene-list-builder) | A disease panel from seven sources, ranked and traceable |
| [recount-explorer](https://github.com/samuelbharti/recount-explorer) | recount3, browsed and exported without code |
| [de-explorer](https://github.com/posit-dev/shiny-showcase-bioinformatics/tree/main/apps/de-explorer) | Differential expression, from PCA to volcano to heatmap |
| [signature-scoring](https://github.com/posit-dev/shiny-showcase-bioinformatics/tree/main/apps/signature-scoring) | Pathway-level scores compared across groups |
| [drug-perturbation](https://github.com/posit-dev/shiny-showcase-bioinformatics/tree/main/apps/drug-perturbation) | Connectivity scoring against reference perturbations |
| [genome-explorer](https://github.com/posit-dev/shiny-showcase-bioinformatics/tree/main/apps/genome-explorer) | Recurrent variants in an interactive genomic view |

### Five packages

| Package | What it does | Published |
|---|---|---|
| [biobouncer](https://github.com/samuelbharti/biobouncer) | Whether a biological identifier means anything | CRAN, PyPI, npm |
| [biohttp](https://github.com/samuelbharti/biohttp) | How an application talks to an external service | CRAN |
| [bioclients](https://github.com/samuelbharti/bioclients) | What each of 29 biological services returns | CRAN |
| [plotomics](https://github.com/samuelbharti/plotomics) | One rendering core, three languages | CRAN, PyPI, npm |
| [biocohort](https://github.com/samuelbharti/biocohort) | How a study stays organised | CRAN |

### Related

- [posit-dev/shiny-showcase-bioinformatics](https://github.com/posit-dev/shiny-showcase-bioinformatics) collects every application and
  package, with documentation and citation information for each one.
- [Beyond Bootstrap: Building Custom Shiny UI with React](https://schloerke.com/presentation-2026-09-15-posit-conf-shinyreact/),
  Barret Schloerke's posit::conf 2026 talk on shinyreact, which Plotomics Live
  is built with.
- [shinyreact-showcase](https://github.com/samuelbharti/shinyreact-showcase), a
  gallery of worked shinyreact examples.

## Building it

You need [Quarto](https://quarto.org). Nothing else.

```bash
quarto render index.qmd        # rebuild the deck
bash scripts/stage-site.sh     # assemble what Pages serves, into _deploy/
bash scripts/check-assets.sh   # check the deck before it ships
```

The deck links its images and clips instead of inlining them. Inlining seven
demo recordings produced a 74 MB page. That suits a borrowed laptop and not a
website, and linking them brings the page itself to about 65 KB. `assets/`
therefore has to travel with the deck, which is what the staging script is
for.

`check-assets.sh` is the gate before a push. It confirms that every referenced
path resolves, that nothing is inlined, that no rehearsal note or author
comment survived the render, and that each outbound link opens in a new tab.
Pass `--links` to resolve every link over the network as well.

`index.html` and `index_files/` are committed, because the deploy workflow
stages and uploads instead of rendering. Re-render and commit both when the
source changes.

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
  licence, so those ten images are reproduced here, not relicensed. See
  [LICENSE-CONTENT.md](LICENSE-CONTENT.md) for the exception in full and for
  where every image came from.

## Not in this repository

No application code. Each project lives in its own repository or inside
`posit-dev/shiny-showcase-bioinformatics`, and every one is linked under
Resources above.

No catalogue either. Duplicating that gallery here would mean maintaining a
second index of the same projects, and the copy is the one that goes stale.

No memes and no team photograph. The meme templates are third-party images with
no licence to redistribute them, and the photograph shows seven identifiable
people who were never asked. Both are gitignored, so neither can arrive here by
accident.
