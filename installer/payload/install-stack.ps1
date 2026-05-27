param(
    [Parameter(Mandatory = $true)]
    [string]$InstallDir,

    [switch]$SkipPull,
    [switch]$SkipTools
)

$ErrorActionPreference = "Stop"
Set-Location $InstallDir

& (Join-Path $PSScriptRoot "check-prerequisites.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "generate-env.ps1") -InstallDir $InstallDir

$dirs = @(
    "library", "library\upload\external", "dedup-data",
    "data\pgdata", "data\redis", "data\model-cache"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir $d) | Out-Null
}

if (-not $SkipTools) {
    & (Join-Path $PSScriptRoot "install-tools.ps1") -InstallDir $InstallDir
}

if (-not $SkipPull) {
    Write-Host "Pulling container images (may take a while)..."
    docker compose pull
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Starting stack..."
docker compose up -d
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$configDir = Join-Path $env:LOCALAPPDATA "ImmichPhotoManager"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null
@{ InstallPath = $InstallDir } | ConvertTo-Json | Set-Content (Join-Path $configDir "install.json")

Write-Host "Stack started. Immich: http://localhost:2283  Deduper: http://localhost:8086" -ForegroundColor Green
