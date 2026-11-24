// src/modules/auth/services/sms-delivery.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsProvider, SmsSendResult } from './sms-provider.interface.js';
import { AfroMessageSmsProvider } from './afromessage-sms.provider.js';
import {
  EthiopianCarrier,
  getEthiopianCarrier,
  normalizeEthiopianPhoneNumber,
} from './phone-normalizer.js';

class DisabledSmsProvider implements SmsProvider {
  readonly name = 'disabled';
  private readonly logger = new Logger(DisabledSmsProvider.name);

  async sendSms(to: string, _message: string): Promise<SmsSendResult> {
    this.logger.warn(
      `SMS requested for ${to.substring(0, 7)}****, but SMS provider is disabled or unconfigured in environment.`,
    );
    return {
      success: false,
      error: 'SMS service is not configured. Please contact administrator or use email recovery.',
    };
  }
}

class GenericHttpSmsProvider implements SmsProvider {
  readonly name = 'generic-http';
  private readonly logger = new Logger(GenericHttpSmsProvider.name);

  constructor(
    private readonly endpoint: string,
    private readonly apiKey: string,
    private readonly senderId?: string,
  ) {}

  async sendSms(to: string, message: string): Promise<SmsSendResult> {
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 10000);

      const res = await fetch(this.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          to,
          message,
          sender: this.senderId,
        }),
        signal: controller.signal,
      });

      clearTimeout(timer);

      if (!res.ok) {
        return {
          success: false,
          error: `HTTP SMS provider responded with status ${res.status}`,
        };
      }

      const body: any = await res.json().catch(() => ({}));
      return {
        success: true,
        messageId: body?.id ? String(body.id) : undefined,
      };
    } catch (err: any) {
      this.logger.error(`Generic HTTP SMS error: ${err?.message}`);
      return { success: false, error: err?.message || 'SMS delivery error' };
    }
  }
}

@Injectable()
export class SmsDeliveryService {
  private readonly logger = new Logger(SmsDeliveryService.name);
  private readonly provider: SmsProvider;
  private readonly isConfigured: boolean;

  constructor(private readonly configService: ConfigService) {
    const providerName = (
      this.configService.get<string>('SMS_PROVIDER') ?? 'afromessage'
    ).toLowerCase();

    const apiKey =
      this.configService.get<string>('AFROMESSAGE_API_KEY') ||
      this.configService.get<string>('SMS_API_KEY') ||
      '';

    const apiUrl =
      this.configService.get<string>('AFROMESSAGE_API_URL') ||
      this.configService.get<string>('SMS_API_URL') ||
      'https://api.afromessage.com/api/send';

    const senderId =
      this.configService.get<string>('AFROMESSAGE_SENDER_ID') ||
      this.configService.get<string>('SMS_SENDER_ID') ||
      'ZikreKedusan';

    if (providerName === 'disabled' || !apiKey) {
      this.logger.warn(
        'SMS delivery service initialized in DISABLED mode (missing SMS_API_KEY / AFROMESSAGE_API_KEY).',
      );
      this.provider = new DisabledSmsProvider();
      this.isConfigured = false;
    } else if (providerName === 'http' || providerName === 'generic') {
      this.provider = new GenericHttpSmsProvider(apiUrl, apiKey, senderId);
      this.isConfigured = true;
      this.logger.log(`SMS delivery initialized with generic HTTP provider: ${apiUrl}`);
    } else {
      // Default to AfroMessage adapter
      this.provider = new AfroMessageSmsProvider({
        apiKey,
        apiUrl,
        senderId,
        identifierId: this.configService.get<string>('AFROMESSAGE_IDENTIFIER_ID'),
      });
      this.isConfigured = true;
      this.logger.log(
        `SMS delivery initialized with AfroMessage provider for Ethiopian carriers (Ethio Telecom / Safaricom).`,
      );
    }
  }

  get configured(): boolean {
    return this.isConfigured;
  }

  /**
   * Dispatches a 6-digit recovery OTP via SMS.
   */
  async sendRecoveryOtp(
    rawPhone: string,
    otp: string,
  ): Promise<{ success: boolean; carrier: EthiopianCarrier; error?: string }> {
    const normalized = normalizeEthiopianPhoneNumber(rawPhone);
    if (!normalized) {
      return {
        success: false,
        carrier: 'UNKNOWN',
        error: 'Invalid Ethiopian phone number format.',
      };
    }

    const carrier = getEthiopianCarrier(normalized);

    const message = `[ዝክረ ክዱሳን / Zikre Kedusan] Your password recovery code is: ${otp}. Valid for 5 minutes. Do not share this code.`;

    const result = await this.provider.sendSms(normalized, message);

    return {
      success: result.success,
      carrier,
      error: result.error,
    };
  }
}
