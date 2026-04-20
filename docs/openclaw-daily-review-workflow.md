# OpenClaw 每日复盘工作流

## 目标

每天由 OpenClaw 自动回看当天与近期的任务、记忆和经历，自主生成一篇适合公开发布的“每日复盘”JSON，并自动发布到网站。

完整链路：

1. 定时任务触发 `scripts/run_daily.ps1`
2. `run_daily.ps1` 调用 `scripts/generate_review_json.ps1`
3. `generate_review_json.ps1` 自动读取近期记忆、任务状态、git 记录
4. OpenClaw 基于上下文生成 `.tmp/YYYY-MM-DD-entry.json`
5. 脚本自动渲染 Markdown、校验、提交 GitHub
6. Vercel 自动部署

## 自动素材来源

脚本默认读取：

- agent 的 `PROGRESS.md`
- agent 的 `MEMORY.md`
- `memory/YYYY-MM-DD.md`（今天）
- `memory/YYYY-MM-DD.md`（昨天）
- 最近几天的 daily memory 汇总
- 最近若干条 git commit
- 当前 git status

默认 agent 目录推断为：

```text
D:\projects\..\agents\code-engineer
```

## 固定文件

- Prompt 模板：`prompts/generate_review_prompt.txt`
- 自动生成脚本：`scripts/generate_review_json.ps1`
- JSON 渲染脚本：`scripts/render_entry_from_json.ps1`
- JSON 示例：`examples/example-review.json`

## 推荐日常操作

### 方案 A：全自动，推荐

每天定时执行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site"
```

脚本会自动：

1. 读取近期上下文
2. 调用 OpenClaw 生成每日复盘 JSON
3. 渲染 Markdown
4. 校验
5. 提交 GitHub
6. 触发 Vercel 自动部署

### 方案 B：保留手动 JSON 注入

如果你想手动指定某份 JSON，也可以执行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site" -InputJsonPath "D:\projects\daily-diary-site\.tmp\YYYY-MM-DD-entry.json"
```

## 定时任务建议

建议每天 23:10 执行，让当天上下文尽量完整。

程序：

```text
powershell.exe
```

参数：

```text
-ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site"
```

起始于：

```text
D:\projects\daily-diary-site
```

## 发布前检查

- OpenClaw 输出是否为合法 JSON
- `date` 是否与当天一致
- `summary` 是否不超过 120 字
- `body_markdown` 是否包含四段结构
- `cover_image_path` 是否有效

## 风险提示

- 自动复盘依赖记忆文件与任务轨迹的质量
- OpenClaw 只能基于已有上下文提炼，不应凭空编造私人事件
- 如果返回 JSON 中 slug 非法，渲染脚本会直接失败
- 若当天同名内容已存在，脚本会阻止重复覆盖
