# Start Immich ML with AMD GPU (RX 580) on Windows Docker Desktop.
# Run once per Windows boot (before compose) — loads /dev/dri and /dev/dxg in WSL.
# Usage: .\scripts\start-gpu-stack.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

& "$Root\scripts\enable-wsl-gpu.ps1"

Write-Host "Recreating immich-machine-learning with release-rocm..."
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d --force-recreate immich-machine-learning

Start-Sleep 15
$providers = docker exec immich_machine_learning python -c "import onnxruntime as ort; print(','.join(ort.get_available_providers()))" 2>$null
if (-not $providers) {
    Start-Sleep 10
    $providers = docker exec immich_machine_learning python -c "import onnxruntime as ort; print(','.join(ort.get_available_providers()))" 2>$null
}
Write-Host "ONNX providers: $providers"

if ($providers -notmatch 'MIGraphX|ROCM') {
    Write-Warning @"
GPU provider not detected — ML may fall back to CPU.
- Confirm AMD drivers and Docker Desktop GPU/WSL integration
- Try HSA_OVERRIDE_GFX_VERSION=9.0.0 or 8.0.3 in .env, then re-run this script
- Revert: docker compose up -d --force-recreate immich-machine-learning
"@
    exit 1
}

Write-Host "GPU ML OK (MIGraphX/ROCm). Immich: http://localhost:2283"
