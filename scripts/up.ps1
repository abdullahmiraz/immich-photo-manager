# One-command stack start (Windows). Loads WSL GPU devices, then docker compose up.
# Usage: .\scripts\up.ps1          # foreground
#        .\scripts\up.ps1 -d       # detached (recommended)

param(
    [switch]$Detached
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Test-Path '.env')) {
    Write-Host "Creating .env from .env.example (first run)..."
    Copy-Item .env.example .env
    Write-Warning "Edit .env and set DB_PASSWORD / PSQL_PASS before production use."
}

Write-Host "Loading WSL GPU modules (safe to skip if already loaded)..."
& "$Root\scripts\enable-wsl-gpu.ps1" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "WSL GPU prep failed — ML may fall back to CPU until enable-wsl-gpu.ps1 succeeds."
}

$args = @('compose', 'up')
if ($Detached) { $args += '-d' }
& docker @args
