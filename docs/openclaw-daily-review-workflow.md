# OpenClaw 每日复盘工作流

## 目标

每天为个人公开日记站生成一篇“每日复盘”JSON，并自动发布到网站。

完整链路：

1. 准备当天素材
2. 用 Prompt 模板让 OpenClaw 输出 JSON
3. 保存到 `.tmp/YYYY-MM-DD-entry.json`
4. 运行 `scripts/run_daily.ps1`
5. 脚本自动渲染 Markdown、校验、提交 GitHub
6. Vercel 自动部署

## 固定文件

- Prompt 模板：`prompts/generate_review_prompt.txt`
- 素材输入模板：`inputs/daily-review-template.txt`
- 素材输入示例：`inputs/daily-review-example.txt`
- JSON 示例：`examples/example-review.json`

## 推荐日常操作

### 方案 A：半自动

1. 打开 `inputs/daily-review-template.txt`
2. 填入当天素材
3. 把内容连同 `prompts/generate_review_prompt.txt` 一起交给 OpenClaw
4. 让 OpenClaw 只输出 JSON
5. 保存为：

```text
D:\projects\daily-diary-site\.tmp\YYYY-MM-DD-entry.json
```

6. 执行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site" -InputJsonPath "D:\projects\daily-diary-site\.tmp\YYYY-MM-DD-entry.json"
```

### 方案 B：占位回退

如果当天没有准备素材，可以直接执行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site"
```

脚本会自动生成占位日记并发布。

## 定时任务建议

如果你希望每天固定提醒自己复盘，可以这样安排：

- 22:50，先手动整理素材
- 23:00，调用 OpenClaw 生成 JSON
- 23:10，任务计划程序执行 `run_daily.ps1`

## 发布前检查

- JSON 是否为合法对象
- `date` 是否为当天日期
- `summary` 是否不超过 120 字
- `body_markdown` 是否包含四段结构
- `cover_image_path` 是否有效

## 风险提示

- OpenClaw 生成 JSON 时，必须严格限制只输出 JSON
- 如果 JSON 中 slug 非法，渲染脚本会直接失败
- 若当天同名内容已存在，脚本会阻止重复覆盖
