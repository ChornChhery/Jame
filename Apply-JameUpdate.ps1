# Apply-JameUpdate.ps1
# Copies the updated Jame project (English + Khmer) over D:\Jame.
# Edit $zip below if your download is in a different place.

$ErrorActionPreference = 'Stop'
$project = 'D:\Jame'
$zip     = "$env:USERPROFILE\Downloads\Jame-en-km-2026-11-24.zip"

if (-not (Test-Path -LiteralPath $zip)) { throw "Zip not found: $zip" }

cd $project

# 1) Safety backup of the current source (lib, test, README) next to the project
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "D:\Jame-backup-$stamp.zip"
Compress-Archive -Path "$project\lib", "$project\test", "$project\README.md" -DestinationPath $backup -Force
Write-Host "Backup written to $backup"

# 2) Overlay the new files
Expand-Archive -Force -LiteralPath $zip -DestinationPath $project

# 3) Remove the old Thai-named report (replaced by 'Project Report Application.docx')
Get-ChildItem -LiteralPath $project -Filter '*Application.docx' |
    Where-Object { $_.Name -ne 'Project Report Application.docx' } |
    Remove-Item -Force

# 4) Restore packages, analyze, test
flutter pub get
flutter analyze
flutter test

Write-Host ''
Write-Host 'Done. Start the stack and the app with:'
Write-Host '  docker compose up -d --wait postgres mailpit api'
Write-Host '  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1'
