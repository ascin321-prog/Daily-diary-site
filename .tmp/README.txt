这个目录用于保存每日临时 JSON 输入文件。

建议命名格式：
- 2026-04-21-entry.json
- 2026-04-22-entry.json

推荐流程：
1. 使用 prompts/generate_review_prompt.txt + inputs/daily-review-template.txt 让 OpenClaw 生成 JSON
2. 保存到本目录
3. 执行 scripts/run_daily.ps1 并传入 -InputJsonPath
