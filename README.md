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
  "title": "网站诞生日记",
  "date": "2026-04-20",
  "slug": "2026-04-20-website-birthday",
  "summary": "这是我的个人日记站上线的第一天。",
  "tags": ["日记", "建站", "记录"],
  "body_markdown": "今天是一个值得庆祝的日子。\n\n我终于有了一个真正属于自己的公开角落。",
  "cover_image_path": "/images/2026/04/2026-04-20-cover.svg",
  "draft": false
}
```

## 自动脚本

### 1. 占位自动生成

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_daily.ps1 -ProjectRoot "D:\projects\daily-diary-site"
```

### 2. 使用 JSON 生成并发布

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_daily.ps1 -ProjectRoot "D:\projects\daily-diary-site" -InputJsonPath "D:\projects\daily-diary-site\.tmp\2026-04-21-entry.json"
```

### 3. 单独从 JSON 渲染 Markdown

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
