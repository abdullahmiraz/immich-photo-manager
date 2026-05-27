# Installer build

## Prerequisites

- [Inno Setup 6](https://jrsoftware.org/isinfo.php)
- .NET 8 SDK (for the manager app)

## Pre-flight (before tagging)

```powershell
pwsh ./.github/scripts/verify-release-prereqs.ps1
```

## Build manager + setup.exe

From repo root (or CI via `build-release.ps1`):

```powershell
dotnet publish manager\ImmichPhotoManager\ImmichPhotoManager.csproj `
  -c Release -r win-x64 --self-contained true `
  -p:PublishSingleFile=true -o manager\ImmichPhotoManager\bin\publish

& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" `
  /DManagerExe=manager\ImmichPhotoManager\bin\publish\ImmichPhotoManager.exe `
  installer\ImmichPhotoManager.iss
```

Output: `installer\output\ImmichPhotoManager-1.0.0-setup.exe`

## Manager (4 tabs)

`ImmichPhotoManager.exe` is the main UI:

| Tab | Service | Upstream |
|-----|---------|----------|
| Deduper | Docker `immich_deduper` :8086 | [immich-deduper](https://github.com/RazgrizHsu/immich-deduper) |
| Upload optimizer | Docker `immich_upload_optimizer` :2283 | [immich-upload-optimizer](https://github.com/miguelangel-nubla/immich-upload-optimizer) + local patch |
| immich-go | `tools\immich-go\immich-go.exe` | [immich-go](https://github.com/simulot/immich-go) |
| Video cleanup | `tools\video-cleanup\optimize.ps1` | [HandBrake](https://handbrake.fr/) (CLI not bundled) |

Immich core (server, ML, DB) is started from the header via Docker Compose.
