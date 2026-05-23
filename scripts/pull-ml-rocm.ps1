# Pull Immich ROCm ML image with retries (resumes partial layers after failed pulls).
# Run configure-docker-fast-pulls.ps1 first for parallel layer downloads.
# Usage: .\scripts\pull-ml-rocm.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$tag = if ($env:IMMICH_VERSION) { $env:IMMICH_VERSION } else { 'release' }
$image = "ghcr.io/immich-app/immich-machine-learning:${tag}-rocm"

Write-Host "Pulling $image (large image; layers download in parallel after fast-pull config)..."
$maxAttempts = 5
for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "--- Attempt $i / $maxAttempts ---"
    docker pull $image
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pull complete."
        exit 0
    }
    if ($i -lt $maxAttempts) {
        Write-Host "Pull failed; retrying in 10s (Docker resumes completed layers)..."
        Start-Sleep -Seconds 10
    }
}
Write-Error "Pull failed after $maxAttempts attempts. Check disk space on D: and network, then retry."
exit 1
