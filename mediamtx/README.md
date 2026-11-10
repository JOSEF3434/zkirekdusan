# Zikre Kedusan — Web Live Studio: MediaMTX Deployment Guide

## Critical Render Hosting Warning

**Do NOT deploy MediaMTX on a Render Web Service for WebRTC/WHIP.**
Render Web Services only route inbound HTTP/HTTPS (`80`/`443`) to a single container port (`:8889`), block custom API ports like `:9997` externally, and drop all WebRTC UDP ICE packets (`8189/udp`) plus raw TCP ICE (`8189/tcp`).
Keep the **NestJS backend on Render**, and deploy **MediaMTX on a Docker-capable VPS** (DigitalOcean, Hetzner, AWS EC2, etc.).

## Architecture

```text
Browser (Flutter Web)
  └── flutter_webrtc getUserMedia → RTCPeerConnection
      └── WHIP POST (HTTPS :443 → :8889) + WebRTC ICE (:8189/udp,tcp) → MediaMTX (VPS)
          └── FFmpeg (-rtsp_transport tcp → libx264 + aac → FLV) → Cloudinary RTMP
              └── HLS (.m3u8) → Mobile & Web Viewers
```

## Prerequisites

- A Linux VPS with Docker + Docker Compose installed (e.g., DigitalOcean, Hetzner, EC2)
- Open public firewall ports: `443/tcp` (Caddy/Nginx HTTPS), `8189/udp`, `8189/tcp` (WebRTC ICE media), plus internal/restricted `:9997` (or HTTPS `/v3/*` basic-auth reverse proxy for `MEDIAMTX_API_URL`)
- DNS A record pointed at the VPS public IP (e.g., `mtx.zikrekidusan.com`)

## Step 1: Deploy MediaMTX on VPS

```bash
cd zkirekdusan/mediamtx
export MTX_WEBRTCADDITIONALHOSTS=<YOUR_VPS_PUBLIC_IP_OR_DOMAIN>
docker compose up -d
```

Verify MediaMTX is running:
```bash
curl http://localhost:9997/v3/config/global/get
```

## Step 2: Configure Render NestJS Backend Environment

Set on Render (and `backend/.env` for local dev):
```env
WHIP_GATEWAY_URL=https://mtx.zikrekidusan.com
MEDIAMTX_API_URL=https://mtx-api.zikrekidusan.com   # or https://mtx.zikrekidusan.com proxying /v3/ with Basic Auth
MEDIAMTX_API_USER=<optional-basic-auth-user>
MEDIAMTX_API_PASSWORD=<optional-basic-auth-pass>
```

Redeploy the NestJS backend on Render.

## Step 3: Reverse Proxy (Nginx / Caddy) on VPS

Proxy public HTTPS traffic on `mtx.zikrekidusan.com` to MediaMTX:
- `https://mtx.zikrekidusan.com/*/whip` → `http://127.0.0.1:8889` (with CORS headers for your Flutter Web origin)
- `https://mtx-api.zikrekidusan.com` (or IP-restricted `:9997`) → `http://127.0.0.1:9997`

Example Nginx snippet for WHIP:
```nginx
location / {
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'POST, PATCH, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, If-Match' always;
        add_header 'Access-Control-Max-Age' 86400;
        return 204;
    }
    proxy_pass http://127.0.0.1:8889;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

## Step 4: TURN Server (Production NAT Traversal)

For users behind symmetric NAT / strict mobile carrier firewalls, add TURN credentials to `mediamtx/mediamtx.yml` (`webrtcICEServers2`) and optionally build Flutter Web with `--dart-define=WEBRTC_TURN_URL=... --dart-define=WEBRTC_TURN_USERNAME=... --dart-define=WEBRTC_TURN_CREDENTIAL=...`.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `DNS_ERROR` / timeout reaching `WHIP_GATEWAY_URL` | Missing DNS record for `mtx.zikrekidusan.com` | Point A record to VPS IP & enable TLS proxy |
| `MEDIAMTX_API_URL ... :9997` timeout on Render | Render blocks custom ports like `:9997` | Move MediaMTX to VPS; proxy Control API over HTTPS or restrict IP |
| ICE stuck in `checking` / `failed` | `8189/udp` & `8189/tcp` blocked or `MTX_WEBRTCADDITIONALHOSTS` unset | Open `8189/udp+tcp`, set VPS public IP, configure TURN |
| No video in Cloudinary from Chrome VP8 | `-c:v copy` pushed VP8 to FLV | Fixed: backend uses `libx264` + `aac` by default |
