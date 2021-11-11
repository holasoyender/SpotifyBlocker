@echo off

icacls "%localappdata%\Spotify\Update" /reset /T
del /s /q "%localappdata%\Spotify\Update"
mkdir "%localappdata%\Spotify\Update"
icacls "%localappdata%\Spotify\Update" /deny "%username%":W

powershell -Command "& {Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/holasoyender/SpotifyBlocker/master/Install.ps1' | Invoke-Expression}"
pause
exit
