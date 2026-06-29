@echo off
set ROAMING=%APPDATA%\alacritty
set REPO=%~dp0

echo Syncing from %ROAMING% to %REPO%
copy /Y "%ROAMING%\alacritty.toml" "%REPO%alacritty.toml"
echo Done.
