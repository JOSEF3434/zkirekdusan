// src/modules/notifications/firebase.service.ts
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  App,
  ServiceAccount,
  cert,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private initialized = false;
  private app?: App;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    const credentialsJson = this.configService.get<string>(
      'FCM_SERVICE_ACCOUNT_JSON',
    );

    if (!credentialsJson) {
      this.logger.warn(
        'FCM_SERVICE_ACCOUNT_JSON not set. Push notifications are disabled.',
      );
      return;
    }

    try {
      if (getApps().length === 0) {
        const serviceAccount = JSON.parse(credentialsJson) as ServiceAccount;
        this.app = initializeApp({
          credential: cert(serviceAccount),
        });
      } else {
        this.app = getApps()[0];
      }
      this.initialized = true;
      this.logger.log('Firebase Admin SDK initialized successfully.');
    } catch (err) {
      this.logger.error('Failed to initialize Firebase Admin SDK', err);
    }
  }

  private buildDataPayload(payload: {
    title: string;
    body: string;
    data?: Record<string, any>;
  }): Record<string, string> {
    const fcmData: Record<string, string> = {
      title: payload.title ?? '',
      body: payload.body ?? '',
    };
    if (payload.data) {
      for (const [k, v] of Object.entries(payload.data)) {
        if (v !== undefined && v !== null) {
          fcmData[k] = typeof v === 'string' ? v : JSON.stringify(v);
        }
      }
    }
    return fcmData;
  }

  async sendPushNotification(payload: {
    token: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  }): Promise<boolean> {
    if (!this.initialized) return false;

    try {
      const fcmData = this.buildDataPayload(payload);

      // SECURITY: DATA-ONLY FCM payload.
      // Do NOT send top-level or android/apns `notification` objects.
      // A raw `notification` payload causes Android/iOS to render sensitive
      // contents in the system notification shade automatically, bypassing
      // the application's App Lock and notification privacy redaction logic.
      await getMessaging(this.app).send({
        token: payload.token,
        data: fcmData,
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: 'default',
            },
          },
        },
      });
      return true;
    } catch (err: unknown) {
      const error = err as { code?: string; message?: string };

      if (error.code === 'messaging/registration-token-not-registered') {
        this.logger.warn(
          `Stale FCM token removed: ${payload.token.substring(0, 20)}...`,
        );
      } else {
        this.logger.error('Failed to send push notification', error.message);
      }
      return false;
    }
  }

  async sendMulticast(payload: {
    tokens: string[];
    title: string;
    body: string;
    data?: Record<string, string>;
  }): Promise<void> {
    if (!this.initialized || payload.tokens.length === 0) return;

    try {
      const fcmData = this.buildDataPayload(payload);

      // SECURITY: DATA-ONLY FCM multicast payload.
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens: payload.tokens,
        data: fcmData,
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              contentAvailable: true,
              badge: 1,
              sound: 'default',
            },
          },
        },
      });
      this.logger.log(
        `Multicast push sent: ${response.successCount} success, ${response.failureCount} failure`,
      );
    } catch (err) {
      this.logger.error('Multicast push failed', err);
    }
  }
}
