# Speed up Docker image pulls (parallel layer downloads).
# Merges into %USERPROFILE%\.docker\daemon.json and restarts Docker Desktop.
# Usage: .\scripts\configure-docker-fast-pulls.ps1

$ErrorActionPreference = 'Stop'

function Read-DaemonHashtable {
    param([string]$Path)
    $ht = @{}
    if (-not (Test-Path $Path)) { return $ht }
    $raw = (Get-Content $Path -Raw).Trim()
    if (-not $raw) { return $ht }
    $obj = $raw | ConvertFrom-Json
    if ($obj -is [System.Collections.IDictionary]) { return $obj }
    $obj.PSObject.Properties | ForEach-Object { $ht[$_.Name] = $_.Value }
    return $ht
}

$dockerDir = Join-Path $env:USERPROFILE '.docker'
$daemonPath = Join-Path $dockerDir 'daemon.json'
New-Item -ItemType Directory -Force -Path $dockerDir | Out-Null

if (Test-Path $daemonPath) {
    $backup = "$daemonPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $daemonPath $backup -Force
    Write-Host "Backed up daemon.json -> $backup"
}

$existing = Read-DaemonHashtable -Path $daemonPath

$existing['max-concurrent-downloads'] = 10
$existing['max-concurrent-uploads'] = 5
$existing['max-download-attempts'] = 5

$json = $existing | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($daemonPath, $json)
Write-Host "Updated $daemonPath :"
Get-Content $daemonPath

Write-Host "`nRestarting Docker Desktop to apply (containers will stop briefly)..."
docker desktop restart 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Run manually: Docker Desktop -> Restart"
    exit 1
}

$deadline = (Get-Date).AddMinutes(3)
while ((Get-Date) -lt $deadline) {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker is ready."
        docker info 2>&1 | Select-String 'Concurrent Download'
        exit 0
    }
    Start-Sleep -Seconds 5
}
Write-Warning "Docker did not become ready within 3 minutes. Open Docker Desktop and wait until running."
