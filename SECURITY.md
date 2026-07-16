# Security policy

## Supported versions

Security fixes apply to the **latest release** on the [main branch](https://github.com/abdullahmiraz/immich-photo-manager). Older tagged commits are not backported unless noted in a release.

## Reporting a vulnerability

**Do not** open public GitHub issues for undisclosed security problems.

Email or DM the maintainer via GitHub: [@abdullahmiraz](https://github.com/abdullahmiraz) with:

- Description and impact
- Steps to reproduce
- Affected version (tag or commit)

We aim to acknowledge within 7 days.

## Operator security (default install)

| Topic | Guidance |
|-------|----------|
| Database password | Generate a random `DB_PASSWORD` / `PSQL_PASS` with `scripts/generate-env.ps1`, or set your own in `.env`. Change + recreate only if you understand Postgres implications. |
| `.env` | Never commit `.env`. Treat API keys like passwords. |
| Postgres | **Do not** publish port 5432 to the internet. This stack keeps DB on the Docker network only. |
| Remote access | Use Immich authentication plus HTTPS (reverse proxy: Caddy, NPM, Traefik). Do not expose Immich without TLS on WAN. |
| Updates | Use `docker compose pull && docker compose up -d` only. Avoid `docker compose down` and `docker system prune -a` on this stack (data loss risk). See [docs/RECIPES.md](docs/RECIPES.md). |
| immich-go | Store API keys outside the repo. Rotate keys in Immich → Account Settings → API Keys. |
| Removal | Photos remain under `library/` until you delete them yourself — there is no automated uninstaller. |

## Supply chain

- Image digests are already pinned in `docker-compose.yml`/`docker-compose.deduper.yml` for `postgres`, `redis`, and `qdrant`. `immich-server`/`immich-machine-learning` track the `release` tag; pin `IMMICH_VERSION` to a specific version in `.env` for full reproducibility.
- Build the patched upload optimizer from [`optimizer/Dockerfile`](optimizer/Dockerfile) if you do not trust a pre-published image.

## Scope

This repository covers **orchestration** only. Vulnerabilities in Immich, immich-deduper, or other upstream apps should be reported to those projects as well.
