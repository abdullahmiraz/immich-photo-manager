# Project state (continuity for humans & agents)

Last updated: 2026-05-23

## Current stack (intended)

| Container | Image | Role |
|-----------|-------|------|
| immich_server | `immich-server:release` | Web + API on :2283 (direct; optimizer off) |
| immich_machine_learning | `immich-machine-learning:release` | CPU ONNX |
| immich_postgres | postgres 14-vectorchord | DB; `default` + `immich-deduper` |
| immich_redis | valkey:9 | Job queue (`./data/redis`) |
| immich_deduper | `immich-deduper:latest-cpu` | Duplicate UI :8086 |
| immich_deduper_qdrant | qdrant:v1.16.3 | Deduper vectors |
| immich_upload_optimizer | (profile `optimizer`, **off**) | Optional; `compose/overlays/upload-optimizer.yml` |

## Compose layout (modular)

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Core Immich + `include` overlays |
| `docker-compose.deduper.yml` | Deduper + Qdrant (default) |
| `docker-compose.optimizer.yml` | Upload proxy (`--profile optimizer`) |

Operator commands: **`docs/RECIPES.md`** (no PowerShell scripts in repo).

## Decisions (do not revert without reason)

1. **No config file at runtime** — UI controls jobs/ffmpeg/ML. `setup/` is backup only.
2. **CPU ML only** — `release` image; no GPU/ROCm (not supported on Windows Docker for this host).
3. **ML threads capped at 4** — prevents false ML unhealthy / duplicates UI freeze.
4. **Upload optimizer disabled by default** — direct uploads on :2283; enable via `--profile optimizer` (see RECIPES).
5. **Deduper network** — Compose-managed `immich-deduper`.
6. **External library** → `/photos-import` (read-only mount).

## Resolved issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Job settings greyed out | `immich.json` mount or bad `system-config` | RECIPES → Reset job settings UI |
| ML `fetch failed` | `IMMICH_PORT` in `.env` | Remove from `.env`; compose sets per service |
| Bulk upload stalls on :2283 | Upload optimizer + high concurrency | Optimizer off; immich-go on :2283 direct |
| Deduper pull denied | `ghcr.io/razgrizhsu/...` | Use Docker Hub `razgrizhsu/immich-deduper:latest-cpu` |

## Data locations (gitignored)

| Path | Contents |
|------|----------|
| `./library` | Immich media |
| `./dedup-data` | Deduper + Qdrant |
| `./data/pgdata`, `./data/redis`, `./data/model-cache` | DB, Redis, ML cache |

## Open follow-ups

- [ ] Rotate `DB_PASSWORD` from default in `.env`
- [ ] Pin image digests in compose for reproducible deploys
