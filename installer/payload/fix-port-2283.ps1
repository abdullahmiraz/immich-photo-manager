# Windows may reserve TCP 2280-2379; see docs/RECIPES.md
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
Write-Host "Stopping Windows NAT (winnat) briefly so Docker can bind :2283..."
net stop winnat
Write-Host "Start Docker stack from Immich Photo Manager, then run: net start winnat"
Read-Host "Press Enter after stack is up to restart winnat"
net start winnat
Write-Host "Done."
