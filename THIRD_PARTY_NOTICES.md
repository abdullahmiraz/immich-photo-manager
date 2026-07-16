# Third-party notices

**Immich Photo Manager** is a community Docker Compose distribution. It is **not** affiliated with, endorsed by, or maintained by the Immich project (immich.app).

This repository contains orchestration files (Compose, env templates, scripts) licensed under the [MIT License](LICENSE). The applications below are separate projects with their own licenses.

## Container images (pulled at runtime)

| Component | Image / source | License | Project |
|-----------|----------------|---------|---------|
| Immich server | `ghcr.io/immich-app/immich-server` | AGPL-3.0 | https://github.com/immich-app/immich |
| Immich ML | `ghcr.io/immich-app/immich-machine-learning` | AGPL-3.0 | https://github.com/immich-app/immich |
| PostgreSQL (Immich) | `ghcr.io/immich-app/postgres` | See Immich repo | https://github.com/immich-app/immich |
| Valkey (Redis) | `docker.io/valkey/valkey` | BSD-3-Clause | https://github.com/valkey-io/valkey |
| immich-deduper | `razgrizhsu/immich-deduper` (Docker Hub) | See upstream | https://github.com/RazgrizHsu/immich-deduper |
| Qdrant | `qdrant/qdrant` | Apache-2.0 | https://github.com/qdrant/qdrant |
| Upload optimizer (base) | `ghcr.io/miguelangel-nubla/immich-upload-optimizer` | See upstream | https://github.com/miguelangel-nubla/immich-upload-optimizer |
| Upload optimizer (patched) | `abdullahmiraz/immich-upload-optimizer-patched` or local build | Patch: MIT (this repo); base: upstream | [`optimizer/Dockerfile`](optimizer/Dockerfile) |

## Optional companion tools (manual download)

| Tool | Distribution | License | Project |
|------|--------------|---------|---------|
| immich-go | GitHub release binary | AGPL-3.0 | https://github.com/simulot/immich-go |
| HandBrake CLI | User download from handbrake.fr | GPLv2 | https://handbrake.fr/ |

When you redistribute or use AGPL software, comply with the respective license (including source availability requirements for network use of modified AGPL programs).

## Trademarks

“Immich” is a trademark of its respective owners. This project name describes compatibility with Immich, not official status.
