#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
cd "$PROJECT_ROOT"

bash scripts/run_daily.sh "$PROJECT_ROOT"
