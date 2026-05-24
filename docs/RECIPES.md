# Recipes

Copy-paste playbooks for common situations. All commands assume project root:

```powershell
cd "D:\code\duplicate image remover\immich"
```

| Recipe | When |
|--------|------|
| [First-time setup](#first-time-setup) | New install |
| [Start / stop / status](#start--stop--status) | Daily use |
| [Verify health](#verify-health) | After start or changes |
| [Recreate after `.env` change](#recreate-after-env-change) | Edited `.env` |
| [Before heavy Immich jobs](#before-heavy-immich-jobs) | Storage migration, large scans |
| [immich-go bulk upload](#immich-go-bulk-upload) | Import from disk |
| [Enable upload optimizer](#enable-upload-optimizer) | Optional ImageMagick compression |
| [Disable upload optimizer](#disable-upload-optimizer) | Default — direct uploads |
| [Upgrade Immich](#upgrade-immich) | New release |
| [Reset job settings UI](#reset-job-settings-ui) | Greyed-out Admin job settings |
| [Update stack (keep containers)](#update-stack-keep-containers) | Upgrade images without removing services |
| [Docker disk (C: vs D:)](#docker-disk-c-vs-d) | WSL disk bloat, safe cleanup, where data lives |

---

## First-time setup

```powershell
cd "D:\code\duplicate image remover\immich"
Copy-Item .env.example .env
# Edit .env: set DB_PASSWORD and PSQL_PASS to the same value

New-Item -ItemType Directory -Force -Path library, "library\upload\external", dedup-data, data\pgdata, data\redis, data\model-cache

docker compose pull
docker compose up -d
docker compose ps
```

Open http://localhost:2283 and register the first user (admin).

---

## Start / stop / status

**Start (detached):**

```powershell
docker compose up -d
```

**Graceful stop** (keeps job queue state):

```powershell
docker compose stop -t 120
```

**Status:**

```powershell
docker compose ps
```

**Logs:**

```powershell
docker compose logs -f
docker logs -f immich_server
docker logs -f immich_deduper
```

---

## Verify health

```powershell
Invoke-RestMethod http://localhost:2283/api/server/ping
# Expect: res = pong

(Invoke-WebRequest http://localhost:8086 -UseBasicParsing).StatusCode
# Expect: 200
```

---

## Recreate after `.env` change

```powershell
docker compose up -d --force-recreate
```

Recreate one service only:

```powershell
docker compose up -d --force-recreate immich-server
```

---

## Before heavy Immich jobs

Use before **Storage Template Migration**, large Smart Search runs, or when the host disk/RAM spikes.

**1. Stop deduper** (reduces disk + RAM contention):

```powershell
docker compose stop immich-deduper
```

**2. Cap job concurrency** — Administration → **Settings** → **Job Settings**, use values from `setup/safe-job-settings.json`:

| Job | Concurrency |
|-----|-------------|
| migration | 1 |
| smartSearch | 2 |
| thumbnailGeneration | 2 |
| faceDetection | 1 |
| videoConversion | 1 |
| library | 1 |
| metadataExtraction | 2 |
| search | 2 |
| ocr | 1 |

**3. Confirm free disk** on D: ≥ library size + 15 GB before Storage Template Migration.

**4. Run one job at a time** in Administration → **Jobs**.

**5. When finished:**

```powershell
docker compose start immich-deduper
```

---

## immich-go bulk upload

Optimizer is **off** by default — use port **2283** (direct server).

**Windows (project root):**

```powershell
.\immich-go\immich-go.exe upload from-folder `
  --server="http://localhost:2283" `
  --api-key="YOUR_API_KEY" `
  --concurrent-tasks=2 `
  --client-timeout=60m `
  --on-errors=continue `
  --pause-immich-jobs=true `
  --date-from-name=true `
  "D:\fixed\realme6"
```

**Git Bash:**

```bash
./immich-go/immich-go.exe upload from-folder \
  --server="http://localhost:2283" \
  --api-key="YOUR_API_KEY" \
  --concurrent-tasks=2 \
  --client-timeout=60m \
  --on-errors=continue \
  --pause-immich-jobs=true \
  --date-from-name=true \
  "/d/fixed/realme6"
```

API key: Immich → Account Settings → API Keys.

Re-run the same command after interruption — already-uploaded files are skipped.

---

## Enable upload optimizer

Optional ImageMagick compression (`optimizer-config/tasks.yaml`). **Only one service can bind host :2283.**

**1. Comment out** `immich-server` `ports:` in `docker-compose.yml`:

```yaml
    # ports:
    #   - "${IMMICH_HOST_PORT:-2283}:2283"
```

**2. Start with optimizer profile:**

```powershell
docker compose --profile optimizer up -d --force-recreate
```

**3. Verify:** http://localhost:2283 (traffic goes through optimizer → server).

---

## Disable upload optimizer

**1. Restore** `immich-server` `ports:` in `docker-compose.yml`.

**2. Recreate without optimizer profile:**

```powershell
docker compose stop immich-upload-optimizer
docker compose up -d --force-recreate immich-server
```

---

## Update stack (keep containers)

**Required services** (do not remove; only update in place):

| Container | Service | Role |
|-----------|---------|------|
| `immich_server` | immich-server | Web + API :2283 |
| `immich_machine_learning` | immich-machine-learning | CPU ML |
| `immich_postgres` | database | Postgres |
| `immich_redis` | redis | Job queue |
| `immich_deduper` | immich-deduper | Duplicate UI :8086 |
| `immich_deduper_qdrant` | qdrant | Deduper vectors |

Optional (only with `--profile optimizer`): `immich_upload_optimizer`.

**Upgrade / recreate** (same containers, new image layers; bind mounts unchanged):

```powershell
docker compose pull
docker compose up -d
```

After `.env` changes:

```powershell
docker compose up -d --force-recreate
```

**Do not run on this project** (removes containers and/or all images — forces full re-pull):

```powershell
# docker compose down          # removes project containers
# docker system prune -a       # deletes all unused images
# docker image prune -a        # deletes images not used by a container
```

Pin version in `.env`: `IMMICH_VERSION=release` (or a specific tag).

---

## Upgrade Immich

Same as [Update stack (keep containers)](#update-stack-keep-containers):

```powershell
docker compose pull
docker compose up -d
```

---

## Reset job settings UI

If Administration → Job Settings is greyed out:

```powershell
docker exec immich_postgres psql -U postgres -d immich -c "DELETE FROM system_metadata WHERE key = 'system-config';"
docker compose restart immich-server
```

Then set jobs in the Admin UI (do **not** mount `immich.json` at runtime).

---

## Compose modules (reusable pieces)

| File | Role |
|------|------|
| `docker-compose.yml` | Core Immich: server, ML, Redis, Postgres |
| `docker-compose.deduper.yml` | immich-deduper + Qdrant (included by default) |
| `docker-compose.optimizer.yml` | Upload proxy (`--profile optimizer`) |

Add future add-ons as `docker-compose.<name>.yaml` in the project root and add to `include:` in `docker-compose.yml`.

---

## Docker disk (C: vs D:)

**Where things live (optimized layout):**

| What | Location | Size (typical) |
|------|----------|----------------|
| Docker engine + images | `C:\Users\<you>\AppData\Local\Docker\wsl` | ~10–15 GB |
| Photos, DB, Redis, ML cache | Project folder `./library`, `./data/*` on **D:** | Your library size |
| Deduper data | `./dedup-data` on **D:** | Varies |

Do **not** set Docker Desktop **Disk image location** to `D:\Docker` unless C: is critically low. A custom location plus deleted images leaves a **bloated `.vhdx`** that does not shrink by itself.

**Safe cleanup** (keeps required containers running; photos/DB are bind mounts):

```powershell
# Only remove stopped/orphan containers — NOT the immich_* stack
docker container prune -f

# Only dangling (untagged) image layers — does not remove images in use by the stack
docker image prune -f
```

**Never** run `docker compose down`, `docker system prune -a`, or `docker image prune -a` unless you intend to tear down the stack and re-pull all images.

**If `docker_data.vhdx` on C: grows huge** after many pulls/upgrades: quit Docker Desktop, run `wsl --shutdown`, then compact (Admin PowerShell):

```powershell
Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx" -Mode Full
```

Or reset the engine disk (re-pull images only; `./library` and `./data` stay):

```powershell
# Quit Docker Desktop first, then:
wsl --shutdown
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Docker\wsl"
# Start Docker Desktop, then: docker compose pull && docker compose up -d
```
