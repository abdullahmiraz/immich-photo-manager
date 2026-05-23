# Project state (continuity for humans & agents)

Last updated: 2026-05-20

## Current stack (intended)

| Container | Image | Role |
|-----------|-------|------|
| immich_server | `ghcr.io/immich-app/immich-server:release` | Web UI, API, workers |
| immich_machine_learning | `immich-machine-learning:release` | CPU ML (OpenVINO/GPU not used on Windows) |
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

## Resolved issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Job settings greyed out in UI | `immich.json` mounted OR `system-config` in Postgres | Remove mount; `DELETE FROM system_metadata WHERE key='system-config'` |
| Containers "unhealthy", app works | Custom healthcheck `curl localhost:3001` | Use `healthcheck: disable: false` |
| Deduper pull denied | Wrong registry `ghcr.io/razgrizhsu/...` | Use `razgrizhsu/immich-deduper` on Docker Hub |
| Deduper crash on start | Missing `QDRANT_URL` | `QDRANT_URL=http://qdrant:6333` in `.env` |
| Duplicates page freezes | ML marked unhealthy under load | Lower ML threads; no config-file job locks |

## GPU (experimental, 2026-05-23)

- **AMD RX 580** on Windows: `docker-compose.gpu.yml` + `hwaccel.ml.yml` (`rocm-wsl`), `scripts/enable-wsl-gpu.ps1`, `scripts/start-gpu-stack.ps1`
- WSL after `modprobe`: `/dev/dri` + `/dev/dxg` present; **no** `/dev/kfd` (use dxg path, not native Linux ROCm)
- **Polaris / gfx803** may need `HSA_OVERRIDE_GFX_VERSION` in `.env`; not officially supported — verify ML logs for GPU provider
- Fallback: `docker compose up -d --force-recreate immich-machine-learning` (CPU `release` image)

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
