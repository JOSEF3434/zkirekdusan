// src/modules/well-known/well-known.controller.ts
//
// Serves /.well-known/assetlinks.json and /.well-known/apple-app-site-association
// for Android App Links and iOS Universal Links verification.
//
// These files must be served without redirects and with correct Content-Type.
// The backend serves them because the Flutter web build is a SPA deployed on Render
// with a catch-all redirect that would otherwise swallow these paths.

import { Controller, Get, Res } from '@nestjs/common';
import type { Response } from 'express';
import { Public } from '../../common/decorators/public.decorator.js';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

const ANDROID_PACKAGE = 'com.zikrekidusan.mobile';

// SHA-256 fingerprints for Android App Links verification.
// Add your release certificate fingerprint here when you have it.
// To obtain: keytool -list -v -keystore <your.keystore> -alias <alias> -storepass <pass>
// Debug cert (for development/testing only — never use alone in production):
const DEBUG_SHA256 =
  'FE:C8:D5:2A:86:62:68:17:76:AC:4B:91:BB:B0:F1:33:AA:43:2B:5D:A6:7C:0A:37:E0:00:E7:B5:F0:6A:EC:3D';

// Replace TEAMID with your actual Apple Developer Team ID.
// Replace com.example.mobile with com.zikrekidusan.mobile after updating the Xcode project.
const IOS_APP_ID = 'TEAMID.com.example.mobile';

@ApiTags('Well-Known')
@Controller('.well-known')
export class WellKnownController {
  @Public()
  @Get('assetlinks.json')
  @ApiOperation({ summary: 'Android App Links verification file' })
  assetLinks(@Res() res: Response): void {
    const payload = [
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: ANDROID_PACKAGE,
          sha256_cert_fingerprints: [DEBUG_SHA256],
        },
      },
    ];

    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Cache-Control', 'no-cache');
    res.status(200).json(payload);
  }

  @Public()
  @Get('apple-app-site-association')
  @ApiOperation({ summary: 'iOS Universal Links verification file' })
  appleAppSiteAssociation(@Res() res: Response): void {
    const payload = {
      applinks: {
        apps: [],
        details: [
          {
            appID: IOS_APP_ID,
            paths: ['/u/*', '/g/*', '/c/*', '/join/group/*', '/video/*', '/*'],
          },
        ],
      },
      webcredentials: {
        apps: [IOS_APP_ID],
      },
    };

    // Apple requires this exact content type (no charset suffix)
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Cache-Control', 'no-cache');
    res.status(200).json(payload);
  }
}
