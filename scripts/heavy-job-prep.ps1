# Run before Storage Template Migration or immich-deduper Fetch/indexing.
# Stops deduper, applies safe job limits, pauses non-essential Immich jobs via low concurrency.
# Usage: .\scripts\heavy-job-prep.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "Stopping immich-deduper (frees CPU, disk, RAM)..."
docker compose stop immich-deduper 2>$null

& (Join-Path $Root 'scripts\apply-safe-job-settings.ps1')

Write-Host ""
Write-Host "Heavy-job prep complete."
Write-Host "  - Ensure free space on D: >= library size (check: library is ~35GB -> need ~40GB+ free)"
Write-Host "  - Do NOT run Storage Template Migration + deduper Fetch at the same time"
Write-Host "  - After work: docker compose start immich-deduper"
