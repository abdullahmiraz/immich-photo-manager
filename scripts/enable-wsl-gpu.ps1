# Load GPU devices in WSL2 (required before ROCm ML container on Windows).
# Run once per Windows boot, then start stack with docker-compose.gpu.yml
# Usage: .\scripts\enable-wsl-gpu.ps1

$ErrorActionPreference = 'Stop'

Write-Host "Loading WSL GPU modules (vgem, amdgpu)..."
wsl -e sh -c "modprobe vgem 2>/dev/null; modprobe amdgpu 2>/dev/null; chmod 666 /dev/dri/* 2>/dev/null; ls -la /dev/dri /dev/dxg 2>&1"

$check = wsl -e sh -c "test -e /dev/dri/card0 && test -e /dev/dxg && echo ok"
if ($check -notmatch 'ok') {
    Write-Warning @"
GPU devices not ready in WSL.
- Update AMD Adrenalin drivers on Windows
- Docker Desktop: Settings -> Resources -> enable GPU / WSL integration
- Reboot Windows, then run this script again
"@
    exit 1
}

Write-Host "WSL GPU devices OK. Start ML with GPU:"
Write-Host '  docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --force-recreate immich-machine-learning'
