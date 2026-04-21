param(
    [string]$TaskName = "OpenClaw-Daily-Diary",
    [string]$ProjectRootWindows = "D:\projects\daily-diary-site",
    [string]$ProjectRootWsl = "/mnt/d/projects/daily-diary-site",
    [string]$WslExe = "wsl.exe",
    [string]$StartTime = "23:10"
)

$ErrorActionPreference = "Stop"

$runScript = "$ProjectRootWsl/scripts/run_daily_wsl.sh"
$wslCommand = "cd $ProjectRootWsl && /bin/bash $runScript"
$action = New-ScheduledTaskAction -Execute $WslExe -Argument "-e bash -lc `"$wslCommand`""
$trigger = New-ScheduledTaskTrigger -Daily -At $StartTime
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Run OpenClaw daily diary via WSL" -Force | Out-Null
Write-Host "已创建/更新计划任务: $TaskName"
Write-Host "执行命令: $WslExe -e bash -lc '$wslCommand'"
