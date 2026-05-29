# Remote access (Cloudflare Tunnel)

Expose Immich at **https://photos.miraz.dev** (or your subdomain) without opening router ports. Uses [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (~100 MB upload limit per request through Cloudflare).

**Not exposed:** deduper (:8086), Postgres, Redis — keep them local only.

## Prerequisites

- Domain **miraz.dev** on Cloudflare
- [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) (free)
- Stack running with upload optimizer on host **:2283**

## 1. Create the tunnel (dashboard)

1. Zero Trust → **Networks** → **Tunnels** → **Create a tunnel**
2. Name: e.g. `immich-home`
3. Install connector → **Docker** → copy the **token**
4. In project `.env` (never commit):

```env
CLOUDFLARE_TUNNEL_TOKEN=your-token-here
COMPOSE_PROFILES=optimizer,cloudflare
IMMICH_SERVER_URL=https://photos.miraz.dev
```

5. **Public Hostname** (same tunnel):

| Field | Value |
|-------|--------|
| Subdomain | `photos` (→ `photos.miraz.dev`) |
| Domain | `miraz.dev` |
| Service type | HTTP |
| URL | `immich-upload-optimizer:2283` (preferred; same Docker network as `cloudflared`) |

Alternative if `cloudflared` runs on the host: `http://localhost:2283` or `host.docker.internal:2283`.

Save. DNS is created automatically for the tunnel.

## 2. Start cloudflared with the stack

From project root:

```powershell
docker compose up -d
docker compose ps
docker compose logs cloudflared --tail 30
```

`immich_cloudflared` should be **running**. Test: https://photos.miraz.dev

## 3. Immich public URL

Immich needs your external URL for links and mobile apps.

1. **Administration** → **Settings** → **Networking** (or Server URL)
2. Set: `https://photos.miraz.dev` (match `IMMICH_SERVER_URL` in `.env`)

Recreate server if you changed `.env` proxy settings:

```powershell
docker compose up -d --force-recreate immich-server
```

## 4. Lock down access (recommended)

Zero Trust → **Access** → **Applications** → add **Self-hosted** app:

- Domain: `photos.miraz.dev`
- Policy: Allow → your email → One-time PIN

Visitors must pass Cloudflare Access, then Immich login.

## 5. Upload limit (100 MB)

Large phone videos may fail over the tunnel. Options:

- Upload on home Wi‑Fi using `http://<PC-LAN-IP>:2283`
- Use a VPN (e.g. Tailscale) for backup, tunnel for viewing only

## Disable tunnel

Remove `cloudflare` from `COMPOSE_PROFILES` and recreate:

```powershell
# COMPOSE_PROFILES=optimizer
docker compose up -d --force-recreate
```

## Troubleshooting

### Tunnel INACTIVE in Cloudflare dashboard

Logs like `QUIC connection failed`, `HTTP/2 connection is blocked`, or `TLS handshake with edge error: EOF` mean **outbound** traffic to Cloudflare Tunnel edges (port **7844** UDP/TCP) is blocked — Windows Firewall, antivirus, router, or ISP.

1. **Windows Firewall** → Allow **Docker Desktop** and outbound for `cloudflared`.
2. Temporarily test on a **phone hotspot** (rules out ISP blocking).
3. This repo uses **`--protocol http2`** on `cloudflared` (see `docker-compose.cloudflare.yml`); still requires reachable edge on 7844.
4. After the connector is **Healthy**, set Public Hostname service URL to **`http://immich-upload-optimizer:2283`**.

### Port 2283 on Windows

If optimizer fails to bind :2283, see [RECIPES.md → Port 2283 blocked](RECIPES.md#port-2283-blocked-windows) (`net stop winnat` elevated, then `compose up`).

| Symptom | Fix |
|---------|-----|
| 502 / connection refused | Stack up? Optimizer on :2283? Hostname URL = `immich-upload-optimizer:2283` |
| Login loops / wrong links | Set public URL in Immich Admin; `IMMICH_SERVER_URL` matches |
| Upload fails for big files | Cloudflare 100 MB limit — use LAN/VPN for backup |
| `cloudflared` exits immediately | Check `CLOUDFLARE_TUNNEL_TOKEN` in `.env` |

See also [SECURITY.md](../SECURITY.md).
