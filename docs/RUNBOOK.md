# Runbook

Full operator guide for this Immich + deduper deployment on **Windows** with **Docker Desktop**.

Quick index: [README.md](../README.md) · Agent context: [AGENTS.md](../AGENTS.md) · State: [STATE.md](STATE.md)

---

## Prerequisites

- Windows 10/11
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL2 backend enabled)
- ~20 GB free disk (Immich images + deduper model cache; first pull is large)
- RAM: 8 GB+ recommended; 16 GB+ for large libraries

---

## First-time setup

### 1. Clone and configure env

```powershell
cd "D:\code\duplicate image remover\immich"
Copy-Item .env.example .env
# Edit .env: set DB_PASSWORD, PSQL_PASS (same value), paths if needed
```

### 2. Create folders (if missing)

```powershell
New-Item -ItemType Directory -Force -Path library, "library\upload\external", dedup-data
```

### 3. Create external Docker network (once per machine)

```powershell
docker network create immich-deduper
```

### 4. Start everything

```powershell
docker compose up -d
```

First start downloads images (several GB). Wait until:

```powershell
docker compose ps
```

All services should show `healthy` or `running` (server may show `health: starting` for ~1 min).

### 5. Open Immich and create admin

1. http://localhost:2283
2. Register the first user (becomes admin).

### 6. External library (optional)

1. Administration → **External Libraries** → Create library
2. Add folder: **`/photos-import`** (container path, not Windows path)
3. Scan library

Host photos live in `library/upload/external`.

### 7. immich-deduper

