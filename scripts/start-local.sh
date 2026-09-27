#!/bin/sh
# Starts only this template's database and local backend.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
command -v docker >/dev/null || { echo 'Install/open Docker Desktop first.' >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo 'Open Docker Desktop and wait until it is running.' >&2; exit 1; }
if [ ! -f .env ]; then
  umask 077
  db_password=$(openssl rand -hex 24)
  (set -C; printf 'DB_USERNAME=chitwan_template\nDB_PASSWORD=%s\nDB_PORT=54330\n' "$db_password" > .env)
  echo 'Created an ignored .env with a new local database password.'
fi
set -a
. ./.env
set +a
: "${DB_PASSWORD:?Set DB_PASSWORD in .env}"
export DB_URL="jdbc:postgresql://127.0.0.1:${DB_PORT:-54330}/chitwan_care_template"
export DB_USERNAME="${DB_USERNAME:-chitwan_template}"
export SERVER_PORT=8082
export SERVER_ADDRESS=127.0.0.1
docker compose up -d --wait postgres
sh backend/scripts/init-auth.sh
cd backend
exec ./mvnw spring-boot:run
