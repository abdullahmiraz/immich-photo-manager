# Project state (continuity for humans & agents)

Last updated: 2026-05-27

## Current stack (intended)

| Container | Image | Role |
|-----------|-------|------|
| immich_server | `immich-server:release` | API (internal); no host port when optimizer on |
| immich_upload_optimizer | `immich-upload-optimizer-patched:v0.5.3` (build `optimizer/`) | Caesium images; videos passthrough; direct response (no redirect wait page) |
| immich_machine_learning | `immich-machine-learning:release` | CPU ONNX |
| immich_postgres | postgres 14-vectorchord | DB; `default` + `immich-deduper` |
| immich_redis | valkey:9 | Job queue (`./data/redis`) |
| immich_deduper | `immich-deduper:latest-cpu` | Duplicate UI :8086 |
| immich_deduper_qdrant | qdrant:v1.16.3 | Deduper vectors |

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
4. **Upload optimizer on by default** — `COMPOSE_PROFILES=optimizer`; Caesium q=85 for JPEG/PNG/WebP/GIF/TIFF; videos passthrough; `IUO_CPUS=2`. Disable: RECIPES → Disable upload optimizer.
5. **Deduper network** — Compose-managed `immich-deduper`.
6. **External library** → `/photos-import` (read-only mount).

## Resolved issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Job settings greyed out | `immich.json` mount or bad `system-config` | RECIPES → Reset job settings UI |
| ML `fetch failed` | `IMMICH_PORT` in `.env` | Remove from `.env`; compose sets per service |
| Bulk upload stalls on :2283 | ImageMagick chains + video transcode + high IUO CPUs | Caesium tasks, video passthrough, `IUO_CPUS=2`; cap Admin job concurrency |
| `redirect was not followed` / `unexpected EOF` on upload | IUO v0.5.3 redirect wait page; Immich web does not poll it | Patched image `optimizer/Dockerfile` → `/usr/local/bin/immich-upload-optimizer`; `docker compose build immich-upload-optimizer` |
| Batch upload dies when a duplicate image is in the mix | Postgres `UQ_assets_owner_checksum` + redirect timeout on other parallel jobs | Patched direct response; duplicates skip one file; see RECIPES → Upload optimizer stability |
| Deduper pull denied | `ghcr.io/razgrizhsu/...` | Use Docker Hub `razgrizhsu/immich-deduper:latest-cpu` |
| `immich_server` won't bind :2283 | Windows excluded range 2280–2379 | RECIPES → Port 2283 blocked (elevated `net stop winnat`, then `compose up`) |

## Data locations (gitignored)

| Path | Contents |
|------|----------|
| `./library` | Immich media |
| `./dedup-data` | Deduper + Qdrant |
| `./data/pgdata`, `./data/redis`, `./data/model-cache` | DB, Redis, ML cache |

## Docker disk (2026-05-24)

- **Removed** `customWslDistroDir: D:\Docker\wsl` — engine back on default `C:\Users\neo\AppData\Local\Docker\wsl`.
- **Deleted** bloated `D:\Docker` (~102 GB VHDX; mostly historical image/layer bloat, not photos).
- **Keep** Immich media/DB on D: via bind mounts (`./library`, `./data/*`) — unchanged.
- **Maintenance:** update with `docker compose pull` + `up -d` only; never `compose down` / `prune -a` on this stack. Use `docker image prune -f` (dangling only) or compact VHDX (RECIPES → Docker disk).

## Open follow-ups

- [ ] Rotate `DB_PASSWORD` from default in `.env`
- [ ] Pin image digests in compose for reproducible deploys
