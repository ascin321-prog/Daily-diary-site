#!/usr/bin/env bash
set -euo pipefail

JSON_PATH="${1:?missing json path}"
PROJECT_ROOT="${2:-/mnt/d/projects/daily-diary-site}"

python3 - "$JSON_PATH" "$PROJECT_ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path
from datetime import datetime

json_path = Path(sys.argv[1]).resolve()
project_root = Path(sys.argv[2]).resolve()
if not json_path.exists():
    raise SystemExit(f'JSON 文件不存在: {json_path}')
raw = json_path.read_text(encoding='utf-8').strip()
if not raw:
    raise SystemExit(f'JSON 文件为空: {json_path}')
try:
    entry = json.loads(raw)
except Exception:
    raise SystemExit('JSON 解析失败，请检查格式。')
for field in ['title', 'date', 'summary', 'body_markdown', 'draft']:
    if field not in entry:
        raise SystemExit(f'缺少必填字段: {field}')
if not str(entry['title']).strip():
    raise SystemExit('title 不能为空')
try:
    datetime.strptime(entry['date'], '%Y-%m-%d')
except Exception:
    raise SystemExit('date 必须是 yyyy-MM-dd 格式')
summary = str(entry['summary'])
if not summary.strip():
    raise SystemExit('summary 不能为空')
if len(summary) > 220:
    raise SystemExit('summary 不能超过 220 个字符')
body = str(entry['body_markdown'])
if not body.strip():
    raise SystemExit('body_markdown 不能为空')
if not isinstance(entry['draft'], bool):
    raise SystemExit('draft 必须是布尔值')

def slugify(date_string, title, preferred):
    slug = preferred or re.sub(r'[^a-z0-9\s-]', '', title.lower())
    slug = re.sub(r'\s+', '-', slug)
    slug = re.sub(r'-+', '-', slug).strip('-') or 'daily-note'
    if not slug.startswith(f'{date_string}-'):
        slug = f'{date_string}-{slug}'
    return slug

slug = slugify(entry['date'], entry['title'], entry.get('slug'))
if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', slug):
    raise SystemExit('slug 非法，必须为小写字母、数字和连字符')

diary_dir = project_root / 'src' / 'content' / 'diary'
diary_dir.mkdir(parents=True, exist_ok=True)
file_path = diary_dir / f'{slug}.md'
if file_path.exists():
    raise SystemExit(f'同名日记已存在: {file_path}')
cover = entry.get('cover_image_path') or '/images/default-cover.svg'
if not cover.startswith('/images/'):
    raise SystemExit('cover_image_path 必须以 /images/ 开头')
tags = entry.get('tags') or []
tag_text = '[' + ', '.join(json.dumps(str(t), ensure_ascii=False) for t in tags) + ']'
markdown = f'''---
title: {json.dumps(str(entry['title']), ensure_ascii=False)}
date: {json.dumps(entry['date'])}
slug: {json.dumps(slug)}
summary: {json.dumps(summary, ensure_ascii=False)}
cover: {json.dumps(cover)}
tags: {tag_text}
draft: {'true' if entry['draft'] else 'false'}
---

{body}
'''
file_path.write_text(markdown, encoding='utf-8')
print(file_path)
PY
