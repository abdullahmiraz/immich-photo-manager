# Maintainer: build and push patched upload optimizer to Docker Hub.
# Requires: docker login, Docker Hub repo abdullahmiraz/immich-upload-optimizer-patched
# Usage: .\scripts\publish-optimizer-image.ps1 [-Tag v0.5.3]

param(
    [string]$Tag = "v0.5.3"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$Image = "abdullahmiraz/immich-upload-optimizer-patched:$Tag"
Push-Location $Root
try {
    docker compose build immich-upload-optimizer
    docker tag "abdullahmiraz/immich-upload-optimizer-patched:$Tag" $Image 2>$null
    docker push $Image
    Write-Host "Published $Image" -ForegroundColor Green
    Write-Host "Set IUO_IMAGE=$Image in .env or use default in .env.example"
} finally {
    Pop-Location
}
