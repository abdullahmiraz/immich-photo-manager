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
.\immich-go.exe upload from-folder `
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
./immich-go.exe upload from-folder \
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

## Upgrade Immich

```powershell
docker compose pull
docker compose up -d
```

Pin version in `.env`: `IMMICH_VERSION=v2` (or `release`).

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
