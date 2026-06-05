@echo off
chcp 65001 >nul
title Subnautica 2 - Graphics Presets
cd /d "%~dp0"

:menu
cls
echo.
echo  ========================================================
echo       SUBNAUTICA 2 - GRAPHICS PRESETS
echo  ========================================================
echo   1. Minimum    - weak PC, max FPS
echo   2. Low        - budget GPUs
echo   3. Medium     - balance quality and FPS
echo   4. High       - strong GPUs
echo   5. Ultra Max  - everything maxed out
echo   6. Potato     - extreme FPS boost
echo   7. AMD FSR    - medium settings + FSR
echo  --------------------------------------------------------
echo   8. Restore last backup
echo   0. Exit
echo  ========================================================
echo.
echo  IMPORTANT: close the game before applying a preset!
echo.
set /p choice="  Select option [0-8]: "

if "%choice%"=="1" call "%~dp001_Minimum.bat" & goto menu
if "%choice%"=="2" call "%~dp002_Low.bat" & goto menu
if "%choice%"=="3" call "%~dp003_Medium.bat" & goto menu
if "%choice%"=="4" call "%~dp004_High.bat" & goto menu
if "%choice%"=="5" call "%~dp005_UltraMax.bat" & goto menu
if "%choice%"=="6" call "%~dp006_Potato.bat" & goto menu
if "%choice%"=="7" call "%~dp007_AMD_FSR.bat" & goto menu
if "%choice%"=="8" call "%~dp0restore-backup.bat" & goto menu
if "%choice%"=="0" exit /b 0

echo  Invalid choice.
timeout /t 2 >nul
goto menu