1. http://localhost:8086
2. Use the UI to index/scan (reads Immich Postgres + `./library`)
3. See [immich-deduper docs](https://github.com/RazgrizHsu/immich-deduper) for thresholds and deletion workflow

---

## Daily commands

| Action | Command |
|--------|---------|
| Start | `docker compose up -d` |
| Stop (graceful) | `docker compose stop -t 120` |
| Logs (all) | `docker compose logs -f` |
| Logs (server) | `docker logs -f immich_server` |
| Logs (deduper) | `docker logs -f immich_deduper` |
| Status | `docker compose ps` |
| Restart one service | `docker compose up -d --force-recreate immich-server` |

After changing `.env`, recreate affected containers:

```powershell
docker compose up -d --force-recreate
```

---

## Health checks

```powershell
# Immich API
Invoke-RestMethod http://localhost:2283/api/server/ping
# Expect: res = pong

# Deduper UI
(Invoke-WebRequest http://localhost:8086 -UseBasicParsing).StatusCode
# Expect: 200
```

---

## Immich duplicate detection (built-in)

1. Administration → **Settings** → enable Smart Search / duplicate detection as needed
2. Administration → **Jobs** → run **Duplicate Detection** (and **Smart Search** if assets lack embeddings)
3. Utilities → **Duplicates** at http://localhost:2283/utilities/duplicates

If the page freezes:

- Check `docker logs immich_server` for `Machine learning server became unhealthy`
- Ensure ML container is healthy: `docker compose ps immich-machine-learning`
- Lower job concurrency in Admin UI if CPU is overloaded
- Do **not** mount a config file (see [STATE.md](STATE.md))

---

## Job settings (Admin UI)

All concurrency and ffmpeg settings are edited in:

**Administration → Settings → Job Settings** (and related sections).

There is **no** `immich.json` mounted in this project. To restore UI control after a bad config import:

```powershell
docker exec immich_postgres psql -U postgres -d immich -c "DELETE FROM system_metadata WHERE key = 'system-config';"
docker compose restart immich-server
```

---

## Backup folder (`setup/`)

| File | Purpose |
|------|---------|
| `setup/immich-config.json` | Exported Immich settings snapshot |
| `setup/Screenshot_1.png` | UI reference |

**Not used at runtime.** To apply: copy values manually in Admin UI, or mount as config (not recommended—locks UI).

---

## Disk spikes & server going offline

**Symptoms:** C: or D: hits 100% during **Storage Template Migration** or **immich-deduper Fetch**; Immich becomes unreachable.

**Root causes on this setup:**

| Cause | Why |
|-------|-----|
| Storage Template Migration | On Windows Docker bind mounts, Immich often **copies** files instead of renaming → needs up to **~1× library size extra free space** (~35 GB for this library) on the same drive as `library/` |
| Docker on C: | Named volumes (`pgdata`, `model-cache`) lived on Docker’s WSL disk (usually **C:**). Only ~38 GB free on C: → WSL VHDX growth fills the disk |
| Parallel jobs | Default job concurrency runs thumbnails + smart search + migration I/O at once |
| Deduper + Immich together | ResNet152 indexing + Qdrant + Immich jobs compete for disk and RAM |

**Fixes applied in this repo:**

- DB/Redis/ML cache → `./data/*` on **D:** (bind mounts, not C: Docker volumes)
- Safe job concurrency → `.\scripts\apply-safe-job-settings.ps1`
- ML threads capped at 4; deduper uses `latest-cpu` with memory/CPU limits

**Before Storage Template Migration**

1. Stop deduper and cap job concurrency:

```powershell
docker compose stop immich-deduper
.\scripts\apply-safe-job-settings.ps1
```

2. Confirm **D: free space ≥ library size + 15 GB** (library ≈ 35 GB → aim for **50+ GB free** on D:).

3. Do **not** run deduper Fetch at the same time.

4. In Admin → Jobs, run only **Storage Template Migration**; wait until finished.

5. If files are already under `library/admin/YYYY/MM/` and match your template, consider **skipping** migration (it may copy every file for no benefit).

**Before immich-deduper Fetch / heavy indexing**

```powershell
docker compose stop immich-deduper
.\scripts\apply-safe-job-settings.ps1
# Wait until Immich Admin → Jobs queues are idle, then Fetch at http://localhost:8086
```

**After heavy work**

```powershell
docker compose start immich-deduper
```

**Docker disk on D:** `D:\Docker\wsl\disk\docker_data.vhdx` (set in `%APPDATA%\Docker\settings.json` → `customWslDistroDir`). App data (`library/`, `data/pgdata`) stays under the project on D:.

---

## Troubleshooting

### `network immich-deduper not found`

```powershell
docker network create immich-deduper
docker compose up -d
```

### Deduper: `Failed to initialize Qdrant`

Ensure `.env` contains:

```
QDRANT_URL=http://qdrant:6333
```

Then: `docker compose up -d --force-recreate immich-deduper`

### Deduper image pull `denied` from ghcr.io

Use Docker Hub image in compose: `razgrizhsu/immich-deduper:latest` (already set in this repo).

### Postgres password mismatch

`DB_PASSWORD`, `PSQL_PASS`, and compose `POSTGRES_PASSWORD` must match. If DB was initialized with another password, either revert `.env` or reset volume (destructive):

```powershell
docker compose down
docker volume rm immich_pgdata   # deletes all Immich DB data
docker compose up -d
```

### Out of disk

- Safe prune (keeps tagged images like `release`, `release-rocm`, `release-openvino`): `docker image prune -f` and `docker builder prune -f`
- Do **not** run `docker system prune -a` if you want to keep ML variant images for later
- Deduper cache: `dedup-data/cache` (safe to delete; re-downloads models on next Fetch)
- Immich uploads: `library/`

### Complete reset (destructive)

```powershell
docker compose down -v
Remove-Item -Recurse -Force dedup-data   # optional: deduper only
# library/ and pgdata volume hold photos/DB — delete only if you want a full wipe
docker network create immich-deduper
docker compose up -d
```

---

## Environment variables reference

See [.env.example](../.env.example). Key variables:

| Variable | Purpose |
|----------|---------|
| `UPLOAD_LOCATION` | Immich media root (`./library`) |
| `EXTERNAL_LIBRARY_PATH` | External import folder on host |
| `DB_*` | Postgres credentials |
| `MACHINE_LEARNING_REQUEST_THREADS` | ML worker threads (use `8`) |
| `DEDUP_*` / `PSQL_*` / `QDRANT_URL` | immich-deduper |

Official Immich env docs: https://docs.immich.app/install/environment-variables

---

## AMD GPU (RX 580) — experimental

Immich ML uses **ROCm** via WSL2 (`/dev/dxg` + `/dev/dri`). Optional images to keep for later: `release-rocm` (AMD), `release-openvino` (Intel/WSL), `release` (CPU fallback).

**After each Windows reboot** (WSL loses `/dev/dxg` until modules load):

```powershell
.\scripts\start-gpu-stack.ps1
```

This runs `enable-wsl-gpu.ps1` and recreates ML with `release-rocm`. `.env` sets `COMPOSE_FILE=docker-compose.yml;docker-compose.gpu.yml` (semicolon on Windows) so plain `docker compose up -d` stays on GPU.

**Verify GPU:**

```powershell
docker inspect immich_machine_learning --format "{{.Config.Image}}"
# expect: .../immich-machine-learning:release-rocm

docker exec immich_machine_learning python -c "import onnxruntime as ort; print(ort.get_available_providers())"
# expect: MIGraphXExecutionProvider (and CPUExecutionProvider)
```

A sysfs vendor warning in logs is normal on Docker Desktop WSL. If only `CPUExecutionProvider`, try `HSA_OVERRIDE_GFX_VERSION=9.0.0` in `.env` and re-run `start-gpu-stack.ps1`.

**Revert to CPU:**

```powershell
# Remove COMPOSE_FILE line from .env, then:
docker compose up -d --force-recreate immich-machine-learning
```

**If ROCm fails:** set `HSA_OVERRIDE_GFX_VERSION=9.0.0` or `8.0.3` in `.env`, recreate ML container. CPU `release` image always works.

### Pull stuck / ENOSPC

Docker disk must be on **D:** with **~20+ GB free**. `%USERPROFILE%\.docker\daemon.json` should include `"max-concurrent-downloads": 10`. Resume: `docker pull ghcr.io/immich-app/immich-machine-learning:release-rocm`

---

## Upgrades

```powershell
docker compose pull
docker compose up -d
```

Pin `IMMICH_VERSION` in `.env` (e.g. `v2`) for controlled upgrades.
