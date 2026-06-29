@echo off
set ROAMING=%APPDATA%\alacritty
set REPO=%~dp0

echo Uploading from %REPO% to %ROAMING%
if not exist "%ROAMING%" mkdir "%ROAMING%"
copy /Y "%REPO%alacritty.toml" "%ROAMING%\alacritty.toml"
echo Done.
