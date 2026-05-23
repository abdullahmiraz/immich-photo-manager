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
      Optimizer[immich_upload_optimizer :2283]
      Server[immich_server internal]
      ML[immich_machine_learning]
      Redis[immich_redis]
      DB[(immich_postgres)]
    end
    subgraph dedup_net [network: immich-deduper external]
      Deduper[immich_deduper :8086]
      Qdrant[immich_deduper_qdrant]
      DB
    end
  end

  Browser --> Optimizer
  Browser --> Deduper
  Optimizer --> Server
  Server --> Redis
  Server --> ML
  Server --> DB
  Deduper --> Qdrant
  Deduper --> DB
  Server --> Library
  Deduper --> Library
  Deduper --> DedupData
```

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
| database | volume `pgdata` | `/var/lib/postgresql/data` | rw |

## Two duplicate workflows

| Tool | URL | Mechanism |
|------|-----|-----------|
| **Immich built-in** | `/utilities/duplicates` | Smart search / CLIP embeddings via Immich ML |
| **immich-deduper** | http://localhost:8086 | ResNet152 + Qdrant; direct Postgres + file access |

Both can coexist; deduper is heavier but often better for large visual similarity sets.

## Configuration source of truth

| Setting type | Where |
|--------------|--------|
| Infra (ports, images, volumes) | `docker-compose.yml` + `.env` |
| Immich jobs, ffmpeg, features | **Immich Admin UI** only |
| Deduper tuning | Deduper UI + `.env` (`PSQL_*`, `QDRANT_URL`) |
| Historical Immich export | `setup/immich-config.json` (not loaded) |
