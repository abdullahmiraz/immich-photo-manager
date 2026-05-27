# Agent guide (read this first)

Docker-only project. No app source code in-repo—only Compose, env, and data dirs.

## Read order (minimize tokens)

1. This file (`AGENTS.md`)
2. `docs/STATE.md` — current decisions, pitfalls, last-known-good
3. `docker-compose.yml` + `compose/` + `.env.example` (not `.env` unless user asks)
4. `docs/RECIPES.md` — copy-paste playbooks
5. `docs/RUNBOOK.md` — troubleshooting only

Do **not** read `library/`, `dedup-data/`, or `setup/` unless the task requires them.

## Project purpose

Self-hosted **Immich** photo library + **immich-deduper** for visual duplicate finding, on **Windows Docker Desktop**. **CPU ML only** — no GPU/ROCm.

| URL | Service |
|-----|---------|
| http://localhost:2283 | Immich (via upload optimizer — Caesium on images) |
| http://localhost:8086 | immich-deduper UI |

## Repo map (tracked files only)

```
immich/
├── AGENTS.md
├── README.md
├── docker-compose.yml              ← core Immich
├── docker-compose.deduper.yml      ← add-on (included)
├── docker-compose.optimizer.yml    ← add-on (--profile optimizer)
├── .env.example
├── optimizer-config/tasks.yaml ← used only with --profile optimizer
├── docs/
│   ├── RECIPES.md              ← step-by-step commands (no scripts)
│   ├── RUNBOOK.md
│   ├── STATE.md
│   └── ARCHITECTURE.md
└── setup/                      ← BACKUP ONLY, never mount at runtime
```

## Hard rules (do not break)

1. **No `IMMICH_CONFIG_FILE` / no mount of `config/immich.json`** — locks Admin UI job settings.
2. **Deduper image**: `razgrizhsu/immich-deduper:latest-cpu` on Docker Hub. **Not** `ghcr.io/razgrizhsu/...`.
3. **Postgres** `database` on networks `default` + `immich-deduper`.
4. **Healthchecks**: `healthcheck: disable: false` only — no custom `curl` on 3001/5000.
5. **ML is CPU-only** — `release` image; no ROCm/GPU devices or overlays.
6. **Do not set `IMMICH_PORT` in `.env`** — compose sets server=2283, ML=3003 per service.
7. **`setup/`** is reference backup only.
8. **Never remove required stack containers** — update with `docker compose pull` + `up -d` only. Do **not** run `docker compose down`, `docker system prune -a`, or `docker image prune -a` for this project (see RECIPES → Update stack).

## Common tasks

See **[docs/RECIPES.md](docs/RECIPES.md)** for all commands. Short form:

```powershell
docker compose pull && docker compose up -d   # update images, keep stack
docker compose stop -t 120                    # graceful pause only
docker compose up -d --force-recreate         # after .env change
```

## When editing compose

- Core in `docker-compose.yml`; add-ons as `docker-compose.*.yml` in project root (not subfolders — avoids wrong bind-mount paths).
- Keep `${VAR}` from `.env`; no hardcoded `D:\...` paths.
- `CHOKIDAR_USEPOLLING=true` on `immich-server` (Windows bind mounts).
- `MACHINE_LEARNING_REQUEST_THREADS=4` in `.env.example`.
- Before heavy jobs: see RECIPES → "Before heavy Immich jobs".

## After meaningful changes

Update `docs/STATE.md` (2–5 bullets).

## Host context

- Windows 10/11, Docker Desktop (WSL2)
- CPU: Xeon E5-2670 v3, 12C/24T
- ML: CPU `release` only
