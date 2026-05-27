param(
    [Parameter(Mandatory = $true)]
    [string]$InstallDir,

    [string]$ImmichGoVersion = "v0.31.0"
)

$ErrorActionPreference = "Stop"
$goDir = Join-Path $InstallDir "tools\immich-go"
New-Item -ItemType Directory -Force -Path $goDir | Out-Null

$tag = $ImmichGoVersion.TrimStart('v')
$zipName = "immich-go_${tag}_windows_amd64.zip"
$url = "https://github.com/simulot/immich-go/releases/download/$ImmichGoVersion/$zipName"
$zipPath = Join-Path $env:TEMP $zipName

Write-Host "Downloading immich-go $ImmichGoVersion..."
Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
Expand-Archive -Path $zipPath -DestinationPath $goDir -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

$exe = Get-ChildItem -Path $goDir -Filter "immich-go.exe" -Recurse | Select-Object -First 1
if ($exe -and $exe.DirectoryName -ne $goDir) {
    Move-Item -Path $exe.FullName -Destination (Join-Path $goDir "immich-go.exe") -Force
}

Write-Host "immich-go installed to $goDir"
