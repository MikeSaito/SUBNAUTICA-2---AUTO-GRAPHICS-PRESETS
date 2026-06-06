#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('minimum', 'low', 'medium', 'high', 'ultramax', 'potato')]
    [string]$Preset,
    [switch]$NoReadOnly,
    [switch]$ForceFSR,
    [switch]$SettingsOnly
)

$ErrorActionPreference = 'Stop'

$winGdkDir  = Join-Path $env:LOCALAPPDATA 'Subnautica2\Saved\Config\WinGDK'
$windowsDir = Join-Path $env:LOCALAPPDATA 'Subnautica2\Saved\Config\Windows'
if ((Test-Path $winGdkDir) -and -not (Test-Path (Join-Path $windowsDir 'GameUserSettings.ini'))) {
    $ConfigDir = $winGdkDir
} else {
    $ConfigDir = $windowsDir
}
$ModDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$PresetDir  = Join-Path $ModDir "presets\$Preset"
$BackupDir  = Join-Path $ModDir 'backup'

$GameProcesses = @('Subnautica2', 'Subnautica2-Win64-Shipping')
foreach ($proc in $GameProcesses) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
        Write-Host ''
        Write-Host '[ERROR] Game is running! Fully close Subnautica 2 first.' -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path $PresetDir)) {
    Write-Host "[ERROR] Preset not found: $PresetDir" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
foreach ($file in @('GameUserSettings.ini', 'Engine.ini')) {
    $src = Join-Path $ConfigDir $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $BackupDir "${file}.${timestamp}.bak") -Force
    }
}

function Read-IniFile {
    param([string]$Path)
    $result = [ordered]@{}
    if (-not (Test-Path $Path)) { return $result }

    $section = ''
    $sectionPattern = '^\s*\[(.+)\]\s*$'
    $kvPattern = '^\s*(.+?)\s*=\s*(.*)\s*$'

    foreach ($line in Get-Content $Path -Encoding UTF8) {
        if ($line -match '^\s*;\s*METADATA=') { continue }
        if ($line -match $sectionPattern) {
            $section = $Matches[1]
            if (-not $result.Contains($section)) {
                $result[$section] = [ordered]@{}
            }
            continue
        }
        if ($section -and $line -match $kvPattern) {
            $key = $Matches[1].Trim()
            if ($key -notmatch '^;') {
                $result[$section][$key] = $Matches[2].Trim()
            }
        }
    }
    return $result
}

