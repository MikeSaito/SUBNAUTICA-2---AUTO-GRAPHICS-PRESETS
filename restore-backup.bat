@echo off
chcp 65001 >nul
title Subnautica 2 - Restore Backup
cd /d "%~dp0"

set "CONFIG=%LOCALAPPDATA%\Subnautica2\Saved\Config\Windows"
set "BACKUP=%~dp0backup"

if not exist "%BACKUP%" (
    echo  Backup folder is empty.
    pause
    exit /b 1
)

echo.
echo  Available backups:
echo.
dir /b /o-d "%BACKUP%\GameUserSettings.ini.*.bak" 2>nul
echo.

set /p bakfile="  Enter backup filename (or Enter for latest): "

if "%bakfile%"=="" (
    for /f "delims=" %%f in ('dir /b /o-d "%BACKUP%\GameUserSettings.ini.*.bak" 2^>nul') do (
        set "bakfile=%%f"
        goto :restore
    )
    echo  No backups found.
    pause
    exit /b 1
)

:restore
set "stamp=%bakfile:GameUserSettings.ini.=%"
set "stamp=%stamp:.bak=%"

if not exist "%BACKUP%\GameUserSettings.ini.%stamp%.bak" (
    echo  File not found: %bakfile%
    pause
    exit /b 1
)

if exist "%CONFIG%\Engine.ini" (
    attrib -r "%CONFIG%\Engine.ini" >nul 2>&1
)

copy /y "%BACKUP%\GameUserSettings.ini.%stamp%.bak" "%CONFIG%\GameUserSettings.ini" >nul

if exist "%BACKUP%\Engine.ini.%stamp%.bak" (
    copy /y "%BACKUP%\Engine.ini.%stamp%.bak" "%CONFIG%\Engine.ini" >nul
) else if exist "%CONFIG%\Engine.ini" (
    del "%CONFIG%\Engine.ini"
)

echo.
echo  Config restored from backup: %stamp%
echo.
pause
