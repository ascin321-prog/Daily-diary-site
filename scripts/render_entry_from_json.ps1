param(
    [Parameter(Mandatory = $true)]
    [string]$JsonPath,

    [string]$ProjectRoot = "D:\projects\daily-diary-site"
)

$ErrorActionPreference = "Stop"

function Fail-AndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

if (-not (Test-Path -LiteralPath $JsonPath)) {
    Fail-AndExit "JSON 文件不存在: $JsonPath"
}

$jsonRaw = Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($jsonRaw)) {
    Fail-AndExit "JSON 文件为空: $JsonPath"
}

try {
    $entry = $jsonRaw | ConvertFrom-Json
}
catch {
    Fail-AndExit "JSON 解析失败，请检查格式。"
}

$requiredFields = @("title", "date", "summary", "body_markdown", "draft")
foreach ($field in $requiredFields) {
    if (-not ($entry.PSObject.Properties.Name -contains $field)) {
        Fail-AndExit "缺少必填字段: $field"
    }
}

if ([string]::IsNullOrWhiteSpace($entry.title)) {
    Fail-AndExit "title 不能为空"
}

try {
    [datetime]::ParseExact($entry.date, "yyyy-MM-dd", $null) | Out-Null
}
catch {
    Fail-AndExit "date 必须是 yyyy-MM-dd 格式"
}

if ([string]::IsNullOrWhiteSpace($entry.summary)) {
    Fail-AndExit "summary 不能为空"
}

if ($entry.summary.Length -gt 220) {
    Fail-AndExit "summary 不能超过 220 个字符"
}

if ([string]::IsNullOrWhiteSpace($entry.body_markdown)) {
    Fail-AndExit "body_markdown 不能为空"
}

if ($entry.draft -isnot [bool]) {
    Fail-AndExit "draft 必须是布尔值"
}

function New-SlugText {
    param(
        [string]$DateString,
        [string]$Title,
        [string]$PreferredSlug
    )

    $slugBase = $PreferredSlug
    if ([string]::IsNullOrWhiteSpace($slugBase)) {
        $slugBase = $Title.ToLowerInvariant()
        $slugBase = $slugBase -replace '[^a-z0-9\s-]', ''
        $slugBase = $slugBase -replace '\s+', '-'
        $slugBase = $slugBase -replace '-+', '-'
        $slugBase = $slugBase.Trim('-')
    }

    if ([string]::IsNullOrWhiteSpace($slugBase)) {
        $slugBase = 'daily-note'
    }

    if ($slugBase -notmatch "^$DateString-") {
        $slugBase = "$DateString-$slugBase"
    }

    return $slugBase
}

$slug = New-SlugText -DateString $entry.date -Title $entry.title -PreferredSlug $entry.slug
if ($slug -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
    Fail-AndExit "slug 非法，必须为小写字母、数字和连字符"
}

$diaryDir = Join-Path $ProjectRoot "src\content\diary"
if (-not (Test-Path -LiteralPath $diaryDir)) {
    New-Item -ItemType Directory -Path $diaryDir -Force | Out-Null
}

$filePath = Join-Path $diaryDir ("$slug.md")
$counter = 2
while ((Test-Path -LiteralPath $filePath) -and ((Resolve-Path -LiteralPath $filePath).Path -notlike "*$slug.md")) {
    $filePath = Join-Path $diaryDir ("$slug-$counter.md")
    $counter++
}

if (Test-Path -LiteralPath $filePath) {
    Fail-AndExit "同名日记已存在: $filePath"
}

$cover = $entry.cover_image_path
if ([string]::IsNullOrWhiteSpace($cover)) {
    $cover = "/images/default-cover.svg"
}
elseif ($cover -notmatch '^/images/') {
    Fail-AndExit "cover_image_path 必须以 /images/ 开头"
}

$tags = @()
if ($entry.PSObject.Properties.Name -contains 'tags' -and $entry.tags) {
    $tags = @($entry.tags | ForEach-Object { '"' + $_ + '"' })
}
$tagsText = '[' + ($tags -join ', ') + ']'

$markdown = @"
---
title: "$($entry.title)"
date: "$($entry.date)"
summary: "$($entry.summary)"
cover: "$cover"
tags: $tagsText
draft: $($entry.draft.ToString().ToLower())
---

$($entry.body_markdown)
"@

[System.IO.File]::WriteAllText($filePath, $markdown, [System.Text.UTF8Encoding]::new($false))
Write-Host $filePath
