#!/usr/bin/env bash
# Sanity gate. Depends on ONE convention:
#   deck image refs are always ../assets/...   (relative to deck/)
#   landing-page refs are always assets/...    (relative to repo root)
#
# Check 5 is the important one, it is the only check that PROVES the deck is
# genuinely self-contained, which is the whole reason for embed-resources: true.
set -uo pipefail
cd "$(dirname "$0")/.."

# Defaults to the shipping deck. Pass a basename to check another one, e.g.
#   bash scripts/check-assets.sh story-v2
NAME="${1:-comp-bio-apps}"
DECK="deck/$NAME.qmd"
HTML="deck/$NAME.html"
PDF="deck/$NAME.pdf"
[ -f "$DECK" ] || { echo "no such deck: $DECK"; exit 1; }
fail=0

# macOS and Linux ship python3; the Windows installer puts it on PATH as python.
PY=$(command -v python3 || command -v python) || {
  echo "no python on PATH, checks 5a and 6 cannot run"; exit 1; }

echo "== 1. deck image refs resolve from deck/ =="
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if [ -f "deck/$p" ]; then echo "  ok      $p"; else echo "  MISSING $p"; fail=1; fi
done < <(grep -ohE '\.\./assets/[A-Za-z0-9._/-]+\.(png|jpg|jpeg|svg|gif)' "$DECK" | sort -u)

echo "== 2. index refs resolve from repo root =="
if [ -f index.qmd ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if [ -f "$p" ]; then echo "  ok      $p"; else echo "  MISSING $p"; fail=1; fi
  done < <(grep -ohE '(^|[^.])assets/[A-Za-z0-9._/-]+\.(png|jpg|jpeg|svg|gif)' index.qmd \
           | grep -oE 'assets/[A-Za-z0-9._/-]+\.(png|jpg|jpeg|svg|gif)' | sort -u)
else
  echo "  (index.qmd not built yet, skipped)"
fi

echo "== 3. truncated / empty downloads =="
# smallest legitimate asset is thumbs/signatures.png at ~9 KB
found=$(find assets -type f \( -size -1k -o -empty \) 2>/dev/null)
[ -n "$found" ] && { echo "$found" | sed 's/^/  SUSPECT: /'; fail=1; } || echo "  none"
found=$(find assets -name '*.part' 2>/dev/null)
[ -n "$found" ] && { echo "$found" | sed 's/^/  PARTIAL: /'; fail=1; } || true

echo "== 4. committed but unused assets (dead weight, not an error) =="
n=0
while IFS= read -r f; do
  b=$(basename "$f")
  grep -qr -- "$b" "$DECK" index.qmd 2>/dev/null || { echo "  unused: $f"; n=$((n+1)); }
done < <(find assets -type f ! -name 'MEMES.md' ! -name '.DS_Store' | sort)
echo "  ($n unused)"

echo "== 5a. did custom.scss actually reach the deck? =="
# Do NOT grep the HTML for these selectors. embed-resources inlines stylesheets
# as `<link href="data:text/css,...">` with a PERCENT-encoded payload, so a
# plain grep returns a false negative even when the rule is present and working.
if [ -f "$HTML" ]; then
  "$PY" scripts/extract-css.py "$HTML" \
    .thumbwall .walls .kicker .payoff .heroline .chip .pills \
    .withmeme .memeinline .bignums .act .verbatim \
    grid-template-columns || fail=1
  # .codepair and .memeslide are still defined in custom.scss but the current
  # deck no longer uses them, so they are deliberately not probed here.
else
  echo "  $HTML not rendered yet"; fail=1
fi

echo "== 5. is the rendered deck ACTUALLY self-contained? =="
if [ -f "$HTML" ]; then
  # Exclude JS template literals (src="${e}"), those live inside reveal.js's
  # own bundled loader and are not image references.
  ext=$(grep -o 'src="[^"]*"' "$HTML" | grep -v '^src="data:' | grep -v '\${' | sort -u)
  if [ -n "$ext" ]; then echo "$ext" | sed 's/^/  EXTERNAL REF: /'; fail=1; else echo "  ok, every src= is a data: URI"; fi
  bg=$(grep -o 'data-background-image="[^"]*"' "$HTML" | grep -v 'data:' | sort -u)
  if [ -n "$bg" ]; then echo "$bg" | sed 's/^/  UNEMBEDDED BACKGROUND: /'; fail=1; else echo "  ok, backgrounds embedded"; fi
  gf=$(grep -c 'fonts.googleapis.com' "$HTML")
  echo "  googlefonts refs: $gf  (0 = fully offline; >0 = will try the network)"
else
  echo "  $HTML not rendered yet"; fail=1
fi

echo "== 6. size + page-count gate =="
ls -lh "$HTML" "$PDF" 2>/dev/null | sed 's/^/  /'
if [ -f "$HTML" ]; then
  # 100 MB is not an aesthetic choice, it is GitHub's hard per-file limit: a
  # push carrying a bigger blob is rejected outright. So this gate now means
  # "the deck can still be committed", which is the only size fact that has
  # consequences. GitHub also WARNS above 50 MB and the deck is past that; the
  # warning is expected and is not what this check is for.
  #
  # The earlier 12 MB limit told you to downscale assets, which was the wrong
  # trade: the deck is presented from local Chrome, where sharpness is what the
  # room sees and load time comes off a local disk.
  #
  # The real cost of a large deck is git history, not load time. Every render
  # writes another full blob. If that becomes a problem, the fix is to stop
  # inlining the video, and the escape hatch is written up in the .demovid
  # comment in deck/story-v2.qmd.
  #
  # wc -c, not stat: `stat -f%z` is BSD-only and `stat -c%s` is GNU-only, so
  # either one silently produces an empty size on the other platform.
  LIMIT_MB=100
  bytes=$(wc -c < "$HTML" | tr -d ' ')
  mb=$(( (bytes * 10 + 524288) / 1048576 ))   # tenths of a MB, rounded
  if [ "$bytes" -gt $((LIMIT_MB * 1048576)) ]; then
    echo "  OVER GATE: $((mb / 10)).$((mb % 10)) MB > ${LIMIT_MB} MB, GitHub will refuse the push"; fail=1
  else echo "  ok, $((mb / 10)).$((mb % 10)) MB, under the ${LIMIT_MB} MB gate"; fi
fi
slides=$(grep -cE '^## ' "$DECK")
echo "  content slides in qmd: $slides (+1 title = $((slides + 1)) expected PDF pages)"
if [ -f "$PDF" ]; then
  # NOT mdls: Spotlight metadata lags a freshly written file and will report the
  # previous build's page count.
  pages=$("$PY" -c "import re,sys;print(len(re.findall(rb'/Type\s*/Page[^s]',open(sys.argv[1],'rb').read())))" "$PDF")
  want=$((slides + 1))
  if [ "$pages" -eq "$want" ]; then echo "  ok, PDF is $pages pages"
  else echo "  PAGE COUNT MISMATCH: PDF has $pages, expected $want (a slide is spilling; set pdf-max-pages-per-slide: 1)"; fail=1; fi
fi

echo
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL, see above"
exit $fail
