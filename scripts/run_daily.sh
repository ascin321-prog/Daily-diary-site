#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
INPUT_JSON_PATH="${2:-}"
BRANCH="${BRANCH:-main}"

exec_step() {
  echo "执行: $*"
  "$@"
}

cd "$PROJECT_ROOT"
DATE_STRING="$(date +%F)"
TMP_DIR="$PROJECT_ROOT/.tmp"
mkdir -p "$TMP_DIR"

exec_step git pull origin "$BRANCH"

JSON_PATH="$INPUT_JSON_PATH"
if [[ -z "$JSON_PATH" ]]; then
  JSON_PATH="$TMP_DIR/${DATE_STRING}-entry.json"
  exec_step bash scripts/generate_review_json.sh "$PROJECT_ROOT" "$JSON_PATH"
fi

FILE_PATH="$(bash scripts/render_entry_from_json.sh "$JSON_PATH" "$PROJECT_ROOT")"
bash scripts/validate_entry.sh "$FILE_PATH"
bash scripts/publish.sh "$PROJECT_ROOT"

echo "每日流程执行完成: $FILE_PATH"
