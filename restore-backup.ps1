#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$ModDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ModDir 'game-path.ps1')
$BackupDir = Join-Path $ModDir 'backup'

if (-not (Test-Path $BackupDir)) {
    Write-Host 'Backup folder is empty.' -ForegroundColor Yellow
    exit 1
}

$ConfigDir = Find-ConfigDir
if (-not (Test-Path $ConfigDir)) {
    $ConfigDir = Resolve-ConfigDir ''
    if (-not $ConfigDir) {
        Write-Host '[ERROR] Config folder not found.' -ForegroundColor Red
        exit 1
    }
}

$backups = Get-ChildItem $BackupDir -Filter 'GameUserSettings.ini.*.bak' -File |
    Sort-Object Name -Descending

if (-not $backups) {
    Write-Host 'No backups found.' -ForegroundColor Yellow
    exit 1
}

Write-Host ''
Write-Host 'Available backups:'
foreach ($bak in $backups) {
    Write-Host "  $($bak.Name)"
}
Write-Host ''

$bakfile = Read-Host 'Enter backup filename (or Enter for latest)'
if ([string]::IsNullOrWhiteSpace($bakfile)) {
    $selected = $backups[0]
} else {
    $selected = Get-Item (Join-Path $BackupDir $bakfile) -ErrorAction SilentlyContinue
    if (-not $selected) {
        Write-Host "File not found: $bakfile" -ForegroundColor Red
        exit 1
    }
}

$stamp = $selected.Name -replace '^GameUserSettings\.ini\.', '' -replace '\.bak$', ''
$engineBackup = Join-Path $BackupDir "Engine.ini.$stamp.bak"
$engineTarget = Join-Path $ConfigDir 'Engine.ini'

Copy-Item $selected.FullName (Join-Path $ConfigDir 'GameUserSettings.ini') -Force

if (Test-Path $engineTarget) {
    $item = Get-Item $engineTarget
    if ($item.IsReadOnly) { $item.IsReadOnly = $false }
}

if (Test-Path $engineBackup) {
    Copy-Item $engineBackup $engineTarget -Force
} elseif (Test-Path $engineTarget) {
    Remove-Item $engineTarget -Force
}

Write-Host ''
Write-Host "Config restored from backup: $stamp" -ForegroundColor Green
Write-Host "Config: $ConfigDir" -ForegroundColor DarkGray
