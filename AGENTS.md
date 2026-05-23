# Agent guide (read this first)

Docker-only project. No app source code in-repo—only Compose, env, and data dirs.

## Read order (minimize tokens)

1. This file (`AGENTS.md`)
2. `docs/STATE.md` — current decisions, pitfalls, last-known-good
3. `docker-compose.yml` + `.env.example` (not `.env` unless user asks)
4. `docs/RUNBOOK.md` — only for install/debug tasks

Do **not** read `library/`, `dedup-data/`, or `setup/` unless the task requires them.

## Project purpose

Self-hosted **Immich** photo library + **immich-deduper** for visual duplicate finding, on **Windows Docker Desktop**.

| URL | Service |
|-----|---------|
| http://localhost:2283 | Immich via upload optimizer (compresses uploads) |
| http://localhost:8086 | immich-deduper UI |

## Repo map (tracked files only)

```
immich/
├── AGENTS.md              ← you are here
├── README.md              ← human index
├── docker-compose.yml     ← single source of infra truth
├── .env.example           ← env template (copy → .env)
├── .gitignore
├── docs/
│   ├── STATE.md           ← continuity / decisions (update when you change behavior)
│   ├── RUNBOOK.md         ← full operator guide
│   └── ARCHITECTURE.md    ← services & networks
└── setup/                 ← BACKUP ONLY, never mount at runtime
    ├── immich-config.json
    └── Screenshot_1.png
```

## Hard rules (do not break)

1. **No `IMMICH_CONFIG_FILE` / no mount of `config/immich.json`** — locks Admin UI job settings; caused duplicates-page freezes.
2. **Deduper image**: `razgrizhsu/immich-deduper:latest` (Docker Hub). **Not** `ghcr.io/razgrizhsu/...` (denied).
3. **Deduper network** is created by Compose (`immich-deduper`); no manual `docker network create`.
4. **Postgres** service `database` must be on networks `default` + `immich-deduper` (deduper reads DB).
5. **Healthchecks**: use `healthcheck: disable: false` (built-in). Do **not** add custom `curl` to port 3001/5000—breaks on Immich v2.
6. **GPU (RX 580 + Windows Docker)**: experimental — `docker compose -f docker-compose.yml -f docker-compose.gpu.yml` + `scripts/enable-wsl-gpu.ps1` before ML recreate. Default stack stays CPU `release`; ROCm may fail on Polaris — check ML logs for `MIGraphXExecutionProvider`.
7. **`setup/`** is reference backup only—do not wire into compose.

## Safe change surface

| OK to edit | Avoid |
|------------|--------|
| `docker-compose.yml`, `.env.example`, `docs/*` | `library/**` (user photos) |
| `README.md`, `AGENTS.md` | `dedup-data/**`, `pgdata` volumes |
| `.gitignore` | Committing `.env` with secrets |

## Common tasks

**Start stack**
```powershell
.\scripts\up.ps1 -d
# or: docker compose up -d  (after reboot run enable-wsl-gpu.ps1 first for GPU ML)
```

**Graceful stop** (preserve jobs)
```powershell
docker compose stop -t 120
```

**Recreate after env change**
```powershell
docker compose up -d --force-recreate
```

**Verify**
```powershell
docker compose ps
# Immich: GET http://localhost:2283/api/server/ping → pong
# Deduper: GET http://localhost:8086 → 200
```

## When editing compose

- Keep `${VAR}` from `.env`; avoid hardcoded `D:\...` paths (use `UPLOAD_LOCATION`, `EXTERNAL_LIBRARY_PATH`).
- `immich-server` needs `CHOKIDAR_USEPOLLING=true` on Windows bind mounts.
- `MACHINE_LEARNING_REQUEST_THREADS=4` (not 8–24)—prevents false ML "unhealthy" during duplicate/migration jobs.
- `./data/` bind mounts for Postgres/Redis/ML cache on D:; Docker engine disk at `D:\Docker\wsl`.
- GPU: AMD RX 580 inline in `docker-compose.yml`; `scripts/up.ps1` runs `enable-wsl-gpu.ps1` before compose up
- Before heavy jobs: `docker compose stop immich-deduper` then `scripts/apply-safe-job-settings.ps1`.

## After meaningful changes

Update `docs/STATE.md` with: what changed, why, and any new pitfalls (2–5 bullets).

## Host context

- OS: Windows 10/11, Docker Desktop (WSL2 backend)
- CPU: Xeon E5-2670 v3, 12C/24T
- GPU: AMD RX 580 — ML uses `release-rocm` + `COMPOSE_FILE` gpu overlay; run `enable-wsl-gpu.ps1` after reboot
