param(
    [string]$ProjectRoot = "D:\projects\daily-diary-site",
    [string]$Branch = "main"
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

function New-Slug {
    param(
        [string]$DateString,
        [string]$Title
    )

    $slugText = $Title.ToLowerInvariant()
    $slugText = $slugText -replace '[^a-z0-9\u4e00-\u9fa5\s-]', ''
    $slugText = $slugText -replace '\s+', '-'
    $slugText = $slugText -replace '-+', '-'
    $slugText = $slugText.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slugText)) {
        $slugText = "daily-note"
    }

    $slugText = $slugText -replace '[^\x00-\x7F]', ''
    $slugText = $slugText -replace '-+', '-'
    $slugText = $slugText.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slugText)) {
        $slugText = "daily-note"
    }

    return "$DateString-$slugText"
}

Set-Location -LiteralPath $ProjectRoot

$today = Get-Date
$dateString = $today.ToString("yyyy-MM-dd")
$year = $today.ToString("yyyy")
$month = $today.ToString("MM")

$diaryDir = Join-Path $ProjectRoot "src\content\diary"
$imageDir = Join-Path $ProjectRoot "public\images\$year\$month"

if (-not (Test-Path -LiteralPath $diaryDir)) {
    New-Item -ItemType Directory -Path $diaryDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $imageDir)) {
    New-Item -ItemType Directory -Path $imageDir -Force | Out-Null
}

Exec-Step -Command "git" -Arguments @("pull", "origin", $Branch)

$title = "今日小记"
$summary = "这是 $dateString 自动生成的一篇日记，占位内容可替换为真实 OpenClaw 输出。"
$bodyMarkdown = @"
今天是 $dateString。

这篇内容由 Windows 定时任务自动触发生成。

你后续可以把这里替换成 OpenClaw 输出的真实日记正文，例如晨间回顾、晚间总结、当天感受与记录。
"@

$slug = New-Slug -DateString $dateString -Title $title
$fileName = "$slug.md"
$filePath = Join-Path $diaryDir $fileName

if (Test-Path -LiteralPath $filePath) {
    Write-Host "今日日记已存在，跳过生成: $filePath" -ForegroundColor Yellow
}
else {
    $coverCandidates = @(
        "/images/$year/$month/$dateString-cover.webp",
        "/images/$year/$month/$dateString-cover.png",
        "/images/$year/$month/$dateString-cover.jpg",
        "/images/$year/$month/$dateString-cover.jpeg",
        "/images/$year/$month/$dateString-cover.svg"
    )

    $selectedCover = $null
    foreach ($cover in $coverCandidates) {
        $coverDiskPath = Join-Path $ProjectRoot ("public" + $cover.Replace('/', '\\'))
        if (Test-Path -LiteralPath $coverDiskPath) {
            $selectedCover = $cover
            break
        }
    }

    if (-not $selectedCover) {
        $selectedCover = "/images/default-cover.svg"
    }

    $markdown = @"
---
title: "$title"
date: "$dateString"
slug: "$slug"
summary: "$summary"
cover: "$selectedCover"
tags: ["日记", "自动生成"]
draft: false
---

$bodyMarkdown
"@

    [System.IO.File]::WriteAllText($filePath, $markdown, [System.Text.UTF8Encoding]::new($false))
    Write-Host "已生成日记: $filePath" -ForegroundColor Green
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
