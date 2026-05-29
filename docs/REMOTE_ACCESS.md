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

## 2. Start cloudflared

### Recommended: Docker Compose (reads token from `.env`)

Do **not** paste the literal text `CLOUDFLARE_TUNNEL_TOKEN` as the token — use the long JWT from the Cloudflare dashboard in `.env`:

```env
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...paste-real-token-here...
COMPOSE_PROFILES=optimizer,cloudflare
```

From project root:

```powershell
docker compose --profile optimizer --profile cloudflare up -d
docker compose logs cloudflared --tail 30
```

Look for **`Registered tunnel connection`** and **`Updated to new configuration`**. If you see repeated `control stream` / `TLS handshake EOF` errors, see **[CLOUDFLARE-FIX.md](CLOUDFLARE-FIX.md)** (Happ VPN `happ-tun` adapter is the usual cause on this PC).

### One-off `docker run` (equivalent)

Cloudflare’s docs show:

```text
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token <YOUR_TOKEN>
```

Replace `<YOUR_TOKEN>` with the value from `.env`, and attach the **Immich network** so `immich-upload-optimizer:2283` resolves:

```powershell
cd path\to\immich-photo-manager
$token = (Get-Content .env | Where-Object { $_ -match '^CLOUDFLARE_TUNNEL_TOKEN=' }) -replace '^CLOUDFLARE_TUNNEL_TOKEN=',''

docker run --rm --network immich_default `
  cloudflare/cloudflared:latest `
  tunnel --no-autoupdate --protocol http2 run --token $token
```

Stop the compose `cloudflared` first to avoid two connectors fighting:

```powershell
docker compose --profile cloudflare stop cloudflared
```

### Fallback: Windows host connector

Use only if Docker `immich_cloudflared` still cannot register after [CLOUDFLARE-FIX.md](CLOUDFLARE-FIX.md) (Happ `happ-tun` off, one connector, fresh token). Host path works when Windows can reach port 7844 but Docker cannot:

```powershell
winget install Cloudflare.cloudflared
cd path\to\immich-photo-manager
.\scripts\run-cloudflared-windows.ps1
```

Set the dashboard route to **`http://localhost:2283`** (host install) instead of `immich-upload-optimizer:2283`.

`immich_cloudflared` should be **running** (or host `cloudflared`). Test: https://photos.miraz.dev

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

### Google login works, then Error 1033 or blank page again

Access succeeded; the tunnel connector is down or the origin URL is wrong.

1. **Zero Trust → Networks → Tunnels → your tunnel → Connectors** — must show **Connected**.
2. **Published application routes** → `photos.miraz.dev` → **`http://immich-upload-optimizer:2283`** (Docker connector).
3. Confirm local: `http://127.0.0.1:2283/api/server/ping` → `{"res":"pong"}`.
4. If Happ VPN was used: disable **`happ-tun`** adapter (see [CLOUDFLARE-FIX.md](CLOUDFLARE-FIX.md)).
5. Immich Admin → **Server URL** = `https://photos.miraz.dev`; recreate `immich-server` if you changed `.env`.

See `docs/CLOUDFLARE-FIX.md` for the full checklist.

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

### Tunnel INACTIVE or degraded in Cloudflare dashboard

1. **Happ VPN:** if `happ-tun` adapter is **Up** after closing VPN, disable it (Admin): `Disable-NetAdapter -Name "happ-tun" -Confirm:$false`. See [CLOUDFLARE-FIX.md](CLOUDFLARE-FIX.md).
2. **One connector only:** disable Windows `Cloudflared` service; kill stray `cloudflared.exe` processes.
3. Recreate Docker connector: `docker compose --profile cloudflare up -d --force-recreate cloudflared`.
4. Logs should show **`Registered tunnel connection`**. Route: **`http://immich-upload-optimizer:2283`**.

Legacy: outbound **7844** blocked by firewall/ISP — allow Docker Desktop or use host `.\scripts\run-cloudflared-windows.ps1` with route **`http://127.0.0.1:2283`**.

### Port 2283 on Windows

If optimizer fails to bind :2283, see [RECIPES.md → Port 2283 blocked](RECIPES.md#port-2283-blocked-windows) (`net stop winnat` elevated, then `compose up`).

| Symptom | Fix |
|---------|-----|
| 502 / connection refused | Stack up? Optimizer on :2283? Hostname URL = `immich-upload-optimizer:2283` |
| Login loops / wrong links | Set public URL in Immich Admin; `IMMICH_SERVER_URL` matches |
| Upload fails for big files | Cloudflare 100 MB limit — use LAN/VPN for backup |
| `cloudflared` exits immediately | Check `CLOUDFLARE_TUNNEL_TOKEN` in `.env` |

See also [SECURITY.md](../SECURITY.md).
