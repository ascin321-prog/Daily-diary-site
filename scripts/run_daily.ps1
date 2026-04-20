param(
    [string]$ProjectRoot = "D:\projects\daily-diary-site",
    [string]$Branch = "main",
    [string]$InputJsonPath = ""
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

$today = Get-Date
$dateString = $today.ToString("yyyy-MM-dd")
$year = $today.ToString("yyyy")
$month = $today.ToString("MM")

$diaryDir = Join-Path $ProjectRoot "src\content\diary"
$imageDir = Join-Path $ProjectRoot "public\images\$year\$month"
$tempDir = Join-Path $ProjectRoot ".tmp"

if (-not (Test-Path -LiteralPath $diaryDir)) {
    New-Item -ItemType Directory -Path $diaryDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $imageDir)) {
    New-Item -ItemType Directory -Path $imageDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

Exec-Step -Command "git" -Arguments @("pull", "origin", $Branch)

$jsonPathToUse = $InputJsonPath
if ([string]::IsNullOrWhiteSpace($jsonPathToUse)) {
    $defaultCover = "/images/default-cover.svg"
    $dateCoverSvg = "/images/$year/$month/$dateString-cover.svg"
    $dateCoverDisk = Join-Path $ProjectRoot ("public" + $dateCoverSvg.Replace('/', '\\'))
    if (Test-Path -LiteralPath $dateCoverDisk) {
        $defaultCover = $dateCoverSvg
    }

    $payload = [ordered]@{
        title = "今日小记"
        date = $dateString
        slug = "$dateString-daily-note"
        summary = "这是 $dateString 自动生成的一篇日记，占位内容可替换为真实 OpenClaw 输出。"
        tags = @("日记", "自动生成")
        body_markdown = "今天是 $dateString。`n`n这篇内容由 Windows 定时任务自动触发生成。`n`n你后续可以把这里替换成 OpenClaw 输出的真实日记正文，例如晨间回顾、晚间总结、当天感受与记录。"
        cover_image_path = $defaultCover
        draft = $false
    }

    $jsonPathToUse = Join-Path $tempDir "$dateString-entry.json"
    $payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jsonPathToUse -Encoding UTF8
}

$filePath = & (Join-Path $ProjectRoot "scripts\render_entry_from_json.ps1") -JsonPath $jsonPathToUse -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) {
    throw "JSON 渲染 Markdown 失败。"
}

& (Join-Path $ProjectRoot "scripts\validate_entry.ps1") -FilePath $filePath
if ($LASTEXITCODE -ne 0) {
    throw "日记校验失败，停止发布。"
}

& (Join-Path $ProjectRoot "scripts\publish.ps1") -ProjectRoot $ProjectRoot
if ($LASTEXITCODE -ne 0) {
    throw "发布失败。"
}

Write-Host "每日流程执行完成。" -ForegroundColor Green
