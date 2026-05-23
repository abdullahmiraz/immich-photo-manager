# Merge setup/safe-job-settings.json into Immich system-config (Postgres).
# Safe for Windows + Docker bind mounts: lowers parallel disk I/O during migrations/deduper.
# Usage: .\scripts\apply-safe-job-settings.ps1

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PatchPath = Join-Path $Root 'setup\safe-job-settings.json'

if (-not (Test-Path $PatchPath)) {
    Write-Error "Missing $PatchPath"
}

$patch = Get-Content $PatchPath -Raw | ConvertFrom-Json
$patchJson = ($patch | ConvertTo-Json -Compress -Depth 20)

$container = 'immich_postgres'
$running = docker ps --filter "name=$container" --format '{{.Names}}' 2>$null
if (-not $running) {
    Write-Error "Start the stack first: docker compose up -d"
}

# Read current config (may be empty or partial)
$currentRaw = docker exec $container psql -U postgres -d immich -t -A -c `
    "SELECT COALESCE(value::text, '{}') FROM system_metadata WHERE key = 'system-config';"
$currentRaw = ($currentRaw -join '').Trim()
if ([string]::IsNullOrWhiteSpace($currentRaw)) { $currentRaw = '{}' }

$current = $currentRaw | ConvertFrom-Json

foreach ($prop in $patch.PSObject.Properties) {
    $name = $prop.Name
    if (-not $current.PSObject.Properties[$name]) {
        Add-Member -InputObject $current -NotePropertyName $name -NotePropertyValue $prop.Value
    } else {
        $target = $current.$name
        foreach ($sub in $prop.Value.PSObject.Properties) {
            if ($target.PSObject.Properties[$sub.Name]) {
                $target.$($sub.Name) = $sub.Value
            } else {
                Add-Member -InputObject $target -NotePropertyName $sub.Name -NotePropertyValue $sub.Value
            }
        }
    }
}

$merged = ($current | ConvertTo-Json -Compress -Depth 30)
# Escape single quotes for SQL
$mergedSql = $merged.Replace("'", "''")

$sql = @"
INSERT INTO system_metadata (key, value)
VALUES ('system-config', '$mergedSql'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
"@

$sql | docker exec -i $container psql -U postgres -d immich -q
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to update system_metadata (exit $LASTEXITCODE)"
}

Write-Host "Applied safe job settings. Restarting immich-server..."
Set-Location $Root
docker compose restart immich-server | Out-Null
Write-Host "Done. Job concurrency is now capped (migration=1, smartSearch=2, thumbnails=2, etc.)."
