#Requires -Version 5.1

$script:GameTitle = 'Subnautica 2'
$script:GameFolderName = 'Subnautica2'
$script:GameExeNames = @('Subnautica2.exe', 'Subnautica2-Win64-Shipping.exe')
$script:GamePassPattern = 'Subnautica|Unknown.?Worlds|UWE'

function Get-AvailableDriveRoots {
    [System.IO.DriveInfo]::GetDrives() |
        Where-Object {
            $_.IsReady -and
            ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable')
        } |
        ForEach-Object {
            $root = if ($_.Root) { $_.Root } else { $_.Name }
            if ($root) { $root.TrimEnd('\') }
        } |
        Where-Object { $_ }
}

function Test-GameExeAt([string]$Root) {
    if ([string]::IsNullOrWhiteSpace($Root)) { return $false }
    $folder = $Root.TrimEnd('\')
    foreach ($exe in $script:GameExeNames) {
        if (Test-Path (Join-Path $folder $exe)) { return $true }
    }
    return $false
}

function Add-GameCandidate(
    [System.Collections.Generic.List[string]]$List,
    [System.Collections.Generic.HashSet[string]]$Seen,
    [string]$Path
) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $normalized = $Path.TrimEnd('\')
    if ($Seen.Contains($normalized)) { return }
    [void]$Seen.Add($normalized)
    $List.Add($normalized)
}

function Get-SteamLibrariesFromVdf([string]$VdfPath) {
    $libs = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $VdfPath)) { return $libs }

    $content = Get-Content $VdfPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $libs }

    foreach ($match in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
        $raw = $match.Groups[1].Value -replace '\\\\', '\'
        if ($raw -and (Test-Path $raw)) {
            $libs.Add($raw.TrimEnd('\'))
        }
    }
    return $libs
}

function Add-SteamInstallCandidates(
    [System.Collections.Generic.List[string]]$Candidates,
    [System.Collections.Generic.HashSet[string]]$Seen,
    [string]$SteamRoot
) {
    if ([string]::IsNullOrWhiteSpace($SteamRoot)) { return }

    $steamRoot = $SteamRoot.TrimEnd('\')
    $gameRel = "steamapps\common\$($script:GameFolderName)"
    Add-GameCandidate $Candidates $Seen (Join-Path $steamRoot $gameRel)

    foreach ($vdf in @(
            (Join-Path $steamRoot 'steamapps\libraryfolders.vdf'),
            (Join-Path $steamRoot 'config\libraryfolders.vdf')
        )) {
        foreach ($lib in Get-SteamLibrariesFromVdf $vdf) {
            Add-GameCandidate $Candidates $Seen (Join-Path $lib $gameRel)
        }
    }
}

function Find-GamePassRoot {
    $packages = Join-Path $env:LOCALAPPDATA 'Packages'
    if (-not (Test-Path $packages)) { return $null }

    foreach ($pkg in Get-ChildItem $packages -Directory -ErrorAction SilentlyContinue) {
        if ($pkg.Name -notmatch $script:GamePassPattern) { continue }
        foreach ($exe in $script:GameExeNames) {
            $deep = Get-ChildItem $pkg.FullName -Recurse -Filter $exe -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($deep) { return $deep.Directory.FullName }
        }
    }
    return $null
}

function Request-GameRootPath {
    Write-Host ''
    Write-Host "[INFO] $($script:GameTitle) was not found automatically." -ForegroundColor Yellow
    Write-Host "Enter the full path to the folder that contains $($script:GameExeNames[0])" -ForegroundColor Yellow
    Write-Host "(example: D:\Games\Steam\steamapps\common\$($script:GameFolderName))" -ForegroundColor DarkGray

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $inputPath = Read-Host 'Game folder path'
        $inputPath = $inputPath.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            Write-Host '[ERROR] Path cannot be empty.' -ForegroundColor Red
            continue
        }
        if (Test-GameExeAt $inputPath) {
            return $inputPath.TrimEnd('\')
        }
        Write-Host "[ERROR] $($script:GameExeNames[0]) not found in that folder. Try again." -ForegroundColor Red
    }
    return $null
}

function Find-GameRoot([string]$Hint, [string]$ModDir) {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $gameRel = "steamapps\common\$($script:GameFolderName)"

    if ($Hint) { Add-GameCandidate $candidates $seen $Hint }
    if ($ModDir) {
        Add-GameCandidate $candidates $seen (Split-Path $ModDir -Parent)
        Add-GameCandidate $candidates $seen (Split-Path (Split-Path $ModDir -Parent) -Parent)
    }

    foreach ($steam in @(
            (Join-Path $env:ProgramFiles "Steam\$gameRel"),
            (Join-Path ${env:ProgramFiles(x86)} "Steam\$gameRel")
        )) {
        Add-GameCandidate $candidates $seen $steam
    }

    foreach ($drive in Get-AvailableDriveRoots) {
        foreach ($rel in @(
                "Steam\$gameRel",
                "staem\$gameRel",
                "Program Files\Steam\$gameRel",
                "Program Files (x86)\Steam\$gameRel",
                "Games\Steam\$gameRel",
                "Games\SteamLibrary\$gameRel",
                "Games\Steam Library\$gameRel"
            )) {
            Add-GameCandidate $candidates $seen (Join-Path $drive $rel)
        }

        foreach ($steamRoot in @(
                (Join-Path $drive 'Steam'),
                (Join-Path $drive 'staem'),
                (Join-Path $drive 'Program Files\Steam'),
                (Join-Path $drive 'Program Files (x86)\Steam')
            )) {
            Add-SteamInstallCandidates $candidates $seen $steamRoot
        }
    }

    foreach ($root in $candidates) {
        if (Test-GameExeAt $root) { return $root.TrimEnd('\') }
        $nested = Join-Path $root $gameRel
        if (Test-GameExeAt $nested) { return $nested.TrimEnd('\') }
    }

    $gamePass = Find-GamePassRoot
    if ($gamePass) { return $gamePass }

    return Request-GameRootPath
}

function Find-ConfigDir {
    $configBase = Join-Path $env:LOCALAPPDATA "$($script:GameFolderName)\Saved\Config"
    $windowsDir = Join-Path $configBase 'Windows'
    $winGdkDir  = Join-Path $configBase 'WinGDK'

    if (Test-Path (Join-Path $windowsDir 'GameUserSettings.ini')) { return $windowsDir }
    if (Test-Path (Join-Path $winGdkDir 'GameUserSettings.ini')) { return $winGdkDir }

    if ((Test-Path $winGdkDir) -and -not (Test-Path (Join-Path $windowsDir 'GameUserSettings.ini'))) {
        return $winGdkDir
    }

    $packages = Join-Path $env:LOCALAPPDATA 'Packages'
    if (Test-Path $packages) {
        foreach ($pkg in Get-ChildItem $packages -Directory -ErrorAction SilentlyContinue) {
            if ($pkg.Name -notmatch $script:GamePassPattern) { continue }
            $deep = Get-ChildItem $pkg.FullName -Recurse -Filter 'GameUserSettings.ini' -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($deep) { return $deep.Directory.FullName }
        }
    }

    if (Test-Path $winGdkDir) { return $winGdkDir }
    return $windowsDir
}

function Request-ConfigDirPath {
    Write-Host ''
    Write-Host '[INFO] Game config folder was not found automatically.' -ForegroundColor Yellow
    Write-Host 'Launch the game once, then retry. Or enter the folder with GameUserSettings.ini' -ForegroundColor Yellow
    Write-Host "(example: $env:LOCALAPPDATA\$($script:GameFolderName)\Saved\Config\Windows)" -ForegroundColor DarkGray

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $inputPath = Read-Host 'Config folder path'
        $inputPath = $inputPath.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            Write-Host '[ERROR] Path cannot be empty.' -ForegroundColor Red
            continue
        }
        if (Test-Path (Join-Path $inputPath 'GameUserSettings.ini')) {
            return $inputPath.TrimEnd('\')
        }
        Write-Host '[ERROR] GameUserSettings.ini not found in that folder. Try again.' -ForegroundColor Red
    }
    return $null
}

function Resolve-ConfigDir([string]$GameRoot) {
    $configDir = Find-ConfigDir
    if (Test-Path (Join-Path $configDir 'GameUserSettings.ini')) {
        return $configDir
    }

    if ($GameRoot) {
        Write-Host ''
        Write-Host '[WARN] Game found, but config not created yet.' -ForegroundColor Yellow
        Write-Host 'Launch Subnautica 2 once, set resolution and display mode, then run this preset again.' -ForegroundColor Yellow
    }

    $manual = Request-ConfigDirPath
    if ($manual) { return $manual }

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    return $configDir
}
