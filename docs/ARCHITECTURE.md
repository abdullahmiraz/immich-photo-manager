# Architecture

## Overview

```mermaid
flowchart TB
  subgraph host [Windows host]
    Browser[Browser]
    Library[(library/)]
    DedupData[(dedup-data/)]
  end

  subgraph compose [docker compose project: immich]
    subgraph default_net [network: default]
      Server[immich_server :2283]
      ML[immich_machine_learning]
      Redis[immich_redis]
      DB[(immich_postgres)]
    end
    subgraph dedup_net [network: immich-deduper]
      Deduper[immich_deduper :8086]
      Qdrant[immich_deduper_qdrant]
      DB
    end
    subgraph optional [profile: optimizer — optional]
      Optimizer[immich_upload_optimizer :2283]
    end
  end

  Browser --> Server
  Browser --> Deduper
  Optimizer -.->|when enabled| Server
  Server --> Redis
  Server --> ML
  Server --> DB
  Deduper --> Qdrant
  Deduper --> DB
  Server --> Library
  Deduper --> Library
  Deduper --> DedupData
```

## Compose modules (reusable)

Root `docker-compose.yml` only `include`s modules — like composing UI from building blocks:

| Module | File | When loaded |
|--------|------|-------------|
| **Base** | `docker-compose.yml` | Always — server, ML, Redis, Postgres |
| **Deduper** | `docker-compose.deduper.yml` | Included by default |
| **Upload optimizer** | `docker-compose.optimizer.yml` | `--profile optimizer` |

Add-ons sit next to `docker-compose.yml` so `.env` paths (`./library`, `./dedup-data`) resolve correctly.

## Service dependencies

```
redis ──┐
        ├──► immich-server (after healthy)
database ─┘

qdrant ──► immich-deduper
database ──► immich-deduper (after healthy)
```

## Volume mounts

| Service | Host | Container | Mode |
|---------|------|-----------|------|
| immich-server | `${UPLOAD_LOCATION}` | `/data` | rw |
| immich-server | `${EXTERNAL_LIBRARY_PATH}` | `/photos-import` | ro |
| immich-deduper | `${UPLOAD_LOCATION}` | `/immich` | ro |
| immich-deduper | `${DEDUP_DATA}` | `/app/data` | rw |
| database | `${DB_DATA_LOCATION}` | `/var/lib/postgresql/data` | rw |
| immich-machine-learning | `${MODEL_CACHE_LOCATION}` | `/cache` | rw |
| redis | `${REDIS_DATA_LOCATION}` | `/data` | rw |

## Two duplicate workflows

| Tool | URL | Mechanism |
|------|-----|-----------|
| **Immich built-in** | `/utilities/duplicates` | Smart search / CLIP via Immich ML |
| **immich-deduper** | http://localhost:8086 | ResNet152 + Qdrant; Postgres + files |

## Configuration source of truth

| Setting type | Where |
|--------------|--------|
| Infra (ports, images, volumes) | `compose/` + `.env` |
| Immich jobs, ffmpeg, features | **Admin UI** only |
| Deduper tuning | Deduper UI + `.env` (`PSQL_*`, `QDRANT_URL`) |
| Job caps reference | `setup/safe-job-settings.json` → apply in Admin UI |
| Historical export | `setup/immich-config.json` (not loaded) |

## ML

CPU-only: `ghcr.io/immich-app/immich-machine-learning:release`. No GPU/ROCm on this stack.
