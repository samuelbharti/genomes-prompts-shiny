#!/usr/bin/env bash
# Local preview of the resource site. Stages the same layout the deploy
# workflow builds, then serves it: site/index.html links to the deck and to
# assets that live outside site/, and fetches site/data/*.json at load time.
# Both need a real server -- opening site/index.html straight from disk 404s
# the deck/asset links, and file:// blocks the JSON fetch outright.
set -uo pipefail
cd "$(dirname "$0")/.."

PORT="${1:-8000}"

bash scripts/stage-site.sh _deploy

PY=$(command -v python3 || command -v python) || {
  echo "no python on PATH"; exit 1; }

echo "Serving _deploy on http://localhost:$PORT (Ctrl+C to stop)"
cd _deploy && "$PY" -m http.server "$PORT"