function Write-IniFile {
    param(
        [string]$Path,
        [hashtable]$Data,
        [string]$Header = ''
    )
    $lines = New-Object System.Collections.Generic.List[string]
    if ($Header) {
        $lines.Add($Header)
    }
    foreach ($section in $Data.Keys) {
        $lines.Add("[$section]")
        foreach ($key in $Data[$section].Keys) {
            $lines.Add("$key=$($Data[$section][$key])")
        }
        $lines.Add('')
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($Path, $lines, $utf8NoBom)
}

$PreserveKeys = @{
    'UWE.PersistentInfo' = @('InstallGUID', 'RunNumber')
    '/Script/Engine.GameUserSettings' = @('bUseDesiredScreenHeight', 'FieldOfView')
    '/Script/Subnautica2.S2GameUserSettings' = @('FieldOfView', 'DesiredFOV', 'fFOV')
    '/Script/Subnautica2.SN2SettingsLocal' = @(
        'ResolutionSizeX', 'ResolutionSizeY',
        'DesiredScreenWidth', 'DesiredScreenHeight',
        'LastUserConfirmedDesiredScreenWidth', 'LastUserConfirmedDesiredScreenHeight',
        'LastUserConfirmedResolutionSizeX', 'LastUserConfirmedResolutionSizeY',
        'FullscreenMode', 'PreferredFullscreenMode', 'LastConfirmedFullscreenMode',
        'LastGPUBenchmarkSteps', 'LastGPUBenchmarkMultiplier', 'LastGPUBenchmarkResult',
        'LastCPUBenchmarkSteps', 'LastCPUBenchmarkResult',
        'LastRecommendedScreenWidth', 'LastRecommendedScreenHeight',
        'AudioOutputDeviceId', 'DesiredUserChosenDeviceProfileSuffix',
        'LastConfirmedAudioQualityLevel', 'ROGAllyCustomModeEnabled'
    )
}

$existingPath = Join-Path $ConfigDir 'GameUserSettings.ini'
$presetPath   = Join-Path $PresetDir 'GameUserSettings.ini'
$merged       = Read-IniFile $presetPath
$existing     = Read-IniFile $existingPath

foreach ($section in $PreserveKeys.Keys) {
    if (-not $existing.Contains($section)) { continue }
    if (-not $merged.Contains($section)) {
        $merged[$section] = [ordered]@{}
    }
    foreach ($key in $PreserveKeys[$section]) {
        if ($existing[$section].Contains($key)) {
            $merged[$section][$key] = $existing[$section][$key]
        }
    }
}

if ($existing.Contains('UWE.PersistentInfo')) {
    $merged['UWE.PersistentInfo'] = $existing['UWE.PersistentInfo']
}

if ($ForceFSR -and $merged.Contains('/Script/Subnautica2.SN2SettingsLocal')) {
    $sn2 = $merged['/Script/Subnautica2.SN2SettingsLocal']
    $sn2['UpscalingMethod'] = 'U_FSR'
    $sn2.Remove('DLSSQualityMode')
    $sn2['UpscalingFrameGeneration'] = '0'
} elseif ($merged.Contains('/Script/Subnautica2.SN2SettingsLocal') -and $existing.Contains('/Script/Subnautica2.SN2SettingsLocal')) {
    $sn2Merged = $merged['/Script/Subnautica2.SN2SettingsLocal']
    $sn2Existing = $existing['/Script/Subnautica2.SN2SettingsLocal']
    if ($sn2Existing.Contains('UpscalingMethod')) {
        $method = $sn2Existing['UpscalingMethod']
        if ($method -in @('U_FSR', 'U_TSR', 'U_None')) {
            $sn2Merged['UpscalingMethod'] = $method
            if ($method -ne 'U_DLSS') {
                $sn2Merged.Remove('DLSSQualityMode')
            }
            if ($sn2Existing.Contains('UpscalingFrameGeneration')) {
                $sn2Merged['UpscalingFrameGeneration'] = $sn2Existing['UpscalingFrameGeneration']
            }
        }
    }
}

$metaHeader = ';METADATA=(Diff=true, UseCommands=true)'
Write-IniFile -Path (Join-Path $ConfigDir 'GameUserSettings.ini') -Data $merged -Header $metaHeader

$enginePreset = Join-Path $PresetDir 'Engine.ini'
$engineTarget = Join-Path $ConfigDir 'Engine.ini'
if ($SettingsOnly) {
    Write-Host '  Settings-only mode: Engine.ini not changed.' -ForegroundColor Yellow
    if (Test-Path $engineTarget) {
        Write-Host '  Tip: delete Engine.ini in AppData if a previous preset caused stutter.' -ForegroundColor DarkYellow
    }
} elseif (Test-Path $enginePreset) {
    Copy-Item $enginePreset $engineTarget -Force
    if (-not $NoReadOnly) {
        $item = Get-Item $engineTarget
        $item.IsReadOnly = $true
    }
} elseif (Test-Path $engineTarget) {
    if ((Get-Item $engineTarget).IsReadOnly) {
        (Get-Item $engineTarget).IsReadOnly = $false
    }
    Remove-Item $engineTarget -Force
}

$presetNames = @{
    minimum  = 'MINIMUM'
    low      = 'LOW'
    medium   = 'MEDIUM'
    high     = 'HIGH'
    ultramax = 'ULTRA MAX'
    potato   = 'POTATO (MAX FPS)'
}

if ($ForceFSR) {
    Write-Host '  AMD FSR mode: UpscalingMethod=U_FSR, FrameGen off' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "  Preset applied: $($presetNames[$Preset])" -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "  Config: $ConfigDir"
Write-Host "  Backup: $BackupDir"
Write-Host ''
Write-Host '  Screen resolution and FOV preserved from current config.'
if (-not $SettingsOnly -and -not $NoReadOnly -and (Test-Path $engineTarget)) {
    Write-Host '  Engine.ini set to Read-only (game will not delete tweaks).'
}
Write-Host '  Launch the game to verify settings.'
Write-Host ''
