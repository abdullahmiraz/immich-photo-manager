# Runbook

Troubleshooting and deep reference. **Day-to-day commands:** [RECIPES.md](RECIPES.md).

Index: [README.md](../README.md) · [AGENTS.md](../AGENTS.md) · [STATE.md](STATE.md) · [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Prerequisites

- Windows 10/11, Docker Desktop (WSL2)
- ~20 GB free disk for images + model cache
- 16 GB+ RAM recommended for large libraries

First install: **[RECIPES.md → First-time setup](RECIPES.md#first-time-setup)**

---

## Daily operations

See **[RECIPES.md](RECIPES.md)** — start, stop, health checks, upgrades, immich-go, optimizer toggle.

---

## Immich duplicate detection (built-in)

1. Administration → **Settings** → enable Smart Search / duplicate detection
2. Administration → **Jobs** → **Duplicate Detection** / **Smart Search**
3. Utilities → **Duplicates** at http://localhost:2283/utilities/duplicates

If the page freezes: ML unhealthy → `docker compose ps`, lower job concurrency (RECIPES → Before heavy jobs), never mount config file.

---

## External library

1. Administration → **External Libraries** → Create library
2. Folder: **`/photos-import`**
3. Scan library

Host path: `library/upload/external`.

**Note:** Storage Template Migration does **not** move external-library assets into `library/library/admin/…`. Use immich-go for internal imports (RECIPES).

---

## Disk spikes & server offline

| Cause | Mitigation |
|-------|------------|
| Storage Template Migration on Windows bind mounts | Needs ~1× library size free on D:; often **copies** files |
| Parallel Immich jobs | Cap concurrency — RECIPES → Before heavy jobs |
| Deduper + Immich together | Stop deduper before heavy Immich work |
| Docker WSL disk bloat | Default location `C:\Users\<you>\AppData\Local\Docker\wsl`; prune images — RECIPES → Docker disk |
| Large library on D: | Keep `./library` and `./data/` bind mounts on D: (not inside Docker VHDX) |

---

## Troubleshooting

### Deduper cannot reach Postgres

`database` must be on `default` + `immich-deduper`. Recreate: `docker compose up -d --force-recreate database immich-deduper`.

### Deduper: `Failed to initialize Qdrant`

`.env` needs `QDRANT_URL=http://qdrant:6333`. Then `docker compose up -d --force-recreate immich-deduper`.

### Deduper pull denied (ghcr.io)

Use `razgrizhsu/immich-deduper:latest-cpu` on Docker Hub (set in compose).

### Postgres password mismatch

`DB_PASSWORD`, `PSQL_PASS`, and compose must match. Destructive reset:

```powershell
docker compose down
Remove-Item -Recurse -Force .\data\pgdata
docker compose up -d
```

### ML `fetch failed`

Remove `IMMICH_PORT` from `.env` if present. Compose sets server=2283, ML=3003.

### Out of disk

```powershell
docker image prune -f
docker compose pull
docker compose up -d
```

### Complete reset (destructive)

```powershell
docker compose down -v
Remove-Item -Recurse -Force dedup-data
docker compose up -d
```

### Job settings greyed out

[RECIPES.md → Reset job settings UI](RECIPES.md#reset-job-settings-ui)

---

## Environment variables

See [.env.example](../.env.example). Official docs: https://docs.immich.app/install/environment-variables

**Never set `IMMICH_PORT` in `.env`.**

---

## Backup folder (`setup/`)

| File | Purpose |
|------|---------|
| `immich-config.json` | Exported settings snapshot |
| `safe-job-settings.json` | Job concurrency reference for Admin UI |
| `external-library-exclusion-patterns-screenshot.png` | External Library folder/exclusion-pattern UI reference |

Not mounted at runtime.

---

## Upgrades

[RECIPES.md → Upgrade Immich](RECIPES.md#upgrade-immich)
