# Immich Photo Manager (desktop)

WinForms app — **four tabs**, one per companion service. Immich itself runs in Docker; the header controls the full stack.

| Tab | Upstream |
|-----|----------|
| Deduper | [immich-deduper](https://github.com/RazgrizHsu/immich-deduper) |
| Upload optimizer | [immich-upload-optimizer](https://github.com/miguelangel-nubla/immich-upload-optimizer) + repo patch |
| immich-go | [immich-go](https://github.com/simulot/immich-go) |
| Video cleanup | [HandBrake](https://handbrake.fr/) (CLI installed separately) |

## Dev build

Requires [.NET 8 SDK](https://dotnet.microsoft.com/download).

```powershell
dotnet run --project manager\ImmichPhotoManager\ImmichPhotoManager.csproj
```

Run from repo root so `docker-compose.yml` is discovered, or install via setup.exe (writes `%LOCALAPPDATA%\ImmichPhotoManager\install.json`).
