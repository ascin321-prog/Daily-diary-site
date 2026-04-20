# Daily Diary Site

一个适合长期运行的个人日记网站系统：

- Astro 静态站点
- Markdown 作为内容源
- GitHub 存储内容
- Vercel 自动部署
- Windows PowerShell 自动生成与发布
- Windows Task Scheduler 定时运行

## 线上地址

- Vercel: https://daily-diary-site.vercel.app

## 启动

```powershell
npm install
npm run dev
```

打开 http://localhost:4321

## 日记目录

```text
src/content/diary/
```

## JSON 输入协议

```json
{
  "title": "把网站真正跑起来的一天",
  "date": "2026-04-21",
  "slug": "2026-04-21-daily-review-site-online",
  "summary": "今天把个人日记站从本地推进到了可公开访问的状态，也补齐了自动发布链路。",
  "tags": ["日记", "复盘", "建站"],
  "body_markdown": "## 今日完成\n\n- 完成 Astro 日记站基础页面\n- 修复 Vercel 部署问题\n- 接通 GitHub 自动部署\n\n## 卡点与问题\n\n- WSL 和 Windows 混合 node_modules 导致本地构建不干净\n- Astro content collection 的 slug 行为和预期不完全一致\n\n## 今天的感受\n\n从方案走到真的上线，中间有不少小坑，但一步一步修通之后，心里会很稳。\n\n## 明天的一步\n\n把每日自动生成 JSON 的流程真正跑起来，减少手工维护成本。",
  "cover_image_path": "/images/default-cover.svg",
  "draft": false
}
```

## 每日复盘 Prompt 模板

固定模板文件：

```text
prompts/generate_review_prompt.txt
```

素材输入模板：

```text
inputs/daily-review-template.txt
```

素材输入示例：

```text
inputs/daily-review-example.txt
```

示例 JSON：

```text
examples/example-review.json
```

完整工作流文档：

```text
docs/openclaw-daily-review-workflow.md
```

## 自动脚本

### 1. 全自动生成每日复盘并发布

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_daily.ps1 -ProjectRoot "D:\projects\daily-diary-site"
```

### 2. 单独生成每日复盘 JSON

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\generate_review_json.ps1 -ProjectRoot "D:\projects\daily-diary-site"
```

### 3. 使用现成 JSON 生成并发布

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_daily.ps1 -ProjectRoot "D:\projects\daily-diary-site" -InputJsonPath "D:\projects\daily-diary-site\.tmp\2026-04-21-entry.json"
```

### 4. 单独从 JSON 渲染 Markdown

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render_entry_from_json.ps1 -JsonPath "D:\projects\daily-diary-site\.tmp\2026-04-21-entry.json" -ProjectRoot "D:\projects\daily-diary-site"
```

## Windows 任务计划程序建议

- 建议时间：每天 23:10
- 程序：`powershell.exe`
- 参数：

```text
-ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\run_daily.ps1" -ProjectRoot "D:\projects\daily-diary-site"
```

- 起始于：

```text
D:\projects\daily-diary-site
```
