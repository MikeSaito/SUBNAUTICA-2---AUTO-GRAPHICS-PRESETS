#Requires -Version 5.1
# Scans Subnautica2-Windows.pak for readable config strings
param(
    [string]$PakPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'Subnautica2\Content\Paks\Subnautica2-Windows.pak'),
    [string]$OutFile = (Join-Path $PSScriptRoot 'extracted-from-pak.txt')
)

if (-not (Test-Path $PakPath)) {
    Write-Host "Pak not found: $PakPath" -ForegroundColor Red
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($PakPath)
$text = -join ($bytes | ForEach-Object { if ($_ -ge 32 -and $_ -lt 127) -or $_ -in 9,10,13 { [char]$_ } else { "`n" } })

$patterns = @(
    '\+CVars=[^\r\n]+',
    '\[ScalabilityGroups\][\s\S]{0,800}',
    '\[Windows DeviceProfile\][\s\S]{0,1200}',
    '\[/Script/Engine\.RendererSettings\][\s\S]{0,400}',
    '\[SystemSettings\][\s\S]{0,400}',
    'sg\.\w+Quality=\d+',
    'r\.(?:Water|Lumen|Shadow|Fog|Sky|Nanite|Dynamic|Streaming|Reflex|NGX)[^\s=]+=[^\s\r\n]+'
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Extracted: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$lines.Add("Source: $PakPath")
$lines.Add('')

foreach ($pat in $patterns) {
    $matches = [regex]::Matches($text, $pat)
    if ($matches.Count -eq 0) { continue }
    $lines.Add("=== Pattern: $pat (count $($matches.Count)) ===")
    $seen = @{}
    foreach ($m in $matches) {
        $val = $m.Value.Trim()
        if ($seen.ContainsKey($val)) { continue }
        $seen[$val] = $true
        $lines.Add($val)
        $lines.Add('')
    }
}

$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($OutFile, $lines, $utf8)
Write-Host "Saved: $OutFile ($($lines.Count) lines)" -ForegroundColor Green
