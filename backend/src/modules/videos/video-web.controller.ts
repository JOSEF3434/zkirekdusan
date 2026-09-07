// src/modules/videos/video-web.controller.ts
import { Controller, Get, Param, Req, Res } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { PrismaService } from '../../prisma/prisma.service.js';
import { Public } from '../../common/decorators/public.decorator.js';

@ApiExcludeController()
@Public()
@Controller()
export class VideoWebController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('share/:id')
  async handleShareRoute(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.renderMediaPage(id, req, res);
  }

  @Get('web/:id')
  async handleWebRoute(
    @Param('id') id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    return this.renderMediaPage(id, req, res);
  }

  private async renderMediaPage(id: string, req: Request, res: Response) {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader(
      'Content-Security-Policy',
      "default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;",
    );

    const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'https';
    const host = req.get('host') || 'zikrekidusan.onrender.com';
    const fullUrl = `${protocol}://${host}${req.originalUrl}`;

    try {
      // 1. Try finding in Video model
      const video = await this.prisma.video.findUnique({
        where: { id },
        include: {
          videoChannel: {
            include: {
              avatarFile: true,
            },
          },
          uploadedBy: {
            include: {
              profile: {
                include: {
                  avatar: true,
                },
              },
            },
          },
          sourceFile: true,
          thumbnailFile: true,
        },
      });

      if (video) {
        const title = video.title || 'ዝክረ ቅዱሳን ቪዲዮ';
        const description =
          video.description ||
          'ዝክረ ቅዱሳን - ኦርቶዶክሳዊ ትምህርቶች፣ መዝሙራት እና ስብከቶች';
        const thumbnailUrl =
          video.thumbnailUrl ||
          video.thumbnailFile?.url ||
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=1200&q=80';
        
        let videoUrl = video.hlsUrl || video.sourceFile?.url || '';
        // If it's a Cloudinary video URL, ensure it can be played directly
        if (videoUrl.includes('cloudinary.com') && videoUrl.includes('/raw/upload/')) {
          videoUrl = videoUrl.replace('/raw/upload/', '/video/upload/');
        }

        const channelName =
          video.videoChannel?.name ||
          video.uploadedBy?.username ||
          'ዝክረ ቅዱሳን';
        const channelAvatar =
          video.videoChannel?.avatarFile?.url ||
          video.uploadedBy?.profile?.avatar?.url ||
          '';
        const viewsCount = video.viewsCount ? Number(video.viewsCount) : 0;
        const durationFormatted = this.formatDuration(video.duration);

        return res.send(
          this.buildHtml({
            id,
            title,
            description,
            thumbnailUrl,
            videoUrl,
            channelName,
            channelAvatar,
            viewsCount,
            duration: durationFormatted,
            fullUrl,
            isVideo: true,
          }),
        );
      }

      // 2. Try finding in Post model
      const post = await this.prisma.post.findUnique({
        where: { id },
        include: {
          author: {
            include: {
              profile: {
                include: {
                  avatar: true,
                },
              },
            },
          },
          media: {
            include: {
              file: true,
            },
          },
        },
      });

      if (post) {
        const title = post.content
          ? post.content.length > 80
            ? post.content.substring(0, 80) + '...'
            : post.content
          : 'ዝክረ ቅዱሳን መልእክት';
        const description =
          post.content || 'ዝክረ ቅዱሳን - ማኅበራዊ እና መንፈሳዊ መድረክ';

        const firstMedia = post.media?.[0]?.file;
        const isVideoMedia = firstMedia?.mimeType?.startsWith('video/');
        const mediaUrl = firstMedia?.url || '';
        const thumbnailUrl = isVideoMedia
          ? 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=1200&q=80'
          : mediaUrl;

        const authorName = post.author?.username || 'ዝክረ ቅዱሳን';
        const authorAvatar = post.author?.profile?.avatar?.url || '';

        return res.send(
          this.buildHtml({
            id,
            title,
            description,
            thumbnailUrl: thumbnailUrl || '',
            videoUrl: isVideoMedia ? mediaUrl : '',
            imageUrl: !isVideoMedia ? mediaUrl : '',
            channelName: authorName,
            channelAvatar: authorAvatar,
            viewsCount: post.viewsCount || 0,
            fullUrl,
            isVideo: isVideoMedia,
          }),
        );
      }

      // 3. Not found
      return res.status(404).send(this.buildNotFoundHtml(fullUrl));
    } catch (err) {
      return res.status(500).send(this.buildErrorHtml(err));
    }
  }

  private formatDuration(seconds?: number | null): string {
    if (!seconds || seconds <= 0) return '';
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  }

  private escapeHtml(str: string): string {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  private buildHtml(data: {
    id: string;
    title: string;
    description: string;
    thumbnailUrl: string;
    videoUrl?: string;
    imageUrl?: string;
    channelName: string;
    channelAvatar?: string;
    viewsCount?: number;
    duration?: string;
    fullUrl: string;
    isVideo?: boolean;
  }): string {
    const escapedTitle = this.escapeHtml(data.title);
    const escapedDesc = this.escapeHtml(data.description);
    const deepLink = `zkrekidusan://video/${data.id}`;

    return `<!DOCTYPE html>
<html lang="am" dir="ltr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>${escapedTitle} | ዝክረ ቅዱሳን</title>

  <!-- Open Graph / Facebook / WhatsApp / Telegram -->
  <meta property="og:type" content="${data.isVideo ? 'video.other' : 'article'}" />
  <meta property="og:url" content="${data.fullUrl}" />
  <meta property="og:title" content="${escapedTitle}" />
  <meta property="og:description" content="${escapedDesc}" />
  <meta property="og:image" content="${data.thumbnailUrl}" />
  ${data.videoUrl ? `<meta property="og:video" content="${data.videoUrl}" />` : ''}
  <meta property="og:site_name" content="ዝክረ ቅዱሳን (Zikre Kidusan)" />

  <!-- Twitter -->
  <meta name="twitter:card" content="${data.isVideo ? 'player' : 'summary_large_image'}" />
  <meta name="twitter:url" content="${data.fullUrl}" />
  <meta name="twitter:title" content="${escapedTitle}" />
  <meta name="twitter:description" content="${escapedDesc}" />
  <meta name="twitter:image" content="${data.thumbnailUrl}" />
  ${data.videoUrl ? `<meta name="twitter:player" content="${data.fullUrl}" />` : ''}

  <!-- Fonts & Hls.js -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Ethiopic:wght@400;600;700&family=Outfit:wght@400;600;700&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>

  <style>
    :root {
      --bg-primary: #0b0c10;
      --bg-surface: #171923;
      --bg-card: #202433;
      --accent-gold: #e5a93b;
      --accent-gold-hover: #c98e28;
      --text-main: #f7fafc;
      --text-muted: #a0aec0;
      --border-color: rgba(255, 255, 255, 0.08);
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      background-color: var(--bg-primary);
      color: var(--text-main);
      font-family: 'Noto Sans Ethiopic', 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    header {
      width: 100%;
      background: rgba(11, 12, 16, 0.85);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid var(--border-color);
      position: sticky;
      top: 0;
      z-index: 50;
      padding: 12px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      text-decoration: none;
      color: inherit;
    }
    .brand-icon {
      width: 36px;
      height: 36px;
      border-radius: 10px;
      background: linear-gradient(135deg, #e5a93b, #d97706);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 18px;
      color: #0b0c10;
      box-shadow: 0 4px 14px rgba(229, 169, 59, 0.3);
    }
    .brand-text h1 {
      font-size: 16px;
      font-weight: 700;
      color: var(--text-main);
      letter-spacing: -0.2px;
    }
    .brand-text p {
      font-size: 11px;
      color: var(--text-muted);
    }
    .app-btn {
      background: linear-gradient(135deg, var(--accent-gold), var(--accent-gold-hover));
      color: #0b0c10;
      font-weight: 700;
      font-size: 13px;
      padding: 8px 18px;
      border-radius: 9999px;
      text-decoration: none;
      transition: all 0.2s ease;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      box-shadow: 0 4px 12px rgba(229, 169, 59, 0.35);
    }
    .app-btn:hover {
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(229, 169, 59, 0.5);
    }
    .main-container {
      width: 100%;
      max-width: 900px;
      padding: 20px 16px 40px 16px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .player-card {
      width: 100%;
      background: #000;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
      border: 1px solid var(--border-color);
      position: relative;
    }
    video {
      width: 100%;
      max-height: 70vh;
      display: block;
      background: #000;
    }
    .image-preview {
      width: 100%;
      max-height: 70vh;
      object-fit: contain;
      display: block;
      background: #000;
    }
    .content-details {
      background: var(--bg-surface);
      border-radius: 16px;
      padding: 20px;
      border: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .title-row h2 {
      font-size: 20px;
      font-weight: 700;
      line-height: 1.4;
      color: var(--text-main);
    }
    .meta-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 12px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border-color);
    }
    .channel-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .channel-avatar {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      object-fit: cover;
      background: var(--bg-card);
      border: 2px solid var(--accent-gold);
    }
    .channel-avatar-fallback {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: linear-gradient(135deg, #3182ce, #63b3ed);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      color: #fff;
    }
    .channel-name {
      font-weight: 700;
      font-size: 15px;
      color: var(--text-main);
    }
    .channel-sub {
      font-size: 12px;
      color: var(--text-muted);
    }
    .stats-badge {
      font-size: 13px;
      color: var(--text-muted);
      background: var(--bg-card);
      padding: 6px 14px;
      border-radius: 20px;
      border: 1px solid var(--border-color);
    }
    .description-box {
      font-size: 14px;
      line-height: 1.6;
      color: #cbd5e0;
      white-space: pre-line;
      word-break: break-word;
    }
    .download-prompt {
      background: linear-gradient(135deg, rgba(229, 169, 59, 0.12), rgba(217, 119, 6, 0.05));
      border: 1px solid rgba(229, 169, 59, 0.3);
      border-radius: 14px;
      padding: 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
    }
    .download-prompt-text h3 {
      font-size: 15px;
      font-weight: 700;
      color: var(--accent-gold);
      margin-bottom: 2px;
    }
    .download-prompt-text p {
      font-size: 12px;
      color: var(--text-muted);
    }
    footer {
      margin-top: auto;
      padding: 24px;
      text-align: center;
      font-size: 12px;
      color: var(--text-muted);
      border-top: 1px solid var(--border-color);
      width: 100%;
    }
  </style>
</head>
<body>
  <header>
    <a href="/" class="brand">
      <div class="brand-icon">ዝ</div>
      <div class="brand-text">
        <h1>ዝክረ ቅዱሳን</h1>
        <p>Zikre Kidusan Platform</p>
      </div>
    </a>
    <a href="${deepLink}" class="app-btn">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M5 3v18l15-9L5 3z"/>
      </svg>
      በመተግበሪያው ክፈት / Open App
    </a>
  </header>

  <main class="main-container">
    <div class="player-card">
      ${
        data.isVideo && data.videoUrl
          ? `<video id="zikreVideoPlayer" controls playsinline preload="metadata" poster="${data.thumbnailUrl}">
               <source src="${data.videoUrl}" type="video/mp4">
               ይቅርታ፣ አሳሽዎ ቪዲዮውን መጫወት አልቻለም።
             </video>`
          : data.imageUrl
          ? `<img src="${data.imageUrl}" alt="${escapedTitle}" class="image-preview" />`
          : `<img src="${data.thumbnailUrl}" alt="${escapedTitle}" class="image-preview" />`
      }
    </div>

    <div class="content-details">
      <div class="title-row">
        <h2>${escapedTitle}</h2>
      </div>

      <div class="meta-row">
        <div class="channel-info">
          ${
            data.channelAvatar
              ? `<img src="${data.channelAvatar}" alt="${this.escapeHtml(data.channelName)}" class="channel-avatar" />`
              : `<div class="channel-avatar-fallback">${this.escapeHtml(data.channelName.substring(0, 1))}</div>`
          }
          <div>
            <div class="channel-name">${this.escapeHtml(data.channelName)}</div>
            <div class="channel-sub">የተረጋገጠ ቻናል</div>
          </div>
        </div>

        <div class="stats-badge">
          ${data.viewsCount ? `${data.viewsCount.toLocaleString()} እይታዎች • ` : ''}${data.duration ? `ርዝመት: ${data.duration}` : 'ዝክረ ቅዱሳን'}
        </div>
      </div>

      <div class="download-prompt">
        <div class="download-prompt-text">
          <h3>ያለ ኢንተርኔት (Offline) ይመልከቱ</h3>
          <p>ቪዲዮውን ወደ ስልክዎ አውርደው በማንኛውም ቦታ ያለ ዳታ ይመልከቱ።</p>
        </div>
        <a href="${deepLink}" class="app-btn">
          ቪዲዮውን አውርድ / Download
        </a>
      </div>

      ${
        data.description
          ? `<div class="description-box">${escapedDesc}</div>`
          : ''
      }
    </div>
  </main>

  <footer>
    <p>© ${new Date().getFullYear()} ዝክረ ቅዱሳን (Zikre Kidusan). All rights reserved.</p>
  </footer>

  <script>
    // Automatic HLS Support for browsers
    document.addEventListener('DOMContentLoaded', function () {
      var video = document.getElementById('zikreVideoPlayer');
      var videoUrl = "${data.videoUrl || ''}";
      
      if (video && videoUrl.includes('.m3u8')) {
        if (Hls.isSupported()) {
          var hls = new Hls();
          hls.loadSource(videoUrl);
          hls.attachMedia(video);
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          video.src = videoUrl;
        }
      }

      // Try deep link redirect on mobile if requested
      var params = new URLSearchParams(window.location.search);
      if (params.get('open') === 'app') {
        window.location.href = "${deepLink}";
      }
    });
  </script>
</body>
</html>`;
  }

  private buildNotFoundHtml(fullUrl: string): string {
    return `<!DOCTYPE html>
<html lang="am">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ይዘቱ አልተገኘም | ዝክረ ቅዱሳን</title>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Ethiopic:wght@400;700&display=swap" rel="stylesheet">
  <style>
    body {
      background: #0b0c10;
      color: #f7fafc;
      font-family: 'Noto Sans Ethiopic', sans-serif;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      margin: 0;
      text-align: center;
    }
    .card {
      background: #171923;
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 20px;
      padding: 40px 24px;
      max-width: 480px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    .icon {
      font-size: 50px;
      margin-bottom: 16px;
    }
    h1 {
      font-size: 20px;
      margin-bottom: 10px;
      color: #e5a93b;
    }
    p {
      color: #a0aec0;
      font-size: 14px;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    a {
      display: inline-block;
      background: #e5a93b;
      color: #0b0c10;
      font-weight: 700;
      padding: 10px 24px;
      border-radius: 999px;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">🔍</div>
    <h1>ይዘቱ አልተገኘም / Content Not Found</h1>
    <p>የፈለጉት ቪዲዮ ወይም መልእክት አልተገኘም ወይም ተሰርዟል። እባክዎ ሊንኩን እንደገና ያረጋግጡ።</p>
    <a href="zkrekidusan://home">ወደ ዝክረ ቅዱሳን መተግበሪያ ተመለስ</a>
  </div>
</body>
</html>`;
  }

  private buildErrorHtml(err: any): string {
    return `<!DOCTYPE html>
<html lang="am">
<head>
  <meta charset="UTF-8">
  <title>ስህተት ተከስቷል | ዝክረ ቅዱሳን</title>
</head>
<body style="background:#0b0c10;color:#fff;font-family:sans-serif;text-align:center;padding:50px;">
  <h2>ስህተት ተከስቷል / Something went wrong</h2>
  <p style="color:#aaa;">እባክዎ ትንሽ ቆይተው እንደገና ይሞክሩ።</p>
</body>
</html>`;
  }
}
