param(
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$failures = @()

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    $failures += "Docker CLI not found. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
} else {
    $info = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures += "Docker is installed but not running. Start Docker Desktop and try again."
    }
}

$os = Get-CimInstance Win32_OperatingSystem
$ramGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
if ($ramGb -lt 7.5) {
    $failures += "At least 8 GB RAM recommended (detected ~${ramGb} GB visible)."
}

if ($failures.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host "Prerequisite check failed:" -ForegroundColor Red
        $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
    exit 1
}

if (-not $Quiet) {
    Write-Host "Prerequisites OK (Docker running, RAM ~${ramGb} GB)." -ForegroundColor Green
}
exit 0
