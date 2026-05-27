# Pre-flight checks before tagging a release. Run from repo root:
#   pwsh ./.github/scripts/verify-release-prereqs.ps1

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

$cfg = Get-Content "installer\config.json" -Raw | ConvertFrom-Json
$goUrl = "https://github.com/simulot/immich-go/releases/download/$($cfg.ImmichGoVersion)/$($cfg.ImmichGoAsset)"
Write-Host "Checking immich-go asset: $goUrl"
Invoke-WebRequest -Uri $goUrl -Method Head -UseBasicParsing | Out-Null
Write-Host "OK: immich-go asset exists"

if (!(Test-Path "manager/ImmichPhotoManager/ImmichPhotoManager.csproj")) {
    throw "Manager project missing"
}
Write-Host "OK: manager project present"

if (!(Test-Path "installer/ImmichPhotoManager.iss")) {
    throw "Inno Setup script missing"
}
Write-Host "OK: installer script present"

Write-Host "All prereq checks passed."
