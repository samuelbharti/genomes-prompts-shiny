#!/usr/bin/env bash
# Assembles the deployable resource site into _deploy/. site/ itself only
# holds the pages, styles, script and JSON data; the deck and the assets the
# pages reference (thumbnails, demo clips, package logos) live at the repo
# root so large binaries aren't duplicated under site/. Both preview-site.sh
# and the GitHub Actions deploy workflow (.github/workflows/deploy-site.yml)
# call this, so the two never drift apart.
set -uo pipefail
cd "$(dirname "$0")/.."

DEPLOY="${1:-_deploy}"

rm -rf "$DEPLOY"
mkdir -p "$DEPLOY"
cp -r site/. "$DEPLOY/"
# The deck links its assets rather than inlining them, so thumbs/ and
# diagrams/ have to be staged too, along with the reveal.js support files.
mkdir -p "$DEPLOY/deck"
cp deck/story-v2.html "$DEPLOY/deck/"
cp -r deck/story-v2_files "$DEPLOY/deck/"
mkdir -p "$DEPLOY/assets/app-thumbnails/small" "$DEPLOY/assets/demo" "$DEPLOY/assets/logos" "$DEPLOY/assets/photos" "$DEPLOY/assets/thumbs" "$DEPLOY/assets/diagrams"
cp assets/app-thumbnails/*.png "$DEPLOY/assets/app-thumbnails/"
cp assets/app-thumbnails/small/*.png "$DEPLOY/assets/app-thumbnails/small/"
cp assets/demo/*.mp4 "$DEPLOY/assets/demo/"
cp assets/logos/*.svg "$DEPLOY/assets/logos/" 2>/dev/null || true
cp assets/thumbs/*.png "$DEPLOY/assets/thumbs/"
cp assets/diagrams/*.svg "$DEPLOY/assets/diagrams/"
cp assets/photos/sb-headshot-1.jpeg assets/photos/sb-headshot-2.jpeg "$DEPLOY/assets/photos/"

# Cache-bust style.css and app.js: GitHub Pages serves them with
# Cache-Control: max-age=600, and the URL never changes otherwise, so a
# visitor who loaded the site in the last 10 minutes can keep rendering an
# old stylesheet against new markup (this is exactly how the headshot
# photos once showed up full-size: the CSS that sizes them hadn't taken
# effect yet in a cached copy). Appending the commit hash as a query string
# gives every deploy a fresh URL.
VERSION=$(git rev-parse --short HEAD 2>/dev/null || date +%s)
sed -i \
  -e "s#href=\"style\.css\"#href=\"style.css?v=$VERSION\"#" \
  -e "s#src=\"app\.js\"#src=\"app.js?v=$VERSION\"#" \
  "$DEPLOY"/*.html

echo "staged: $DEPLOY (version $VERSION)"
