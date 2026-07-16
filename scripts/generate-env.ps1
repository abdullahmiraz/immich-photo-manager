# Generate .env from .env.example with a randomized DB password.
param(
    [string]$InstallDir = (Split-Path $PSScriptRoot -Parent),
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$example = Join-Path $InstallDir ".env.example"
$envFile = Join-Path $InstallDir ".env"

if (!(Test-Path $example)) {
    throw ".env.example not found in $InstallDir"
}

if ((Test-Path $envFile) -and !$Force) {
    throw ".env already exists at $envFile — pass -Force to overwrite (this will not update a running stack's DB password)."
}

function New-RandomPassword {
    $bytes = New-Object byte[] 24
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes) -replace '[^a-zA-Z0-9]', 'x'
}

$pass = New-RandomPassword
$content = Get-Content $example -Raw
$content = $content -replace 'DB_PASSWORD=GENERATE_ON_INSTALL', "DB_PASSWORD=$pass"
$content = $content -replace 'PSQL_PASS=GENERATE_ON_INSTALL', "PSQL_PASS=$pass"
Set-Content -Path $envFile -Value $content -Encoding UTF8
Write-Host "Created .env with generated database password."
