param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

$ErrorActionPreference = "Stop"

function Fail-AndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

if (-not (Test-Path -LiteralPath $FilePath)) {
    Fail-AndExit "文件不存在: $FilePath"
}

$resolvedPath = (Resolve-Path -LiteralPath $FilePath).Path
$extension = [System.IO.Path]::GetExtension($resolvedPath)

if ($extension -notin @(".md", ".markdown")) {
    Fail-AndExit "文件扩展名必须是 .md 或 .markdown，当前为: $extension"
}

$content = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8

if ([string]::IsNullOrWhiteSpace($content)) {
    Fail-AndExit "Markdown 文件内容为空: $resolvedPath"
}

if ($content -notmatch "(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.+)$") {
    Fail-AndExit "frontmatter 格式不正确，必须以 --- 开始并结束。"
}

$frontmatterBlock = $matches[1]
$body = $matches[2]

if ([string]::IsNullOrWhiteSpace($body)) {
    Fail-AndExit "正文内容为空。"
}

$requiredFields = @("title", "date", "slug", "summary", "draft")

foreach ($field in $requiredFields) {
    if ($frontmatterBlock -notmatch "(?m)^$field\s*:\s*.+$") {
        Fail-AndExit "frontmatter 缺少必填字段: $field"
    }
}

$titleMatch = [regex]::Match($frontmatterBlock, '(?m)^title\s*:\s*"?(.*?)"?\s*$')
$dateMatch = [regex]::Match($frontmatterBlock, '(?m)^date\s*:\s*"?(.*?)"?\s*$')
$slugMatch = [regex]::Match($frontmatterBlock, '(?m)^slug\s*:\s*"?(.*?)"?\s*$')
$summaryMatch = [regex]::Match($frontmatterBlock, '(?m)^summary\s*:\s*"?(.*?)"?\s*$')
$draftMatch = [regex]::Match($frontmatterBlock, '(?m)^draft\s*:\s*(true|false)\s*$')

if (-not $titleMatch.Success -or [string]::IsNullOrWhiteSpace($titleMatch.Groups[1].Value)) {
    Fail-AndExit "title 不能为空。"
}

if (-not $dateMatch.Success) {
    Fail-AndExit "date 缺失或格式无效。"
}

try {
    [datetime]::ParseExact($dateMatch.Groups[1].Value, "yyyy-MM-dd", $null) | Out-Null
}
catch {
    Fail-AndExit "date 必须是 yyyy-MM-dd 格式。"
}

if (-not $slugMatch.Success -or $slugMatch.Groups[1].Value -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
    Fail-AndExit "slug 必须为小写英文、数字和连字符组合。"
}

if (-not $summaryMatch.Success -or [string]::IsNullOrWhiteSpace($summaryMatch.Groups[1].Value)) {
    Fail-AndExit "summary 不能为空。"
}

if ($summaryMatch.Groups[1].Value.Length -gt 220) {
    Fail-AndExit "summary 建议不超过 220 个字符。"
}

if (-not $draftMatch.Success) {
    Fail-AndExit "draft 必须为 true 或 false。"
}

$normalizedPath = $resolvedPath.Replace('\\', '/')
if ($normalizedPath -notmatch '/src/content/diary/') {
    Fail-AndExit "Markdown 文件必须位于 src/content/diary/ 目录下。"
}

Write-Host "校验通过: $resolvedPath" -ForegroundColor Green
exit 0
