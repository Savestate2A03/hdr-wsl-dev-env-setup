@echo off
setlocal
start /b powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$baseDir = '%~dp0'.TrimEnd('\'); $repoDir = Join-Path $baseDir 'HewDraw-Remix'; if (-not (Test-Path $repoDir)) { $repoDir = $baseDir }; if ($repoDir -match '^\\\\wsl(?:\.localhost|\$)\\([^\\]+)(\\.*)$') { $distro = $Matches[1]; $path = ($Matches[2] -replace '\\', '/'); code --folder-uri ('vscode-remote://wsl+' + $distro + $path) } else { code $repoDir }"
