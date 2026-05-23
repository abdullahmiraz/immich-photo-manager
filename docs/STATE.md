# Project state (continuity for humans & agents)

Last updated: 2026-05-23

## Current stack (intended)

| Container | Image | Role |
|-----------|-------|------|
| immich_upload_optimizer | `miguelangel-nubla/immich-upload-optimizer:latest` | Upload proxy :2283; Caesium lossy q=80 + EXIF |
| immich_server | `ghcr.io/immich-app/immich-server:release` | Web UI, API (internal; no host port) |
| immich_machine_learning | `immich-machine-learning:release-rocm` | GPU-first; auto CPU fallback on WSL until HIP works |
| immich_postgres | `ghcr.io/immich-app/postgres:14-vectorchord...` | DB; on `default` + `immich-deduper` networks |
| immich_redis | valkey:9 | Job queue (persistent volume `redisdata`) |
| immich_deduper | `razgrizhsu/immich-deduper:latest` | Duplicate finder UI :8086 |
| immich_deduper_qdrant | qdrant:v1.16.3 | Deduper vector store |

## Decisions (do not revert without reason)

1. **No config file at runtime** — UI controls jobs/ffmpeg/ML. `setup/immich-config.json` is backup only.
2. **immich-deduper** integrated per [same-host guide](https://github.com/RazgrizHsu/immich-deduper/tree/main/docker/same-host), not API-key sidecar.
3. **ML threads capped at 8** — full 24 threads caused `Machine learning server became unhealthy` and duplicates UI freeze.
4. **Redis AOF + RDB** — job queue survives restarts.
5. **External library** host path → container `/photos-import` (read-only).
6. **Upload optimizer** — `optimizer-config/tasks.yaml`: Caesium `--quality=80 --exif --keep-dates` for JPEG/PNG/WebP/GIF/TIFF; HEIC/RAW/video passthrough unchanged.
7. **Deduper network** — Compose creates `immich-deduper` automatically (not external).

## Resolved issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Job settings greyed out in UI | `immich.json` mounted OR `system-config` in Postgres | Remove mount; `DELETE FROM system_metadata WHERE key='system-config'` |
| Containers "unhealthy", app works | Custom healthcheck `curl localhost:3001` | Use `healthcheck: disable: false` |
| Deduper pull denied | Wrong registry `ghcr.io/razgrizhsu/...` | Use `razgrizhsu/immich-deduper` on Docker Hub |
| Deduper crash on start | Missing `QDRANT_URL` | `QDRANT_URL=http://qdrant:6333` in `.env` |
| ML `fetch failed` / OCR jobs fail | `IMMICH_PORT=2283` in shared `.env` makes ML listen on wrong port | Remove `IMMICH_PORT` from `.env`; compose sets server=2283, ML=3003 |

## GPU (RX 580 — GPU-first, CPU fallback on WSL)

- **Compose:** `release-rocm` + `/dev/dxg` + `libdxcore` in `docker-compose.yml`
- **Today on Windows WSL:** HIP often reports `no ROCm-capable device` → ONNX **`Falling back to ['CPUExecutionProvider']`** (high CPU, flat GPU is expected until Immich/ROCm WSL matures)
- **When GPU works:** same compose — logs will show MIGraphX without "Falling back to CPU"; GPU usage in Task Manager during face/Smart Search jobs
- **After reboot:** `.\scripts\enable-wsl-gpu.ps1` before `docker compose up -d`
- **Pure CPU only (optional):** `docker compose -f docker-compose.yml -f docker-compose.cpu.yml up -d --force-recreate immich-machine-learning` if you add a cpu overlay, or temporarily change image to `release` without GPU devices

## Data locations (gitignored)

| Path | Contents |
|------|----------|
| `./library` | Immich upload (photos, thumbs, DB backups) |
| `./dedup-data` | Deduper DB, Qdrant, torch cache |
| Docker volume `pgdata` | Postgres |
| Docker volume `redisdata` | Redis |
| Docker volume `model-cache` | ML models |

## External library

- Container path: `/photos-import`
- Host path: `./library/upload/external` (`EXTERNAL_LIBRARY_PATH`)
- Enable in Immich: Administration → External Libraries

## Disk / performance (2026-05-20)

| Issue | Mitigation |
|-------|------------|
| 100% disk during Storage Template Migration | Needs ~library-size free on D:; migration may **copy** files on Windows bind mounts |
| C: drive full | Moved `pgdata` / `redis` / `model-cache` to `./data/` bind mounts on D: |
| Deduper + Immich crash host | `heavy-job-prep.ps1` stops deduper; job concurrency via `apply-safe-job-settings.ps1` |
| ML unhealthy under load | `MACHINE_LEARNING_REQUEST_THREADS=4`, deduper `latest-cpu`, container mem/cpu limits |

Scripts: `scripts/heavy-job-prep.ps1`, `scripts/apply-safe-job-settings.ps1`, `scripts/migrate-docker-volumes-to-bind.ps1`

## Open / optional follow-ups

- [ ] Rotate `DB_PASSWORD` from default in `.env` for production
- [ ] Document immich-go upload workflow if re-added to README
- [ ] Pin image digests in compose for reproducible deploys
