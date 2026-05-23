# One-time: copy Docker named volumes (often on C:) to bind mounts under ./data on D:
# Run from repo root after: docker compose down
# Usage: .\scripts\migrate-docker-volumes-to-bind.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$dirs = @('data\pgdata', 'data\redis', 'data\model-cache')
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

$volumes = @{
    'immich_pgdata'       = 'data\pgdata'
    'immich_redisdata'    = 'data\redis'
    'immich_model-cache'  = 'data\model-cache'
}

foreach ($vol in $volumes.Keys) {
    $dest = $volumes[$vol]
    $hasData = (Get-ChildItem $dest -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($hasData) {
        Write-Host "Skip $dest (already has data)"
        continue
    }
    $exists = docker volume inspect $vol 2>$null
    if (-not $exists) {
        Write-Host "Volume $vol not found (fresh install) - skip"
        continue
    }
    Write-Host "Copying $vol -> $dest ..."
    $destAbs = (Resolve-Path $dest).Path
    docker run --rm `
        -v "${vol}:/from:ro" `
        -v "${destAbs}:/to" `
        alpine sh -c "cp -a /from/. /to/" | Out-Null
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Done. Start stack: docker compose up -d"
