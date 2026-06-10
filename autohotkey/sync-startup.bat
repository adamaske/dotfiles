@echo off
setlocal

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "AHK_DIR=%~dp0"

:: terminal.ahk — Win+Enter opens terminal
powershell -NoProfile -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$s = $ws.CreateShortcut('%STARTUP%\terminal.lnk'); " ^
    "$s.TargetPath = '%AHK_DIR%terminal.ahk'; " ^
    "$s.Save()"

echo [OK] Startup shortcuts synced to:
echo      %STARTUP%
