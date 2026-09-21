import { Controller, Get, Param, Res, HttpStatus } from '@nestjs/common';
import type { Response } from 'express';
import { AppService } from './app.service.js';
import { PrismaService } from './prisma/prisma.service.js';
import { Public } from './common/decorators/public.decorator.js';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Public()
  @Get()
  getHello() {
    return this.appService.getHello();
  }

  // ─────────────────────────────────────────────
  // Android App Links verification file
  // ─────────────────────────────────────────────
  @Public()
  @Get('.well-known/assetlinks.json')
  getAssetLinks(@Res() res: Response) {
    res.setHeader('Content-Type', 'application/json');
    return res.status(HttpStatus.OK).json([
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: 'com.zikrekidusan.mobile',
          sha256_cert_fingerprints: [
            // Standard debug and release cert fingerprints
            'FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C',
          ],
        },
      },
    ]);
  }

  // ─────────────────────────────────────────────
  // iOS Universal Links verification file
  // ─────────────────────────────────────────────
  @Public()
  @Get('.well-known/apple-app-site-association')
  getAppleSiteAssociation(@Res() res: Response) {
    res.setHeader('Content-Type', 'application/json');
    return res.status(HttpStatus.OK).json({
      applinks: {
        apps: [],
        details: [
          {
            appID: 'TEAMID.com.zikrekidusan.mobile',
            paths: ['/u/*', '/g/*', '/video/*', '/playlist/*'],
          },
        ],
      },
    });
  }

  // ─────────────────────────────────────────────
  // Web Fallback Landing Page for /u/:username
  // ─────────────────────────────────────────────
  @Public()
  @Get('u/:username')
  async handleUserProfileWebLanding(
    @Param('username') username: string,
    @Res() res: Response,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { username },
      include: {
        profile: {
          select: {
            displayName: true,
            bio: true,
            avatar: {
              select: {
                url: true,
              },
            },
          },
        },
      },
    });

    const appSchemeUrl = `zikrekidusan://profile/user/${encodeURIComponent(username)}`;
    const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.zikrekidusan.mobile';
    const appStoreUrl = 'https://apps.apple.com/app/zikre-kidusan/id123456789';

    if (!user) {
      return res.status(HttpStatus.NOT_FOUND).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>User Not Found — Zikre Kidusan</title>
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0E1621; color: #fff; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; text-align: center; }
            .card { background: #17212B; padding: 40px 30px; border-radius: 20px; max-width: 400px; width: 90%; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
            h1 { font-size: 24px; margin-bottom: 10px; color: #ff5555; }
            p { color: #8E9BA8; line-height: 1.5; margin-bottom: 24px; }
            .btn { display: inline-block; background: #00C6FF; color: #000; padding: 12px 28px; border-radius: 25px; text-decoration: none; font-weight: bold; }
          </style>
        </head>
        <body>
          <div class="card">
            <h1>User Not Found</h1>
            <p>The profile for <strong>@${escapeHtml(username)}</strong> does not exist or has been deactivated.</p>
            <a href="${playStoreUrl}" class="btn">Get Zikre Kidusan App</a>
          </div>
        </body>
        </html>
      `);
    }

    const displayName =
      user.profile?.displayName || user.username || 'Zikre Kidusan User';
    const bio = user.profile?.bio || 'Check out this profile on Zikre Kidusan.';
    const avatarUrl =
      user.profile?.avatar?.url || 'https://via.placeholder.com/150';

    return res.status(HttpStatus.OK).send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${escapeHtml(displayName)} (@${escapeHtml(username)}) — Zikre Kidusan</title>
        <meta property="og:title" content="${escapeHtml(displayName)} on Zikre Kidusan">
        <meta property="og:description" content="${escapeHtml(bio)}">
        <meta property="og:image" content="${escapeHtml(avatarUrl)}">
        <style>
          * { box-sizing: border-box; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #0E1621;
            color: #FFFFFF;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
          }
          .card {
            background: #17212B;
            padding: 40px 24px;
            border-radius: 24px;
            max-width: 420px;
            width: 100%;
            text-align: center;
            box-shadow: 0 15px 35px rgba(0,0,0,0.6);
            border: 1px solid rgba(255,255,255,0.06);
          }
          .avatar {
            width: 110px;
            height: 110px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #00C6FF;
            margin-bottom: 16px;
            background: #232E3C;
          }
          h1 { font-size: 22px; margin: 0 0 6px 0; font-weight: 700; }
          .username { color: #00C6FF; font-size: 15px; margin-bottom: 14px; font-weight: 600; }
          .bio { color: #A4B3C2; font-size: 14px; line-height: 1.5; margin-bottom: 28px; }
          .btn-main {
            display: block;
            width: 100%;
            background: linear-gradient(135deg, #00C6FF, #0072FF);
            color: #FFFFFF;
            padding: 14px 20px;
            border-radius: 14px;
            text-decoration: none;
            font-weight: 700;
            font-size: 16px;
            margin-bottom: 14px;
            transition: opacity 0.2s;
          }
          .btn-main:hover { opacity: 0.9; }
          .store-buttons { display: flex; gap: 10px; justify-content: center; }
          .btn-store {
            flex: 1;
            background: #232E3C;
            color: #E1E8F0;
            padding: 10px 14px;
            border-radius: 12px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
            border: 1px solid rgba(255,255,255,0.1);
          }
          .footer-text {
            color: #6C7A89;
            font-size: 12px;
            margin-top: 24px;
          }
        </style>
        <script>
          // Automatic app intent launch attempt
          window.onload = function() {
            setTimeout(function() {
              window.location.href = "${appSchemeUrl}";
            }, 300);
          };
        </script>
      </head>
      <body>
        <div class="card">
          <img class="avatar" src="${escapeHtml(avatarUrl)}" alt="${escapeHtml(displayName)}" onerror="this.src='https://via.placeholder.com/150'">
          <h1>${escapeHtml(displayName)}</h1>
          <div class="username">@${escapeHtml(username)}</div>
          <div class="bio">${escapeHtml(bio)}</div>
          
          <a href="${appSchemeUrl}" class="btn-main">Open in Zikre Kidusan</a>
          
          <div class="store-buttons">
            <a href="${playStoreUrl}" class="btn-store">Google Play</a>
            <a href="${appStoreUrl}" class="btn-store">App Store</a>
          </div>

          <div class="footer-text">
            Don't have the app? Download it above to connect with @${escapeHtml(username)}.
          </div>
        </div>
      </body>
      </html>
    `);
  }
}

function escapeHtml(unsafe: string): string {
  return (unsafe || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
