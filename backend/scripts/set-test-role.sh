#!/bin/sh
# Local development only. Register the account in the app before promoting it.
set -eu
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo 'Usage: sh backend/scripts/set-test-role.sh EMAIL ADMIN|DEPARTMENT|USER [DEPARTMENT_ID]' >&2
  exit 1
fi
case "$2" in ADMIN|DEPARTMENT|USER) ;; *) echo 'Invalid role' >&2; exit 1 ;; esac
department_id=${3:-}
if [ "$2" = DEPARTMENT ]; then
  case "$department_id" in ''|*[!0-9]*) echo 'DEPARTMENT requires an existing active department ID as third argument.' >&2; exit 1 ;; esac
fi
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$project_dir"
docker compose exec -T postgres sh -c 'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -v account_email="$1" -v account_role="$2" -v department_id="$3"' sh "$1" "$2" "$department_id" <<'SQL'
UPDATE app_users SET role = :'account_role', updated_at = CURRENT_TIMESTAMP,
 department_id = CASE WHEN :'account_role' = 'DEPARTMENT' THEN NULLIF(:'department_id','')::bigint ELSE NULL END
WHERE lower(email) = lower(:'account_email') AND active = true
AND (:'account_role' <> 'DEPARTMENT' OR EXISTS (SELECT 1 FROM departments WHERE id = NULLIF(:'department_id','')::bigint AND active))
RETURNING id, email, role, department_id;
SQL
echo 'UPDATE 1 means success; UPDATE 0 means check registered email and active department ID. Log out and log in again.'
