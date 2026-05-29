# Run Cloudflare Tunnel on Windows (outside Docker). Use when Docker cloudflared cannot reach edge (Error 1033).
# Prerequisite: winget install Cloudflare.cloudflared
# Dashboard route: http://localhost:2283 (not immich-upload-optimizer)

$ErrorActionPreference = "Stop"
$Root = if ($PSScriptRoot) { Resolve-Path (Join-Path $PSScriptRoot "..") } else { Get-Location }
$envFile = Join-Path $Root ".env"

if (!(Test-Path $envFile)) {
    throw ".env not found at $envFile"
}

$token = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*CLOUDFLARE_TUNNEL_TOKEN=(.+)\s*$') {
        $token = $matches[1].Trim('"').Trim("'")
    }
}

if ([string]::IsNullOrWhiteSpace($token) -or $token -eq 'CLOUDFLARE_TUNNEL_TOKEN') {
    throw "Set CLOUDFLARE_TUNNEL_TOKEN in .env to the real token from Cloudflare Zero Trust (not the placeholder name)."
}

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
    throw "cloudflared not on PATH. Install: winget install Cloudflare.cloudflared"
}

Write-Host "Stopping Docker cloudflared (if any)..." -ForegroundColor Yellow
Push-Location $Root
docker compose --profile cloudflare stop cloudflared 2>$null
Pop-Location

Write-Host "Starting tunnel on Windows host (http2)..." -ForegroundColor Green
Write-Host "Dashboard service URL should be: http://localhost:2283"
Write-Host ""
Write-Host "Live logs in Cloudflare stay empty until you see 'Registered tunnel connection' below." -ForegroundColor Yellow
Write-Host "If you see TLS handshake EOF / port 7844 blocked, see docs/CLOUDFLARE-FIX.md" -ForegroundColor Yellow
Write-Host ""
& $cloudflared.Source tunnel --no-autoupdate --protocol http2 run --token $token
