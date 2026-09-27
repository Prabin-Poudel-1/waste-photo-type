#!/bin/sh
set -eu
backend_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
auth_file="$backend_dir/auth-local.properties"
if [ -e "$auth_file" ]; then
  echo 'Local JWT configuration already exists; preserved.'
  exit 0
fi
umask 077
jwt_value=$(openssl rand -base64 48)
(set -C; printf 'JWT_SECRET=%s\n' "$jwt_value" > "$auth_file")
echo 'Created private local JWT configuration. Do not commit this file.'
