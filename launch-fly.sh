#!/usr/bin/env bash
set -euo pipefail

# Helper script (non-destructive) to remind you of the basic Fly.io commands
# for this repo. It prints commands instead of running them so you can review
# and adapt them to your own app names/regions.
#
# See README.md for the full deployment notes.

APP_NAME="${1:-}"
MYSQL_APP_NAME="${2:-}"

echo ""
echo "React + Flask (Dockerfile.combo) — Fly.io quick commands"
echo ""

if [[ -z "${APP_NAME}" ]]; then
  echo "Usage:"
  echo "  ./launch-fly.sh <app-name> [mysql-app-name]"
  echo ""
  echo "Example:"
  echo "  ./launch-fly.sh my-web-app my-mysql"
  echo ""
  exit 0
fi

echo "App:"
echo "  fly launch --no-deploy --name \"${APP_NAME}\" --dockerfile Dockerfile.combo"
echo "  fly deploy --app \"${APP_NAME}\" --dockerfile Dockerfile.combo"
echo ""

if [[ -n "${MYSQL_APP_NAME}" ]]; then
  echo "MySQL (separate Fly app; uses fly.mysql.toml):"
  echo "  # edit fly.mysql.toml: set app = '${MYSQL_APP_NAME}', primary_region, env MYSQL_DATABASE/MYSQL_USER"
  echo "  fly volumes create mysqldata --size 10 -a \"${MYSQL_APP_NAME}\""
  echo "  fly secrets set MYSQL_PASSWORD='<app-user-password>' MYSQL_ROOT_PASSWORD='<root-password>' -a \"${MYSQL_APP_NAME}\""
  echo "  fly deploy -a \"${MYSQL_APP_NAME}\" -c fly.mysql.toml"
  echo ""
  echo "Point the web app at MySQL via DATABASE_URL:"
  echo "  fly secrets set DATABASE_URL=\"mysql+mysqlconnector://<user>:<pass>@${MYSQL_APP_NAME}.internal:3306/<db>?auth_plugin=mysql_native_password\" -a \"${APP_NAME}\""
  echo ""
fi

