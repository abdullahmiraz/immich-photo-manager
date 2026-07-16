# Cloudflare Tunnel — troubleshooting (Windows)

Quick fixes for **Error 1033**, **530**, **INACTIVE** connectors, and **degraded** tunnel status on this stack.

See also **[REMOTE_ACCESS.md](REMOTE_ACCESS.md)** for setup.

## What works on this PC (last-known-good)

| Piece | Setting |
|-------|---------|
| Connector | Docker `immich_cloudflared` (`COMPOSE_PROFILES=optimizer,cloudflare`) |
| Protocol | **`--protocol http2`** in `docker-compose.cloudflare.yml` |
| Dashboard route | `photos.miraz.dev` → **`http://immich-upload-optimizer:2283`** |
| Windows service | **`Cloudflared` disabled** — one connector only |
| Happ VPN | Disable **`happ-tun`** adapter if VPN app is closed (see below) |

Success in logs:

```text
Registered tunnel connection
Updated to new configuration ... "hostname":"photos.miraz.dev","service":"http://immich-upload-optimizer:2283"
```

## Error 1033 / INACTIVE / no Connectors

Cloudflare has **no live connector** for your tunnel. Immich can work on `http://127.0.0.1:2283` while the dashboard shows **INACTIVE**.

### 1. Happ VPN TUN adapter (common on this PC)

Closing Happ does **not** remove the TUN adapter. If `happ-tun` is **Up** with a default route, Cloudflare HTTPS from Docker **times out** (Google may still work).

```powershell
Get-NetAdapter | Where-Object Name -like '*tun*' | Select-Object Name,Status
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object InterfaceAlias,RouteMetric
```

Fix (Admin PowerShell):

```powershell
Disable-NetAdapter -Name "happ-tun" -Confirm:$false
```

Then:

```powershell
cd path\to\immich
docker compose --profile cloudflare up -d --force-recreate cloudflared
docker compose logs cloudflared --tail 40
```

### 2. Only one connector

- Disable Windows service: `sc config Cloudflared start= disabled`
- Kill stray processes: `Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force`
- Do not run `docker run cloudflared ...` while `immich_cloudflared` is up

### 3. Wrong dashboard tab

Use **Published application routes**, not **Hostname routes (Beta)**.

| Public hostname | Service (Docker connector) |
|-----------------|---------------------------|
| `photos.miraz.dev` | `http://immich-upload-optimizer:2283` |

For **host** `cloudflared` (fallback): `http://127.0.0.1:2283`

### 4. See live errors

```powershell
docker compose logs cloudflared --tail 80
```

| Log line | Meaning |
|----------|---------|
| `TLS handshake ... EOF` | Outbound 7844 blocked (firewall, VPN, ISP) |
| `control stream encountered a failure` | Often VPN TUN or competing connectors |
| `context deadline exceeded` | Edge registration timeout; refresh tunnel token |
| `Registered tunnel connection` | Fixed |

## After Google login: 1033 or blank page

Access works; tunnel origin is wrong or connector is down.

1. Confirm connector **Healthy** in Zero Trust → Tunnels → Connectors.
2. Route for Docker: **`http://immich-upload-optimizer:2283`** (not `127.0.0.1`).
3. Local check: `http://127.0.0.1:2283/api/server/ping` → `{"res":"pong"}`.
4. Immich Admin → **Server URL** = `https://photos.miraz.dev`.
5. Recreate server after `.env` proxy changes:

```powershell
docker compose up -d --force-recreate immich-server
```

**Bypass test:** Access → Applications → temporary **Bypass** for your email. If Immich loads, fix route or connector only.

## How to tell it is fixed

| Check | Good | Bad |
|-------|------|-----|
| https://photos.miraz.dev | Google / Access login | Error 1033 |
| After Access login | Immich login | 530 / blank |
| http://127.0.0.1:2283 | `{"res":"pong"}` | Connection refused |
| `docker compose logs cloudflared` | `Registered tunnel connection` | Repeated EOF / control stream errors |
| Tunnel overview | **Healthy**, 1+ connector | INACTIVE / degraded |

**302 to `mirazdev.cloudflareaccess.com`** = DNS + Access OK; still need a healthy connector for Immich after login.

## Windows host fallback

If Docker connector cannot register after disabling `happ-tun`:

```powershell
winget install Cloudflare.cloudflared
cd path\to\immich
.\scripts\run-cloudflared-windows.ps1
```

Dashboard route for host connector: **`http://127.0.0.1:2283`**. Stop Docker `cloudflared` first.

Admin firewall (if needed):

```powershell
$cf = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
New-NetFirewallRule -DisplayName "cloudflared QUIC 7844" -Direction Outbound -Program $cf -Action Allow -Protocol UDP -RemotePort 7844 -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "cloudflared TCP 7844"  -Direction Outbound -Program $cf -Action Allow -Protocol TCP  -RemotePort 7844 -ErrorAction SilentlyContinue
```

## Security

Never commit `.env` or paste tunnel tokens in chat. **Refresh token** in Zero Trust if exposed, update `.env`, recreate `cloudflared`.
