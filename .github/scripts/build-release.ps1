# Used by CI and local release builds. Run from repo root.
param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host "==> Verify immich-go release asset exists"
$cfg = Get-Content "installer\config.json" -Raw | ConvertFrom-Json
$goUrl = "https://github.com/simulot/immich-go/releases/download/$($cfg.ImmichGoVersion)/$($cfg.ImmichGoAsset)"
try {
    Invoke-WebRequest -Uri $goUrl -Method Head -UseBasicParsing | Out-Null
} catch {
    throw "immich-go asset not found: $goUrl"
}

Write-Host "==> dotnet publish manager"
dotnet publish manager/ImmichPhotoManager/ImmichPhotoManager.csproj `
    -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:Version=$Version `
    -o manager/publish

$managerExe = Join-Path $Root "manager\publish\ImmichPhotoManager.exe"
if (!(Test-Path $managerExe)) {
    throw "Manager exe missing: $managerExe"
}

$iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
if (!(Test-Path $iscc)) {
    throw "Inno Setup not found at $iscc"
}

Write-Host "==> Inno Setup compile"
& $iscc `
    "/DMyAppVersion=$Version" `
    "/DManagerExe=$managerExe" `
    "installer\ImmichPhotoManager.iss"

$setup = Get-ChildItem "installer\output\*.exe" | Select-Object -First 1
if (!$setup) {
    throw "Setup exe not produced in installer\output"
}

$hash = Get-FileHash $setup.FullName -Algorithm SHA256
"$($hash.Hash)  $($setup.Name)" | Set-Content "installer\output\SHA256SUMS.txt" -Encoding utf8
Write-Host "Built: $($setup.FullName)"
Get-Content "installer\output\SHA256SUMS.txt"
