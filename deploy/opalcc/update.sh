#!/usr/bin/env bash
# Runs ON the Opalstack server (account navincc), from cron and by hand.
# Pulls main from GitHub, rebuilds the site, and publishes it to the static app's document root.
#
# Usage: update.sh           do nothing unless GitHub has a new commit or the date has changed
#        update.sh --force   rebuild and publish regardless
set -euo pipefail

SRC="/home/navincc/puneknot-src"            # checkout of https://github.com/ngkabra/puneknot
APP_ROOT="/home/navincc/apps/puneknot"      # document root of the Opalstack static app
STATE="$SRC/.deploy"                        # lock, stamp and log; ignored by git
PYTHON="$SRC/.venv/bin/python"

mkdir -p "$STATE"
exec 9>"$STATE/lock"
flock -n 9 || exit 0                        # another run is in progress

cd "$SRC"                                   # git here is too old for `git -C`
# Explicit refspec: git 1.8.3 here does not update origin/main on a plain `git fetch origin main`.
git fetch --quiet origin +refs/heads/main:refs/remotes/origin/main
remote_rev=$(git rev-parse origin/main)
today=$(TZ=Asia/Kolkata date +%F)
stamp="$remote_rev $today"

# The date is part of the stamp so that a talk moves from "next" to the archive overnight.
if [[ "${1:-}" != "--force" && -f "$STATE/stamp" && "$(cat "$STATE/stamp")" == "$stamp" ]]; then
  exit 0
fi

log() { echo "$(TZ=Asia/Kolkata date '+%F %T') $*" | tee -a "$STATE/deploy.log"; }

# The checkout is disposable: local edits on the server are discarded.
git reset --quiet --hard "$remote_rev"

# The app is created in the Opalstack panel; never create its directory from here.
[[ -d "$APP_ROOT" ]] || { log "FAILED ${remote_rev:0:7}: $APP_ROOT does not exist"; exit 1; }

if ! "$PYTHON" -m pip install --quiet --disable-pip-version-check -r requirements.txt >>"$STATE/deploy.log" 2>&1 \
   || ! env -u BASE_URL TZ=Asia/Kolkata "$PYTHON" build.py >>"$STATE/deploy.log" 2>&1; then
  log "FAILED ${remote_rev:0:7}: build error, live site left as it was"
  exit 1
fi

# Preflight: refuse to publish an obviously broken build.
talks_built=$(find _site/talks -mindepth 2 -name index.html | wc -l)
talks_src=$(find talks -name '*.md' | wc -l)
if [[ ! -s _site/index.html || ! -s _site/static/site.css || "$talks_built" -ne "$talks_src" ]]; then
  log "FAILED ${remote_rev:0:7}: preflight ($talks_built pages from $talks_src talk files), live site left as it was"
  exit 1
fi

# Everything under the document root is build output, so --delete is safe.
rsync -a --delete --delay-updates _site/ "$APP_ROOT/"
echo "$stamp" > "$STATE/stamp"
log "published ${remote_rev:0:7}"
