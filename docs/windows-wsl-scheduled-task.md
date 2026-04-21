# Windows + WSL 每晚自动运行配置

这是当前项目的推荐定时运行方式。

原则：
- Windows 负责“定时唤起”
- WSL 负责“真正执行 daily diary 流程”
- 不再依赖 PowerShell 作为主业务执行链路

## 最佳路径

使用 Windows 任务计划程序，触发 `wsl.exe` 执行项目里的 WSL 脚本：

```text
wsl.exe -e bash -lc "cd /mnt/d/projects/daily-diary-site && /bin/bash /mnt/d/projects/daily-diary-site/scripts/run_daily_wsl.sh"
```

## 一键安装计划任务

在 Windows PowerShell 中执行：

```powershell
powershell -ExecutionPolicy Bypass -File "D:\projects\daily-diary-site\scripts\install_daily_task_windows.ps1"
```

默认会创建：
- 任务名：`OpenClaw-Daily-Diary`
- 执行时间：每天 `23:10`

## 手动验证

先在 Windows 里手动执行这条命令，确认能通：

```powershell
wsl.exe -e bash -lc "cd /mnt/d/projects/daily-diary-site && /bin/bash /mnt/d/projects/daily-diary-site/scripts/run_daily_wsl.sh"
```

## 成功验收标准

运行后至少检查这几项：

1. `.tmp/YYYY-MM-DD-entry.json` 已生成
2. `src/content/diary/` 下出现或更新当天日记
3. GitHub 有新 commit
4. Vercel deployment 成功
5. 线上页面可访问

## 查看任务是否安装成功

在 Windows PowerShell 中：

```powershell
Get-ScheduledTask -TaskName "OpenClaw-Daily-Diary"
```

## 手动触发一次任务

```powershell
Start-ScheduledTask -TaskName "OpenClaw-Daily-Diary"
```

## 删除任务

```powershell
Unregister-ScheduledTask -TaskName "OpenClaw-Daily-Diary" -Confirm:$false
```
