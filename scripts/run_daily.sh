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

EXPECTED_SLUG="$(python3 - "$JSON_PATH" <<'PY'
import json, sys, re
from pathlib import Path
raw = Path(sys.argv[1]).read_text(encoding='utf-8')
obj = json.loads(raw)
date_string = obj.get('date', '')
title = str(obj.get('title', ''))
preferred = obj.get('slug')
slug = preferred or re.sub(r'[^a-z0-9\s-]', '', title.lower())
slug = re.sub(r'\s+', '-', slug)
slug = re.sub(r'-+', '-', slug).strip('-') or 'daily-note'
if date_string and not slug.startswith(f'{date_string}-'):
    slug = f'{date_string}-{slug}'
print(slug)
PY
)"
EXPECTED_FILE="$PROJECT_ROOT/src/content/diary/${EXPECTED_SLUG}.md"

if [[ -f "$EXPECTED_FILE" ]]; then
  echo "检测到目标日记已存在，跳过渲染: $EXPECTED_FILE"
  FILE_PATH="$EXPECTED_FILE"
else
  FILE_PATH="$(bash scripts/render_entry_from_json.sh "$JSON_PATH" "$PROJECT_ROOT")"
fi

bash scripts/validate_entry.sh "$FILE_PATH"
bash scripts/publish.sh "$PROJECT_ROOT"

echo "每日流程执行完成: $FILE_PATH"
