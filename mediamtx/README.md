# Zikre Kedusan — Web Live Studio: MediaMTX Deployment Guide

## Architecture

`
Browser (Flutter Web)
  └── flutter_webrtc getUserMedia → RTCPeerConnection
      └── WHIP POST → MediaMTX (port 8889)
          └── ffmpeg → Cloudinary RTMP (rtmp://live.cloudinary.com/streams)
              └── HLS → Viewers
`

## Prerequisites

- A server / VPS with Docker installed (e.g., DigitalOcean, Hetzner, EC2)
- Publicly accessible ports: 8889/tcp, 8889/udp, 9997/tcp
- Domain pointed at the server (e.g., mtx.zikrekidusan.com) — or use IP
- HTTPS recommended (use Caddy or nginx reverse proxy for TLS)

## Step 1: Deploy MediaMTX

`ash
# On your server:
git clone https://github.com/YOURORG/zkirekdusan  # or copy the mediamtx/ folder
cd zkirekdusan/mediamtx

docker compose up -d
`

Verify MediaMTX is running:
`ash
curl http://localhost:9997/v3/config/global/get
`

## Step 2: Configure Backend

Add to ackend/.env:
`
WHIP_GATEWAY_URL=https://mtx.zikrekidusan.com
`

Redeploy/restart the NestJS backend.

## Step 3: CORS on MediaMTX (Production)

MediaMTX 1.8+ supports CORS headers via nginx proxy.
For the WHIP endpoint, the browser sends a preflight OPTIONS request.
Configure nginx:

`
ginx
location /whip {
    add_header 'Access-Control-Allow-Origin' 'https://app.zikrekidusan.com' always;
    add_header 'Access-Control-Allow-Methods' 'POST, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
    if ( = 'OPTIONS') {
        return 204;
    }
    proxy_pass http://127.0.0.1:8889;
}
`

## Step 4: TURN Server (Production NAT Traversal)

For users behind NAT/firewalls, WebRTC needs TURN.
Recommended: Coturn (free) or Metered.ca TURN (free tier).

Add to mediamtx/mediamtx.yml:
`yaml
webrtcICEServers2:
  - url: stun:stun.l.google.com:19302
  - url: turn:your-turn-host:3478
    username: your-username
    password: your-password
`

## Step 5: Verify End-to-End

1. Open Zikre Kedusan web app in Chrome
2. Navigate to Live Studio → Create Stream → Go Live
3. Watch browser console:
   - [WHIP] state → acquiringMedia
   - [WHIP] Media acquired: video=1 audio=1
   - [WHIP] state → connecting
   - [WHIP] POSTing SDP offer to https://mtx.../whip
   - [WHIP] ✓ WHIP session established
   - [WHIP] state → connected
4. Check MediaMTX logs: docker logs zikrekidusan-mediamtx
5. Cloudinary dashboard should show an active live stream

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| CORS error on WHIP POST | Missing CORS headers | Configure nginx proxy |
| ICE failed | NAT traversal blocked | Add TURN server |
| WHIP 404 | Wrong endpoint URL | Check WHIP_GATEWAY_URL in backend .env |
| No video in Cloudinary | ffmpeg not finding stream | Check MediaMTX logs for runOnReady errors |
| HTTP 400 from WHIP | SDP format issue | Update flutter_webrtc package |