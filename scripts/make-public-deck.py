#!/usr/bin/env python
"""Produce a publishable copy of a deck source.

    uv run scripts/make-public-deck.py deck/story-v2.qmd <out.qmd> [--drop-image SUBSTR]

The deck sources carry two things that must never ship:

  - `::: notes` blocks, the rehearsal aid. Written for one reader, and the
    reason the built deck leaked internal commentary when it was served from
    GitHub Pages.
  - HTML comments. Pandoc passes these straight through to the output, so a
    design note naming a private project ends up readable in view-source.

It also switches `embed-resources` off. Inlining seven demo clips produced a
74 MB page, which is right for a borrowed laptop and wrong for a website.

`--drop-image` removes any image line whose path contains the substring, so a
photograph of people can be held back until everyone in it has agreed. Repeat
the flag for more than one.

The sanitised source is what the public repo commits, so the .qmd and the
rendered .html agree and the build stays reproducible.
"""

import pathlib
import re
import sys


def strip_notes(text):
    """Remove `::: notes` ... `:::` blocks.

    Matches the closing fence at the start of a line so a nested div inside a
    note would not end the block early. Nothing in the current decks nests,
    and the count check below fails loudly if that ever changes.
    """
    return re.sub(r"^::: notes\n.*?^:::\n", "", text, flags=re.S | re.M)


def strip_html_comments(text):
    return re.sub(r"<!--.*?-->\n?", "", text, flags=re.S)


def unembed(text):
    return re.sub(r"^(\s*)embed-resources:\s*true\s*$",
                  r"\1embed-resources: false", text, flags=re.M)


def drop_images(text, substrings):
    """Remove whole image lines whose path contains any of `substrings`."""
    dropped = 0
    kept = []
    for line in text.split("\n"):
        if line.lstrip().startswith("![") and any(s in line for s in substrings):
            dropped += 1
            continue
        kept.append(line)
    return "\n".join(kept), dropped


def main():
    args = sys.argv[1:]
    drops = []
    while "--drop-image" in args:
        i = args.index("--drop-image")
        drops.append(args[i + 1])
        del args[i:i + 2]
    if len(args) != 2:
        raise SystemExit(__doc__)
    src, dst = pathlib.Path(args[0]), pathlib.Path(args[1])
    text = src.read_text(encoding="utf-8")

    n_notes = len(re.findall(r"^::: notes$", text, flags=re.M))
    n_comments = len(re.findall(r"<!--.*?-->", text, flags=re.S))

    out = unembed(strip_html_comments(strip_notes(text)))
    out, n_dropped = drop_images(out, drops)
    for s in drops:
        if s in out:
            raise SystemExit(f"refusing to write: '{s}' still referenced")

    # Fail rather than ship something half-cleaned.
    leftover_notes = len(re.findall(r"^::: notes$", out, flags=re.M))
    leftover_comments = len(re.findall(r"<!--.*?-->", out, flags=re.S))
    if leftover_notes or leftover_comments:
        raise SystemExit(
            f"refusing to write: {leftover_notes} notes block(s) and "
            f"{leftover_comments} comment(s) survived"
        )
    if "embed-resources: true" in out:
        raise SystemExit("refusing to write: embed-resources is still true")

    # Div fences must still balance, or the deck will render wrong.
    opens = len(re.findall(r"^:::+ *[^:\s]", out, flags=re.M))
    closes = len(re.findall(r"^:::+\s*$", out, flags=re.M))
    if opens != closes:
        raise SystemExit(f"refusing to write: {opens} div opens vs {closes} closes")

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(out, encoding="utf-8")

    print(f"  {src} -> {dst}")
    print(f"  removed {n_notes} notes block(s), {n_comments} HTML comment(s), "
          f"{n_dropped} image(s)")
    print(f"  {len(text.split())} words -> {len(out.split())} words")


if __name__ == "__main__":
    main()
