# Immich + Duplicate Remover (Docker)

Self-hosted photo library ([Immich](https://immich.app)) with [immich-deduper](https://github.com/RazgrizHsu/immich-deduper) for visual duplicate detection. Runs on **Windows** via **Docker Desktop** (CPU ML only).

| App | URL |
|-----|-----|
| Immich | http://localhost:2283 (upload optimizer: Caesium images, videos passthrough) |
| immich-deduper | http://localhost:8086 |

## Quick start

```powershell
cd "D:\code\duplicate image remover\immich"
Copy-Item .env.example .env   # edit DB_PASSWORD / PSQL_PASS
docker compose up -d
```

Full first-time steps: **[docs/RECIPES.md](docs/RECIPES.md)**

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/RECIPES.md](docs/RECIPES.md) | **Step-by-step commands** — start, stop, heavy jobs, immich-go, optimizer |
| [docs/RUNBOOK.md](docs/RUNBOOK.md) | Troubleshooting, disk, upgrades |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Services, networks, compose modules |
| [docs/STATE.md](docs/STATE.md) | Decisions & pitfalls (agents) |
| [AGENTS.md](AGENTS.md) | Agent read-first guide |

## Project layout

```
docker-compose.yml           # core Immich
docker-compose.deduper.yml   # add-on (included)
docker-compose.optimizer.yml # add-on (optional profile)
.env.example
optimizer-config/        # Caesium upload tasks (COMPOSE_PROFILES=optimizer)
setup/                   # backup only
library/                 # photos (gitignored)
dedup-data/              # deduper data (gitignored)
```

## External photos

Host: `library/upload/external` → Immich UI path: **`/photos-import`**

Settings: **Immich Admin UI** only (no runtime config file). See [docs/STATE.md](docs/STATE.md).
