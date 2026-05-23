# Enable WSL GPU + start full stack with ROCm ML overlay
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

& (Join-Path $Root 'scripts\enable-wsl-gpu.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Optional: uncomment if pulls are still slow
# & (Join-Path $Root 'scripts\configure-docker-fast-pulls.ps1')

docker network create immich-deduper 2>$null
& (Join-Path $Root 'scripts\pull-ml-rocm.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --force-recreate immich-machine-learning
Start-Sleep -Seconds 20
docker logs immich_machine_learning --tail 40 2>&1
