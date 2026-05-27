param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("start", "stop", "update")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$config = Join-Path $env:LOCALAPPDATA "ImmichPhotoManager\install.json"
if (!(Test-Path $config)) {
    Write-Error "Install not found. Run Immich Photo Manager Setup first."
}
$install = (Get-Content $config | ConvertFrom-Json).InstallPath
Set-Location $install

switch ($Action) {
    "start"  { docker compose up -d }
    "stop"   { docker compose stop -t 120 }
    "update" { docker compose pull; docker compose up -d }
}
