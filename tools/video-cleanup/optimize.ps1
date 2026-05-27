# Batch transcode MP4s under this folder (outputs to per-folder encoded/).
# Requires HandBrake CLI — see README.md (not redistributed with this repo).

$HandBrakeCLI = Join-Path $PSScriptRoot "HandBrakeCLI.exe"
if (!(Test-Path $HandBrakeCLI)) {
    $HandBrakeCLI = Join-Path (Join-Path $PSScriptRoot "..\handbrake") "HandBrakeCLI.exe"
}
$BaseDir = $PSScriptRoot
$LogFile = Join-Path $BaseDir "encoding_errors.log"

if (!(Test-Path $HandBrakeCLI)) {
    Write-Error @"
HandBrakeCLI.exe not found. Install HandBrake CLI and place it at one of:
  $PSScriptRoot\HandBrakeCLI.exe
  $(Join-Path (Join-Path $PSScriptRoot '..\handbrake') 'HandBrakeCLI.exe')
See tools\video-cleanup\README.md
"@
    exit 1
}

Write-Host "Starting batch transcode across directories..." -ForegroundColor Yellow
Write-Host "HandBrake: $HandBrakeCLI" -ForegroundColor Yellow
Write-Host "Base Directory: $BaseDir" -ForegroundColor Yellow
Write-Host "---------------------------------------------------"

Get-ChildItem -Path $BaseDir -Filter *.mp4 -Recurse | ForEach-Object {
    if ($_.DirectoryName -match "\\encoded") {
        return
    }

    $inputFile = $_.FullName
    $currentOutputDir = Join-Path $_.DirectoryName "encoded"
    $outputFile = Join-Path $currentOutputDir $_.Name

    if (!(Test-Path $currentOutputDir)) {
        New-Item -ItemType Directory -Path $currentOutputDir | Out-Null
    }

    Write-Host "Processing: $($_.Directory.Name)\$($_.Name)" -ForegroundColor Cyan
    & $HandBrakeCLI -i "$inputFile" -o "$outputFile" -E copy:aac 2>&1

    if ($LASTEXITCODE -ne 0) {
        $errorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ERROR: Failed to process $inputFile. HandBrake Exit Code: $LASTEXITCODE"
        Write-Host $errorMessage -ForegroundColor Red
        Add-Content -Path $LogFile -Value $errorMessage
        if (Test-Path $outputFile) { Remove-Item "$outputFile" -Force }
    } else {
        Write-Host "Successfully encoded: $($_.Name)" -ForegroundColor Green
    }
    Write-Host "---------------------------------------------------"
}

Write-Host "Encoding batch complete!" -ForegroundColor Green
