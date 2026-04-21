#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
BRANCH="${BRANCH:-main}"

exec_step() {
  echo "执行: $*"
  "$@"
}

cd "$PROJECT_ROOT"
COMMIT_DATE="$(date +%F)"
COMMIT_MESSAGE="chore(diary): publish ${COMMIT_DATE}"

exec_step git pull origin "$BRANCH"
exec_step git add .

if [[ -z "$(git status --porcelain)" ]]; then
  echo "没有检测到可提交变更，跳过 commit/push。"
  exit 0
fi

exec_step git commit -m "$COMMIT_MESSAGE"
exec_step git push origin "$BRANCH"

echo "发布完成: $COMMIT_MESSAGE"
