param(
    [string]$ProjectRoot = "D:\projects\daily-diary-site"
)

$ErrorActionPreference = "Stop"

function Exec-Step {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    Write-Host "执行: $Command $($Arguments -join ' ')" -ForegroundColor Cyan
    & $Command @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "命令执行失败: $Command $($Arguments -join ' ')"
    }
}

Set-Location -LiteralPath $ProjectRoot

$commitDate = Get-Date -Format "yyyy-MM-dd"
$commitMessage = "chore(diary): publish $commitDate"

Exec-Step -Command "git" -Arguments @("pull", "origin", "main")
Exec-Step -Command "git" -Arguments @("add", ".")

$hasChanges = git status --porcelain
if ([string]::IsNullOrWhiteSpace(($hasChanges | Out-String))) {
    Write-Host "没有检测到可提交变更，跳过 commit/push。" -ForegroundColor Yellow
    exit 0
}

Exec-Step -Command "git" -Arguments @("commit", "-m", $commitMessage)
Exec-Step -Command "git" -Arguments @("push", "origin", "main")

Write-Host "发布完成: $commitMessage" -ForegroundColor Green
