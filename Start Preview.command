#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$project_dir/scripts/flutterw" run -d web-server --web-hostname=127.0.0.1 --web-port=5190 --dart-define=ANALYSIS_MODE=mock --dart-define=API_BASE_URL=http://127.0.0.1:8082
