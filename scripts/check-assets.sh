#!/usr/bin/env bash
# Sanity gate for the deck before it goes to Pages.
#
# The deck is the repository: index.qmd at the root, index.html committed beside
# it, and assets/ linked rather than inlined. That last point inverts what this
# script used to check. With embed-resources off, a base64 payload in the output
# is a regression, not the goal, and every referenced path has to survive the
# trip into _deploy/ because nothing is carried inside the HTML.
#
# Checks 4 and 5 are the ones with consequences. Everything the deck publishes
# is readable in view-source, so a rehearsal note or an HTML comment that
# survives the render is public the moment the workflow runs.
set -uo pipefail
cd "$(dirname "$0")/.."

QMD="index.qmd"
HTML="index.html"
[ -f "$QMD" ]  || { echo "no $QMD here"; exit 1; }
[ -f "$HTML" ] || { echo "no $HTML, run: quarto render $QMD"; exit 1; }
fail=0

echo "== 1. every referenced asset exists on disk =="
n=0; missing=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  n=$((n + 1))
  [ -f "$p" ] || { echo "  MISSING $p"; missing=1; fail=1; }
done < <(grep -ohE '(assets|index_files)/[A-Za-z0-9._/-]+\.(png|jpg|jpeg|svg|gif|mp4|css|js|woff2?)' "$HTML" | sort -u)
[ "$missing" -eq 0 ] && echo "  ok, $n referenced paths all resolve"

echo "== 2. assets are linked, not inlined =="
# embed-resources: false is deliberate. Inlining the seven demo clips produced a
# 74 MB page, which suits a borrowed laptop and not a website.
b64=$(grep -c 'data:image/[a-z]*;base64' "$HTML")
if [ "$b64" -gt 0 ]; then echo "  INLINED: $b64 base64 payloads, embed-resources has been turned back on"; fail=1
else echo "  ok, no base64 payloads"; fi
bytes=$(wc -c < "$HTML" | tr -d ' ')
echo "  page: $((bytes / 1024)) KB"

echo "== 3. the rendered page matches the source =="
# A cheap staleness proxy. The workflow uploads the committed HTML and never
# runs Quarto, so an uncommitted render ships the previous deck silently.
qs=$(grep -cE '^## ' "$QMD")
hs=$(grep -o 'class="slide level2"' "$HTML" | wc -l)
hh=$(grep -o '<section' "$HTML" | wc -l)
echo "  $qs headings in source, $hs level-2 sections and $hh sections in output"
[ "$hh" -ge "$qs" ] || { echo "  STALE: fewer sections than headings, re-render and commit"; fail=1; }

echo "== 4. nothing rehearsal-only survived into the output =="
for pat in 'HONESTY' 'ONE JOB' 'class="notes"'; do
  c=$(grep -c -- "$pat" "$HTML")
  if [ "$c" -gt 0 ]; then echo "  LEAK: $c occurrence(s) of $pat"; fail=1
  else echo "  ok, no $pat"; fi
done

# HTML comments are the subtle half. Pandoc passes an author's comment straight
# through to the output, where it is readable in view-source, and that is how a
# design note naming a private project got published once already.
#
# Test the SOURCE, because a clean source cannot leak one. The output carries
# comments Quarto's own template emits, so those are named here rather than
# counted: anything not on this list is printed for a human to judge.
src=$(grep -c -- '<!--' "$QMD")
if [ "$src" -gt 0 ]; then
  echo "  LEAK: $src HTML comment(s) in $QMD, run make-public-deck.py"; fail=1
else
  echo "  ok, no HTML comments in the source"
fi
unknown=$(grep -o '<!--[^>]*-->' "$HTML" | grep -vE '<!-- *(reveal\.js plugins|htmlwidget|/?html_preserve)' | sort -u)
if [ -n "$unknown" ]; then
  echo "  comments in the output that are not Quarto boilerplate, check each one:"
  echo "$unknown" | sed 's/^/    /'
  fail=1
else
  echo "  ok, output comments are all Quarto's own"
fi

echo "== 5. withheld material is not referenced =="
for pat in 'assets/memes' 'assets/photos' 'shinyshadcn' 'shinymui' 'lifescience-shiny-gallery'; do
  c=$(grep -ci -- "$pat" "$HTML")
  # The thank-you slide's generated id contains "shiny-team", which is not the
  # photograph. Match the path, not the words.
  if [ "$c" -gt 0 ]; then echo "  REFERENCED: $pat ($c)"; fail=1; fi
done
echo "  ok, nothing withheld is referenced"

echo "== 6. outbound links =="
links=$(grep -oE 'href="https://[^"]+"' "$HTML" | sed 's/href="//;s/"$//' | grep -v creativecommons | sort -u)
lc=$(printf '%s\n' "$links" | grep -c . )
tc=$(grep -o 'target="_blank"' "$HTML" | wc -l)
echo "  $lc external links, $tc open in a new tab"
# A link that replaces the deck loses the reader's place mid-presentation.
[ "$lc" -le "$tc" ] || { echo "  some links would navigate away from the deck"; fail=1; }
if [ "${1:-}" = "--links" ]; then
  echo "  resolving each one (slow, network):"
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    code=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 25 "$l")
    [ "$code" = "200" ] && echo "    ok  $l" || { echo "    $code $l"; fail=1; }
  done <<< "$links"
fi

echo "== 7. committed but unused assets (dead weight, not an error) =="
u=0
while IFS= read -r f; do
  grep -qF -- "$f" "$HTML" || { echo "  unused: $f"; u=$((u + 1)); }
done < <(find assets -type f | sed 's|\\|/|g' | sort)
echo "  ($u unused)"

echo
[ "$fail" -eq 0 ] && echo "PASS" || echo "FAIL, see above"
exit "$fail"
