@echo off
chcp 65001 >nul
title Subnautica 2 - Restore Backup
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-backup.ps1"
pause
