param(
    [string]$ProjectRoot = "D:\projects\daily-diary-site",
    [string]$OutputPath = "",
    [int]$RecentCommits = 5,
    [string]$AgentId = "main"
)

$ErrorActionPreference = "Stop"

function Exec-Capture {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $result = & $Command @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "命令执行失败: $Command $($Arguments -join ' ')`n$($result | Out-String)"
    }
    return ($result | Out-String)
}

function Read-IfExists {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    }
    return ""
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 5000
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    if ($Text.Length -le $MaxLength) {
        return $Text
    }

    return $Text.Substring(0, $MaxLength)
}

function Collect-AgentActivity {
    param(
        [string]$WorkspaceRoot,
        [string[]]$DateStrings
    )

    $agentsRoot = Join-Path $WorkspaceRoot "agents"
    if (-not (Test-Path -LiteralPath $agentsRoot)) {
        return ""
    }

    $blocks = @()
    Get-ChildItem -LiteralPath $agentsRoot -Directory | Sort-Object Name | ForEach-Object {
        $agentDir = $_.FullName
        $progressPath = Join-Path $agentDir "PROGRESS.md"
        $memDir = Join-Path $agentDir "memory"
        $progressText = Read-IfExists $progressPath
        $recentMems = @()

        if (Test-Path -LiteralPath $memDir) {
            Get-ChildItem -LiteralPath $memDir -Filter "*.md" | Sort-Object Name | ForEach-Object {
                foreach ($day in $DateStrings) {
                    if ($_.Name -like "*$day*") {
                        $text = Read-IfExists $_.FullName
                        if ($text -match "今日完成|当前第一优先级|最近完成|当前任务目标") {
                            $recentMems += [pscustomobject]@{ Name = $_.Name; Text = $text }
                        }
                        break
                    }
                }
            }
        }

        $activeProgress = $false
        if (-not [string]::IsNullOrWhiteSpace($progressText) -and $progressText -notmatch "暂无") {
            if ($progressText -match "当前第一优先级|当前任务目标|进行中|最近完成") {
                $activeProgress = $true
            }
        }

        if (-not $activeProgress -and $recentMems.Count -eq 0) {
            return
        }

        $block = @("### agent: $($_.Name)")
        if ($activeProgress) {
            $block += "[PROGRESS]"
            $block += (($progressText -split "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 30)
        }
        $recentMems | Select-Object -First 2 | ForEach-Object {
            $block += "[MEMORY $($_.Name)]"
            $block += (($_.Text -split "`r?`n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 36)
        }
        $blocks += ($block -join "`n")
    }

    return ($blocks -join "`n`n")
}

Set-Location -LiteralPath $ProjectRoot

$today = Get-Date
$dateString = $today.ToString("yyyy-MM-dd")
$yesterdayString = $today.AddDays(-1).ToString("yyyy-MM-dd")
$tempDir = Join-Path $ProjectRoot ".tmp"
if (-not (Test-Path -LiteralPath $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $tempDir "$dateString-entry.json"
}

$workspaceRoot = "/home/barry/.openclaw/workspace"
$todayMemory = Read-IfExists (Join-Path $workspaceRoot "memory/$dateString.md")
$yesterdayMemory = Read-IfExists (Join-Path $workspaceRoot "memory/$yesterdayString.md")
$progressContent = Read-IfExists (Join-Path $workspaceRoot "PROGRESS.md")
$longMemoryContent = Read-IfExists (Join-Path $workspaceRoot "MEMORY.md")
$agentActivity = Collect-AgentActivity -WorkspaceRoot $workspaceRoot -DateStrings @($dateString, $yesterdayString)

$gitLog = ""
try {
    $gitLog = Exec-Capture -Command "git" -Arguments @("log", "--pretty=format:%h %ad %s", "--date=short", "-n", "$RecentCommits")
}
catch {
    $gitLog = "(无可用 git 日志)"
}

$gitStatus = ""
try {
    $gitStatus = Exec-Capture -Command "git" -Arguments @("status", "--short")
}
catch {
    $gitStatus = "(无可用 git 状态)"
}

$promptTemplate = Read-IfExists (Join-Path $ProjectRoot "prompts\generate_review_prompt.txt")
if ([string]::IsNullOrWhiteSpace($promptTemplate)) {
    throw "缺少 prompt 模板: prompts\\generate_review_prompt.txt"
}

$userPrompt = @"
今天日期：$dateString

请你不要向我提问，也不要要求我补充素材。
请你直接根据下面提供的近期上下文，自主提炼今天和近期的任务推进、情绪变化、关键经历，写成一篇适合公开发布的每日复盘 JSON。

重点要求：
1. 只输出合法 JSON。
2. 不要输出代码块，不要输出解释文字。
3. 复盘要基于已有上下文，不要凭空捏造具体私人事件。
4. 可以提炼情绪和状态变化，但必须克制、真实。
5. body_markdown 必须包含四段：今日完成、卡点与问题、今天的感受、明天的一步。
6. 标题不要带日期前缀，直接根据复盘内容总结一个自然标题。
7. slug 仍然保留日期前缀，方便归档。
8. 优先吸纳所有近两日有工作进展的 agent 素材，但只提炼适合公开发布的内容。
9. 如果适合生成封面图，请给出与正文一致的标题和摘要，不要编造图片细节；后续脚本会负责生成安全的封面文件。

【当前 PROGRESS.md】
$(Limit-Text -Text $progressContent -MaxLength 3500)

【今日记忆】
$(Limit-Text -Text $todayMemory -MaxLength 4000)

【昨日记忆】
$(Limit-Text -Text $yesterdayMemory -MaxLength 2500)

【长期记忆】
$(Limit-Text -Text $longMemoryContent -MaxLength 2500)

【近两日活跃 agents 素材】
$(Limit-Text -Text $agentActivity -MaxLength 9000)

【最近 Git 提交】
$(Limit-Text -Text $gitLog -MaxLength 2000)

【当前 Git 状态】
$(Limit-Text -Text $gitStatus -MaxLength 2000)
"@

$combinedPrompt = $promptTemplate + "`n`n" + $userPrompt
$jsonRaw = Exec-Capture -Command "openclaw" -Arguments @("agent", "--local", "--agent", $AgentId, "--message", $combinedPrompt, "--timeout", "600")

$jsonText = $jsonRaw.Trim()
$firstBrace = $jsonText.IndexOf('{')
$lastBrace = $jsonText.LastIndexOf('}')
if ($firstBrace -lt 0 -or $lastBrace -lt $firstBrace) {
    throw "OpenClaw 未返回合法 JSON。原始输出:`n$jsonText"
}
$jsonText = $jsonText.Substring($firstBrace, $lastBrace - $firstBrace + 1)

try {
    $parsed = $jsonText | ConvertFrom-Json
}
catch {
    throw "OpenClaw 返回内容不是合法 JSON。原始输出:`n$jsonText"
}

$requiredFields = @("title", "date", "summary", "body_markdown", "draft")
foreach ($field in $requiredFields) {
    if (-not ($parsed.PSObject.Properties.Name -contains $field)) {
        throw "返回 JSON 缺少字段: $field"
    }
}

$parsed.title = ([string]$parsed.title) -replace '^\d{4}-\d{2}-\d{2}[\s:：-]*', ''
if ([string]::IsNullOrWhiteSpace($parsed.title)) {
    $parsed.title = "今日复盘"
}

if (-not ($parsed.PSObject.Properties.Name -contains "cover_image_path") -or [string]::IsNullOrWhiteSpace($parsed.cover_image_path)) {
    $parsed | Add-Member -NotePropertyName cover_image_path -NotePropertyValue "/images/default-cover.svg" -Force
}

if (-not ($parsed.PSObject.Properties.Name -contains "slug") -or [string]::IsNullOrWhiteSpace($parsed.slug)) {
    $fallbackSlug = "$dateString-daily-review"
    $parsed | Add-Member -NotePropertyName slug -NotePropertyValue $fallbackSlug -Force
}

$parsed.date = $dateString
$parsed.draft = [bool]$parsed.draft
$parsed | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

$coverScript = Join-Path $ProjectRoot "scripts\generate_cover_svg.ps1"
if (Test-Path -LiteralPath $coverScript) {
    try {
        & $coverScript -ProjectRoot $ProjectRoot -JsonPath $OutputPath | Out-Null
    }
    catch {
    }
}

Write-Host $OutputPath
