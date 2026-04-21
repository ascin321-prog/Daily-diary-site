#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/mnt/d/projects/daily-diary-site}"
JSON_PATH="${2:?missing json path}"

python3 - "$PROJECT_ROOT" "$JSON_PATH" <<'PY'
import json
import re
import sys
from pathlib import Path
from datetime import datetime

project_root = Path(sys.argv[1]).resolve()
json_path = Path(sys.argv[2]).resolve()
obj = json.loads(json_path.read_text(encoding='utf-8'))
date_string = obj.get('date') or datetime.now().strftime('%Y-%m-%d')
title = str(obj.get('title') or '每日复盘')
summary = str(obj.get('summary') or '')
month_dir = project_root / 'public' / 'images' / date_string[:4] / date_string[5:7]
month_dir.mkdir(parents=True, exist_ok=True)
cover_name = f"{date_string}-cover.svg"
cover_path = month_dir / cover_name
bg1, bg2, accent = '#f7f1e8', '#eadfce', '#8a6f52'
lines = [title[:18]]
if summary:
    segs = re.findall(r'.{1,20}', summary[:40])
    lines.extend(segs[:2])
text_y = 180
text_blocks = []
for i, line in enumerate(lines):
    text_blocks.append(f'<text x="80" y="{text_y + i*46}" font-size="{34 if i == 0 else 20}" fill="#4b3f34" font-family="PingFang SC, Microsoft YaHei, sans-serif">{line}</text>')
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="900" viewBox="0 0 1600 900">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="{bg1}"/>
      <stop offset="100%" stop-color="{bg2}"/>
    </linearGradient>
  </defs>
  <rect width="1600" height="900" fill="url(#bg)"/>
  <circle cx="1320" cy="170" r="140" fill="{accent}" fill-opacity="0.14"/>
  <circle cx="1450" cy="760" r="220" fill="{accent}" fill-opacity="0.08"/>
  <rect x="72" y="92" width="920" height="420" rx="36" fill="#fffaf4" fill-opacity="0.72"/>
  <text x="80" y="130" font-size="18" fill="#8a6f52" font-family="PingFang SC, Microsoft YaHei, sans-serif">{date_string} · 自动生成封面</text>
  {''.join(text_blocks)}
</svg>'''
cover_path.write_text(svg, encoding='utf-8')
obj['cover_image_path'] = f"/images/{date_string[:4]}/{date_string[5:7]}/{cover_name}"
json_path.write_text(json.dumps(obj, ensure_ascii=False), encoding='utf-8')
print(obj['cover_image_path'])
PY
