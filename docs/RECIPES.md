# Recipes

Copy-paste playbooks for common situations. All commands assume project root:

```powershell
cd "D:\code\duplicate image remover\immich"
```

| Recipe | When |
|--------|------|
| [First-time setup](#first-time-setup) | New install |
| [Start / stop / status](#start--stop--status) | Daily use |
| [Port 2283 blocked (Windows)](#port-2283-blocked-windows) | `immich_server` Created; bind forbidden on :2283 |
| [Verify health](#verify-health) | After start or changes |
| [Recreate after `.env` change](#recreate-after-env-change) | Edited `.env` |
| [Before heavy Immich jobs](#before-heavy-immich-jobs) | Storage migration, large scans |
| [immich-go bulk upload](#immich-go-bulk-upload) | Import from disk |
| [Upload optimizer stability](#upload-optimizer-stability) | Before batch uploads with optimizer on |
| [Enable upload optimizer](#enable-upload-optimizer) | Re-enable after disable |
| [Disable upload optimizer](#disable-upload-optimizer) | Direct server on :2283, no compression |
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

## Port 2283 blocked (Windows)

**Symptom:** `docker compose up` succeeds for postgres/redis/ML but `immich_server` stays `Created` or fails with:

`listen tcp 0.0.0.0:2283: bind: ... forbidden by its access permissions`

**Cause:** Windows reserved TCP range includes 2283 (check: `netsh interface ipv4 show excludedportrange protocol=tcp` — look for `2280`–`2379`).

**Fix (keep host port 2283):** Run **elevated** PowerShell (Approve UAC), then:

```powershell
cd "D:\code\duplicate image remover\immich"
net stop winnat
docker compose up -d immich-server
net start winnat
Invoke-RestMethod http://localhost:2283/api/server/ping
```

If `immich_server` was recreated on another host port earlier, `docker compose up -d immich-server` restores `IMMICH_HOST_PORT=2283` from `.env`.

**After reboot:** The exclusion may return. Repeat the elevated block above before starting Immich, or apply a one-time wider dynamic port range (admin, then reboot):

```powershell
netsh int ipv4 set dynamicport tcp start=49152 num=16384
netsh int ipv6 set dynamicport udp start=49152 num=16384
net stop winnat
net start winnat
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

Uploads go through the optimizer on **2283** when `COMPOSE_PROFILES=optimizer` (default in `.env.example`). For direct server only, see [Disable upload optimizer](#disable-upload-optimizer).

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

## Upload optimizer stability

Use before uploading **5+ files at once** (images + videos) with the optimizer on.

**1. Optional — reduce contention:**

```powershell
docker compose stop immich-deduper
```

**2. Cap Immich job concurrency** — Administration → **Settings** → **Job Settings**, use `setup/safe-job-settings.json` (especially `thumbnailGeneration` 2, `smartSearch` 2).

**3. Config in use:** `optimizer-config/tasks.yaml` — **Caesium** q=85 for JPEG/PNG/WebP/GIF/TIFF; **videos passthrough** (no HandBrake). Uppercase extensions (`MP4`, `MOV`, …) are listed for phone filenames.

**4. Patched optimizer image** (`optimizer/Dockerfile`) — disables IUO’s redirect wait page so the Immich web UI gets a direct upload response (avoids `redirect was not followed` / `unexpected EOF` on parallel uploads). Rebuild after pull: `docker compose build immich-upload-optimizer`.

**5. Duplicate / “clone” images in the same batch** — Caesium produces the same bytes for the same source photo, so Immich may log `duplicate key value violates unique constraint "UQ_assets_owner_checksum"` for a file already in the library (or uploaded earlier in the batch). That single item is skipped; **other files should still upload** once the patched optimizer is running. If the UI still aborts the whole batch, upload in smaller groups (e.g. 2–3 at a time) or remove the earlier copy from Immich first.

**6. After uploads:** `docker compose start immich-deduper` if stopped.

If :2283 bind fails on Windows, see [Port 2283 blocked (Windows)](#port-2283-blocked-windows).

**Test video passthrough (optional):**

```powershell
curl -sS -o NUL -w "http_code:%{http_code}\n" -X POST "http://localhost:2283/api/assets" `
  -H "Accept: application/json" `
  -F "assetData=@library\library\admin\2026\05\VID_20260516_233658548.mp4"
docker compose logs immich-upload-optimizer --tail 20
```

Expect log line `file NOT replaced` for the `.mp4` (passthrough). A `401` without an API key is normal; the optimizer still processed the file.

---

## Enable upload optimizer

Caesium compression via `immich-upload-optimizer` (`optimizer-config/tasks.yaml`). **Only one service can bind host :2283.**

Repo default: `immich-server` host `ports:` commented out; `COMPOSE_PROFILES=optimizer` in `.env`.

**1. In `.env`:**

```env
COMPOSE_PROFILES=optimizer
IUO_VERSION=v0.5.3
IUO_CPUS=2
```

**2. Ensure** `immich-server` `ports:` are commented in `docker-compose.yml` (committed default).

**3. Build patched optimizer and recreate stack:**

```powershell
docker compose build immich-upload-optimizer
docker compose pull
docker compose up -d --force-recreate
docker compose ps
Invoke-RestMethod http://localhost:2283/api/server/ping
```

**4. Verify:** http://localhost:2283 — uploads hit optimizer → server. Logs: `docker compose logs immich-upload-optimizer --tail 50`.

---

## Disable upload optimizer

**1. In `.env`:** remove or comment `COMPOSE_PROFILES=optimizer`.

**2. Restore** `immich-server` `ports:` in `docker-compose.yml`:

```yaml
    ports:
      - "${IMMICH_HOST_PORT:-2283}:2283"
```

**3. Recreate:**

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

With `COMPOSE_PROFILES=optimizer`: `immich_upload_optimizer` (required for :2283 UI).

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
