#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
OUTPUT_PATH="${2:-}"
AGENT_ID="${AGENT_ID:-main}"
DATE_STRING="$(date +%F)"

if [[ -z "$OUTPUT_PATH" ]]; then
  OUTPUT_PATH="$PROJECT_ROOT/.tmp/${DATE_STRING}-entry.json"
fi
mkdir -p "$(dirname "$OUTPUT_PATH")"

PROMPT_FILE="$PROJECT_ROOT/prompts/generate_review_prompt.txt"
[[ -f "$PROMPT_FILE" ]] || { echo "缺少 prompt 模板: $PROMPT_FILE" >&2; exit 1; }

WORKSPACE_ROOT="/home/barry/.openclaw/workspace"
PROGRESS_CONTENT="$(cat "$WORKSPACE_ROOT/PROGRESS.md" 2>/dev/null || true)"
LONG_MEMORY_CONTENT="$(cat "$WORKSPACE_ROOT/MEMORY.md" 2>/dev/null || true)"
TODAY_MEMORY="$(cat "$WORKSPACE_ROOT/memory/${DATE_STRING}.md" 2>/dev/null || true)"
YESTERDAY_MEMORY="$(cat "$WORKSPACE_ROOT/memory/$(date -d 'yesterday' +%F).md" 2>/dev/null || true)"
GIT_LOG="$(git -C "$PROJECT_ROOT" log --pretty=format:'%h %ad %s' --date=short -n 5 2>/dev/null || true)"
GIT_STATUS="$(git -C "$PROJECT_ROOT" status --short 2>/dev/null || true)"

PROMPT="$(cat "$PROMPT_FILE")

今天日期：$DATE_STRING

请你不要向我提问，也不要要求我补充素材。
请你直接根据下面提供的近期上下文，自主提炼今天和近期的任务推进、情绪变化、关键经历，写成一篇适合公开发布的每日复盘 JSON。

重点要求：
1. 只输出合法 JSON。
2. 不要输出代码块，不要输出解释文字。
3. 复盘要基于已有上下文，不要凭空捏造具体私人事件。
4. 可以提炼情绪和状态变化，但必须克制、真实。
5. body_markdown 必须包含四段：今日完成、卡点与问题、今天的感受、明天的一步。
6. 如果没有专用封面图，cover_image_path 使用 /images/default-cover.svg。

【当前 PROGRESS.md】
$PROGRESS_CONTENT

【今日记忆】
$TODAY_MEMORY

【昨日记忆】
$YESTERDAY_MEMORY

【长期记忆】
$LONG_MEMORY_CONTENT

【最近 Git 提交】
$GIT_LOG

【当前 Git 状态】
$GIT_STATUS"

RAW="$(openclaw agent --local --agent "$AGENT_ID" --message "$PROMPT" --timeout 600)"
python3 - "$RAW" "$OUTPUT_PATH" "$DATE_STRING" <<'PY'
import json, sys
raw, output_path, date_string = sys.argv[1], sys.argv[2], sys.argv[3]
start = raw.find('{')
end = raw.rfind('}')
if start < 0 or end < start:
    raise SystemExit(f'OpenClaw 未返回合法 JSON。原始输出:\n{raw}')
text = raw[start:end+1]
obj = json.loads(text)
for field in ['title', 'date', 'summary', 'body_markdown', 'draft']:
    if field not in obj:
        raise SystemExit(f'返回 JSON 缺少字段: {field}')
obj.setdefault('cover_image_path', '/images/default-cover.svg')
obj.setdefault('slug', f'{date_string}-daily-review')
obj['date'] = date_string
obj['draft'] = bool(obj['draft'])
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
print(output_path)
PY
