# Immich + Duplicate Remover (Docker)

Self-hosted photo library ([Immich](https://immich.app)) with [immich-deduper](https://github.com/RazgrizHsu/immich-deduper) for visual duplicate detection. Runs on **Windows** via **Docker Desktop**.

| App | URL |
|-----|-----|
| Immich (via upload optimizer) | http://localhost:2283 |
| immich-deduper | http://localhost:8086 |

## Quick start

**First time only:**

```powershell
cd "D:\code\duplicate image remover\immich"
Copy-Item .env.example .env   # edit passwords if needed
```

**Start (recommended on Windows — loads GPU + full stack):**

```powershell
.\scripts\up.ps1 -d
```

**Or plain Compose** (works if Docker Desktop is already running and WSL GPU was loaded this session):

```powershell
docker compose up -d
```

Open http://localhost:2283 (upload optimizer → Immich). Deduper: http://localhost:8086

## Documentation

| Doc | Audience | Contents |
|-----|----------|----------|
| [docs/RUNBOOK.md](docs/RUNBOOK.md) | Operators | Install, daily use, troubleshooting |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Everyone | Services, networks, volumes |
| [docs/STATE.md](docs/STATE.md) | Maintainers & AI | Current decisions, pitfalls, changelog |
| [AGENTS.md](AGENTS.md) | Coding agents | Read-first guide, hard rules, file map |

## AI / Cursor agents

Start with **[AGENTS.md](AGENTS.md)** then **[docs/STATE.md](docs/STATE.md)**. Do not scan `library/` or `dedup-data/`.

## Project layout

```
docker-compose.yml   # infrastructure
.env.example         # copy → .env
setup/               # backup only (config export + screenshot)
library/             # photos (gitignored)
dedup-data/          # deduper data (gitignored)
```

## External photos

- Host: `library/upload/external`
- In Immich UI use container path: **`/photos-import`**

## Settings

Configured in **Immich Admin UI** (no runtime config file). See [docs/STATE.md](docs/STATE.md) for why.
