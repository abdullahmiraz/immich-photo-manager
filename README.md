# Immich Photo Manager

**Unofficial community distribution** — one Windows-friendly stack for [Immich](https://immich.app), visual duplicate finding, upload compression, bulk import, and optional pre-import video prep.

> Not affiliated with or endorsed by immich.app. For the upstream photo server, see https://immich.app.

| App | URL |
|-----|-----|
| Immich (via upload optimizer) | http://localhost:2283 |
| immich-deduper | http://localhost:8086 |

## Install

### Option A — Windows installer (recommended)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend, 8 GB+ RAM).
2. Download **`ImmichPhotoManager-*-setup.exe`** from [GitHub Releases](https://github.com/abdullahmiraz/immich-photo-manager/releases) and verify the published SHA256.
3. Run the installer, choose an install folder, wait for images to pull and containers to start.
4. Open Immich at http://localhost:2283 and create the admin user.

Launches **Immich Photo Manager** — a desktop app with **four tabs** (deduper, upload optimizer, immich-go, video cleanup). Each tab links to its own open-source project; Immich stack controls are in the app header.

Full guide: **[docs/SUITE.md](docs/SUITE.md)**

### Option B — Manual (Docker Compose)

```powershell
cd path\to\immich-photo-manager
Copy-Item .env.example .env   # set DB_PASSWORD and PSQL_PASS (same value; not the placeholder)
New-Item -ItemType Directory -Force -Path library, "library\upload\external", dedup-data, data\pgdata, data\redis, data\model-cache
docker compose pull
docker compose up -d
```

First-time and daily commands: **[docs/RECIPES.md](docs/RECIPES.md)**

## What’s included

| Layer | Role |
|-------|------|
| Immich | Photo/video library, mobile apps, ML search |
| immich-deduper | Visual duplicate review UI |
| Upload optimizer | Caesium on images; videos passthrough; patched for stable web uploads |
| immich-go | Bulk import from disk (downloaded by installer) |
| video-cleanup | Optional HandBrake batch transcode before upload |

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/SUITE.md](docs/SUITE.md) | Installer, tools, security overview |
| [docs/RECIPES.md](docs/RECIPES.md) | Step-by-step commands |
| [docs/RUNBOOK.md](docs/RUNBOOK.md) | Troubleshooting |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Services and networks |
| [docs/STATE.md](docs/STATE.md) | Decisions and pitfalls |
| [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) | Licenses and upstream projects |
| [SECURITY.md](SECURITY.md) | Reporting and hardening |

## Project layout

```
docker-compose.yml              # core Immich
docker-compose.deduper.yml      # deduper + Qdrant (included)
docker-compose.optimizer.yml    # upload optimizer (profile)
.env.example
optimizer/                      # patched upload optimizer build
optimizer-config/
tools/
  immich-go/                   # populated by installer
  video-cleanup/
manager/                        # 4-tab WinForms app (ImmichPhotoManager.exe)
installer/                      # Inno Setup + payload scripts
docs/
setup/                          # backup reference only — not mounted at runtime
```

## Requirements

- Windows 10/11 with Docker Desktop (WSL2)
- 8 GB RAM minimum (16 GB recommended for ML jobs)
- Disk: library size + ~15 GB for DB/ML/cache

CPU ML only (no GPU overlay in this stack).

## License

MIT for this repository’s Compose, docs, and installer scripts. Bundled applications (Immich, immich-go, etc.) are under their own licenses — see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
