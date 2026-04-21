#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="${1:?missing markdown file path}"

python3 - "$FILE_PATH" <<'PY'
import re
import sys
from pathlib import Path
from datetime import datetime

path = Path(sys.argv[1]).resolve()
if not path.exists():
    raise SystemExit(f"文件不存在: {path}")
if path.suffix not in {'.md', '.markdown'}:
    raise SystemExit(f"文件扩展名必须是 .md 或 .markdown，当前为: {path.suffix}")
text = path.read_text(encoding='utf-8')
if not text.strip():
    raise SystemExit(f"Markdown 文件内容为空: {path}")
m = re.match(r'^---\s*\n(.*?)\n---\s*\n(.+)$', text, re.S)
if not m:
    raise SystemExit('frontmatter 格式不正确，必须以 --- 开始并结束。')
frontmatter, body = m.group(1), m.group(2)
if not body.strip():
    raise SystemExit('正文内容为空。')
required = ['title', 'date', 'slug', 'summary', 'draft']
for field in required:
    if not re.search(rf'(?m)^{field}\s*:\s*.+$', frontmatter):
        raise SystemExit(f'frontmatter 缺少必填字段: {field}')

def extract(name, pattern):
    mm = re.search(pattern, frontmatter, re.M)
    return mm.group(1) if mm else None

title = extract('title', r'^title\s*:\s*"?(.*?)"?\s*$')
date = extract('date', r'^date\s*:\s*"?(.*?)"?\s*$')
slug = extract('slug', r'^slug\s*:\s*"?(.*?)"?\s*$')
summary = extract('summary', r'^summary\s*:\s*"?(.*?)"?\s*$')
draft = extract('draft', r'^draft\s*:\s*(true|false)\s*$')
if not title or not title.strip():
    raise SystemExit('title 不能为空。')
try:
    datetime.strptime(date, '%Y-%m-%d')
except Exception:
    raise SystemExit('date 必须是 yyyy-MM-dd 格式。')
if not slug or not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug):
    raise SystemExit('slug 必须为小写英文、数字和连字符组合。')
if not summary or not summary.strip():
    raise SystemExit('summary 不能为空。')
if len(summary) > 220:
    raise SystemExit('summary 建议不超过 220 个字符。')
if draft not in {'true', 'false'}:
    raise SystemExit('draft 必须为 true 或 false。')
normalized = str(path).replace('\\', '/')
if '/src/content/diary/' not in normalized:
    raise SystemExit('Markdown 文件必须位于 src/content/diary/ 目录下。')
print(f'校验通过: {path}')
PY
