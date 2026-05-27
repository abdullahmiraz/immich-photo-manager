param(
    [Parameter(Mandatory = $true)]
    [string]$InstallDir
)

$ErrorActionPreference = "Stop"
$example = Join-Path $InstallDir ".env.example"
$envFile = Join-Path $InstallDir ".env"

if (!(Test-Path $example)) {
    throw ".env.example not found in $InstallDir"
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
