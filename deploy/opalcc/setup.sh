#!/usr/bin/env bash
# One-time setup ON the Opalstack server, after the static app "puneknot" exists in the panel:
#
#   git clone https://github.com/ngkabra/puneknot.git ~/puneknot-src
#   ~/puneknot-src/deploy/opalcc/setup.sh
#
# Safe to run again: it only adds what is missing.
set -euo pipefail

SRC="/home/navincc/puneknot-src"
APP_ROOT="/home/navincc/apps/puneknot"
PYTHON_BIN="/usr/local/bin/python3.12"      # the system python3 here is 3.6, which is too old
CRON_LINE="*/10 * * * * $SRC/deploy/opalcc/update.sh >/dev/null 2>&1"

[[ -d "$SRC/.git" ]] || { echo "clone the repository to $SRC first" >&2; exit 1; }
[[ -d "$APP_ROOT" ]] || { echo "create the static app 'puneknot' in the Opalstack panel first" >&2; exit 1; }

[[ -x "$SRC/.venv/bin/python" ]] || "$PYTHON_BIN" -m venv "$SRC/.venv"

if ! crontab -l 2>/dev/null | grep -qF "$SRC/deploy/opalcc/update.sh"; then
  { crontab -l 2>/dev/null || true; echo "$CRON_LINE"; } | crontab -
  echo "cron entry added"
fi

"$SRC/deploy/opalcc/update.sh" --force
