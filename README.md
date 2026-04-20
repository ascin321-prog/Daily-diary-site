# Daily Diary Site

一个适合长期运行的个人日记网站系统：

- Astro 静态站点
- Markdown 作为内容源
- GitHub 存储内容
- Vercel 自动部署
- Windows PowerShell 自动生成与发布
- Windows Task Scheduler 定时运行

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

## 自动脚本

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_daily.ps1 -ProjectRoot "D:\projects\daily-diary-site"
```
