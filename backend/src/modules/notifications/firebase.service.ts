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

  async sendPushNotification(payload: {
    token: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  }): Promise<boolean> {
    if (!this.initialized) return false;

    try {
      await getMessaging(this.app).send({
        token: payload.token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
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
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens: payload.tokens,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
      });
      this.logger.log(
        `Multicast push sent: ${response.successCount} success, ${response.failureCount} failure`,
      );
    } catch (err) {
      this.logger.error('Multicast push failed', err);
    }
  }
}
