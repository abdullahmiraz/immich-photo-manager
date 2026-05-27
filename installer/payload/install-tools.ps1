param(
    [Parameter(Mandatory = $true)]
    [string]$InstallDir,

    [string]$ImmichGoVersion = "v0.31.0",
    [string]$ImmichGoAsset = "immich-go_Windows_x86_64.zip"
)

$ErrorActionPreference = "Stop"
$configPath = Join-Path $InstallDir "installer\config.json"
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($cfg.ImmichGoVersion) { $ImmichGoVersion = $cfg.ImmichGoVersion }
    if ($cfg.ImmichGoAsset) { $ImmichGoAsset = $cfg.ImmichGoAsset }
}

$goDir = Join-Path $InstallDir "tools\immich-go"
New-Item -ItemType Directory -Force -Path $goDir | Out-Null

$url = "https://github.com/simulot/immich-go/releases/download/$ImmichGoVersion/$ImmichGoAsset"
$zipPath = Join-Path $env:TEMP $ImmichGoAsset

Write-Host "Downloading immich-go $ImmichGoVersion ($ImmichGoAsset)..."
Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
Expand-Archive -Path $zipPath -DestinationPath $goDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

$exe = Join-Path $goDir "immich-go.exe"
if (!(Test-Path $exe)) {
    $found = Get-ChildItem -Path $goDir -Filter "immich-go.exe" -Recurse | Select-Object -First 1
    if ($found) { Move-Item -Path $found.FullName -Destination $exe -Force }
}
if (!(Test-Path $exe)) {
    throw "immich-go.exe not found after extracting $ImmichGoAsset"
}

Write-Host "immich-go installed to $exe"
