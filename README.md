# Immich (Docker Compose, Windows-friendly)

A self-hosted [Immich](https://immich.app) Docker Compose deployment with optional add-ons: visual duplicate finding, upload compression, bulk import, and pre-import video prep.

> Not affiliated with or endorsed by immich.app. For the upstream photo server, see https://immich.app.

| App | URL |
|-----|-----|
| Immich (via upload optimizer) | http://localhost:2283 |
| immich-deduper | http://localhost:8086 |

## Install

```powershell
cd path\to\immich
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
| immich-go | Bulk import from disk (see [tools/immich-go](tools/immich-go/README.md)) |
| video-cleanup | Optional HandBrake batch transcode before upload |

## Documentation

Full index: **[docs/README.md](docs/README.md)**.

| Doc | Contents |
|-----|----------|
| [docs/REMOTE_ACCESS.md](docs/REMOTE_ACCESS.md) | Cloudflare Tunnel (photos.miraz.dev) |
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
  immich-go/                   # bulk import CLI (see its README to install)
  video-cleanup/
docs/
setup/                          # backup reference only — not mounted at runtime
```

## Requirements

- Windows 10/11 with Docker Desktop (WSL2)
- 8 GB RAM minimum (16 GB recommended for ML jobs)
- Disk: library size + ~15 GB for DB/ML/cache

CPU ML only (no GPU overlay in this stack).

## License

MIT for this repository’s Compose files, docs, and scripts. Bundled applications (Immich, immich-go, etc.) are under their own licenses — see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
