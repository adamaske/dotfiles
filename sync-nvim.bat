@echo off
set SRC=%LOCALAPPDATA%\nvim
set DST=%~dp0nvim

echo Syncing nvim config from %SRC% to %DST%...
robocopy "%SRC%" "%DST%" /MIR /NFL /NDL /NJH /NJS
echo Done.
