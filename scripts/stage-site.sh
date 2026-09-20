#!/usr/bin/env bash
# Assemble what GitHub Pages serves: the rendered deck, its support files, and
# the images it links. The deck links its assets rather than inlining them, so
# assets/ has to travel with it.
#
# The deploy workflow calls this, and so can you, which is why the two cannot
# drift apart.
set -uo pipefail
cd "$(dirname "$0")/.."
DEPLOY="${1:-_deploy}"

rm -rf "$DEPLOY"
mkdir -p "$DEPLOY"

cp index.html "$DEPLOY/"
cp -r index_files "$DEPLOY/"
cp -r assets "$DEPLOY/"

echo "staged: $DEPLOY ($(find "$DEPLOY" -type f | wc -l) files)"
