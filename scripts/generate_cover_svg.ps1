param(
    [string]$ProjectRoot = "D:\projects\daily-diary-site",
    [Parameter(Mandatory = $true)]
    [string]$JsonPath
)

$ErrorActionPreference = "Stop"

$jsonRaw = Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8
$entry = $jsonRaw | ConvertFrom-Json
$dateString = if ($entry.date) { [string]$entry.date } else { (Get-Date).ToString("yyyy-MM-dd") }
$title = if ($entry.title) { [string]$entry.title } else { "每日复盘" }
$summary = if ($entry.summary) { [string]$entry.summary } else { "" }
$year = $dateString.Substring(0,4)
$month = $dateString.Substring(5,2)
$imageDir = Join-Path $ProjectRoot "public\images\$year\$month"
if (-not (Test-Path -LiteralPath $imageDir)) {
    New-Item -ItemType Directory -Path $imageDir -Force | Out-Null
}
$coverName = "$dateString-cover.svg"
$coverPath = Join-Path $imageDir $coverName
$titleText = if ($title.Length -gt 18) { $title.Substring(0,18) } else { $title }
$summaryLines = @()
if (-not [string]::IsNullOrWhiteSpace($summary)) {
    $clean = $summary
    if ($clean.Length -gt 40) { $clean = $clean.Substring(0,40) }
    for ($i = 0; $i -lt $clean.Length; $i += 20) {
        $len = [Math]::Min(20, $clean.Length - $i)
        $summaryLines += $clean.Substring($i, $len)
    }
}
$textNodes = @()
$textNodes += "<text x='80' y='180' font-size='34' fill='#4b3f34' font-family='PingFang SC, Microsoft YaHei, sans-serif'>$titleText</text>"
for ($i = 0; $i -lt $summaryLines.Count; $i++) {
    $y = 226 + ($i * 46)
    $textNodes += "<text x='80' y='$y' font-size='20' fill='#4b3f34' font-family='PingFang SC, Microsoft YaHei, sans-serif'>$($summaryLines[$i])</text>"
}
$svg = @"
<svg xmlns='http://www.w3.org/2000/svg' width='1600' height='900' viewBox='0 0 1600 900'>
  <defs>
    <linearGradient id='bg' x1='0' y1='0' x2='1' y2='1'>
      <stop offset='0%' stop-color='#f7f1e8'/>
      <stop offset='100%' stop-color='#eadfce'/>
    </linearGradient>
  </defs>
  <rect width='1600' height='900' fill='url(#bg)'/>
  <circle cx='1320' cy='170' r='140' fill='#8a6f52' fill-opacity='0.14'/>
  <circle cx='1450' cy='760' r='220' fill='#8a6f52' fill-opacity='0.08'/>
  <rect x='72' y='92' width='920' height='420' rx='36' fill='#fffaf4' fill-opacity='0.72'/>
  <text x='80' y='130' font-size='18' fill='#8a6f52' font-family='PingFang SC, Microsoft YaHei, sans-serif'>$dateString · 自动生成封面</text>
  $($textNodes -join "`n  ")
</svg>
"@
[System.IO.File]::WriteAllText($coverPath, $svg, [System.Text.UTF8Encoding]::new($false))
$entry.cover_image_path = "/images/$year/$month/$coverName"
$entry | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonPath -Encoding UTF8
Write-Host $entry.cover_image_path
