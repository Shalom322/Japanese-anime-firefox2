@echo off
rem japanese-anime-firefox installer. Usage: install.bat   or   install.bat -Uninstall
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
