#!/usr/bin/env bash
# Build the site and publish it to the Opalstack static app "puneknot" (account navincc).
# Usage: deploy/opalcc/deploy.sh            build, upload, health-check
#        deploy/opalcc/deploy.sh --dry-run  build and show what would change; upload nothing
set -euo pipefail

REMOTE="${OPALCC_SSH:-opalcc}"              # SSH alias or user@host; CI sets navincc@opal2.opalstack.com
REMOTE_ROOT="/home/navincc/apps/puneknot"   # document root of the static app
SITE_URL="https://puneknot.com"
PYTHON="${PYTHON:-python3}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DRY=()
if [[ "${1:-}" == "--dry-run" ]]; then DRY=(--dry-run --itemize-changes); fi

# Build for the domain root. A leftover BASE_URL would break every link in production.
env -u BASE_URL TZ=Asia/Kolkata "$PYTHON" build.py

# Preflight: refuse to upload an obviously broken build.
test -s _site/index.html
test -s _site/static/site.css
test -s _site/talks/index.html
talks_built=$(find _site/talks -mindepth 2 -name index.html | wc -l)
talks_src=$(find talks -name '*.md' | wc -l)
[[ "$talks_built" -eq "$talks_src" ]] || { echo "built $talks_built talk pages from $talks_src files" >&2; exit 1; }

# The app is created in the Opalstack panel; never create its directory from here.
ssh "$REMOTE" "test -d '$REMOTE_ROOT'" || { echo "$REMOTE_ROOT does not exist on $REMOTE: create the static app first (see deploy/opalcc/README.md)" >&2; exit 1; }

# Everything under the document root is build output, so --delete is safe.
rsync -az --delete --delay-updates "${DRY[@]}" _site/ "$REMOTE:$REMOTE_ROOT/"

if [[ ${#DRY[@]} -gt 0 ]]; then echo "dry run: nothing uploaded"; exit 0; fi

# Health check. Until DNS points here this fails; set SKIP_HEALTH=1 for that period only.
if [[ "${SKIP_HEALTH:-0}" == "1" ]]; then echo "uploaded; health check skipped"; exit 0; fi
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$SITE_URL/talks/")
[[ "$code" == "200" ]] || { echo "health check: $SITE_URL/talks/ returned $code" >&2; exit 1; }
echo "deployed: $SITE_URL"
