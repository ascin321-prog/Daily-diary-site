#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
OUTPUT_PATH="${2:-}"
AGENT_ID="${AGENT_ID:-main}"
DATE_STRING="$(date +%F)"
YESTERDAY="$(date -d 'yesterday' +%F)"

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
YESTERDAY_MEMORY="$(cat "$WORKSPACE_ROOT/memory/${YESTERDAY}.md" 2>/dev/null || true)"
GIT_LOG="$(git -C "$PROJECT_ROOT" log --pretty=format:'%h %ad %s' --date=short -n 5 2>/dev/null || true)"
GIT_STATUS="$(git -C "$PROJECT_ROOT" status --short 2>/dev/null || true)"
AGENT_ACTIVITY="$(python3 - "$WORKSPACE_ROOT" "$DATE_STRING" "$YESTERDAY" <<'PY'
from pathlib import Path
import sys
workspace = Path(sys.argv[1])
days = sys.argv[2:]
agents_root = workspace / 'agents'
blocks = []
if agents_root.exists():
    for agent_dir in sorted(agents_root.iterdir()):
        if not agent_dir.is_dir():
            continue
        progress_path = agent_dir / 'PROGRESS.md'
        mem_dir = agent_dir / 'memory'
        progress_text = progress_path.read_text(encoding='utf-8', errors='ignore') if progress_path.exists() else ''
        recent_mems = []
        if mem_dir.exists():
            for mem in sorted(mem_dir.glob('*.md')):
                if any(day in mem.name for day in days):
                    text = mem.read_text(encoding='utf-8', errors='ignore')
                    if any(token in text for token in ['今日完成', '当前第一优先级', '最近完成', '当前任务目标']):
                        recent_mems.append((mem.name, text))
        active_progress = progress_text and '暂无' not in progress_text and any(token in progress_text for token in ['当前第一优先级', '当前任务目标', '进行中', '最近完成'])
        if not recent_mems and not active_progress:
            continue
        block = [f'### agent: {agent_dir.name}']
        if active_progress:
            lines = [line for line in progress_text.splitlines() if line.strip()][:30]
            block.append('[PROGRESS]')
            block.extend(lines)
        for name, text in recent_mems[:2]:
            lines = [line for line in text.splitlines() if line.strip()][:36]
            block.append(f'[MEMORY {name}]')
            block.extend(lines)
        blocks.append('\n'.join(block))
print('\n\n'.join(blocks))
PY
)"

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
6. 标题不要带日期前缀，直接根据复盘内容总结一个自然标题。
7. slug 仍然保留日期前缀，方便归档。
8. 优先吸纳所有近两日有工作进展的 agent 素材，但只提炼适合公开发布的内容。
9. 如果适合生成封面图，请给出与正文一致的标题和摘要，不要编造图片细节；后续脚本会负责生成安全的封面文件。

【当前 PROGRESS.md】
$PROGRESS_CONTENT

【今日记忆】
$TODAY_MEMORY

【昨日记忆】
$YESTERDAY_MEMORY

【长期记忆】
$LONG_MEMORY_CONTENT

【近两日活跃 agents 素材】
$AGENT_ACTIVITY

【最近 Git 提交】
$GIT_LOG

【当前 Git 状态】
$GIT_STATUS"

RAW="$(openclaw agent --local --agent "$AGENT_ID" --message "$PROMPT" --timeout 600)"
python3 - "$RAW" "$OUTPUT_PATH" "$DATE_STRING" <<'PY'
import json, re, sys
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
obj['title'] = re.sub(r'^\d{4}-\d{2}-\d{2}[\s:：-]*', '', str(obj['title'])).strip() or '今日复盘'
obj.setdefault('slug', f'{date_string}-daily-review')
obj.setdefault('cover_image_path', '/images/default-cover.svg')
obj['date'] = date_string
obj['draft'] = bool(obj['draft'])
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
print(output_path)
PY
if [[ -x "$PROJECT_ROOT/scripts/generate_cover_svg.sh" ]]; then
  bash "$PROJECT_ROOT/scripts/generate_cover_svg.sh" "$PROJECT_ROOT" "$OUTPUT_PATH" >/dev/null || true
fi
