// src/modules/auth/services/afromessage-sms.provider.ts
import { Logger } from '@nestjs/common';
import { SmsProvider, SmsSendResult } from './sms-provider.interface.js';

export interface AfroMessageConfig {
  apiKey: string;
  apiUrl?: string;
  senderId?: string;
  identifierId?: string;
  timeoutMs?: number;
}

/**
 * AfroMessage SMS Provider implementation for Ethiopian destinations (Ethio Telecom and Safaricom Ethiopia).
 * Matches AfroMessage HTTP API specifications.
 */
export class AfroMessageSmsProvider implements SmsProvider {
  readonly name = 'afromessage';
  private readonly logger = new Logger(AfroMessageSmsProvider.name);
  private readonly apiKey: string;
  private readonly apiUrl: string;
  private readonly senderId?: string;
  private readonly identifierId?: string;
  private readonly timeoutMs: number;

  constructor(config: AfroMessageConfig) {
    this.apiKey = config.apiKey;
    this.apiUrl = config.apiUrl || 'https://api.afromessage.com/api/send';
    this.senderId = config.senderId;
    this.identifierId = config.identifierId;
    this.timeoutMs = config.timeoutMs ?? 10000;
  }

  async sendSms(to: string, message: string): Promise<SmsSendResult> {
    if (!this.apiKey) {
      this.logger.warn('AfroMessage API key is not configured.');
      return {
        success: false,
        error: 'AfroMessage API key is missing.',
      };
    }

    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);

      const payload: Record<string, unknown> = {
        to,
        message,
      };

      if (this.senderId) {
        payload.sender = this.senderId;
      }
      if (this.identifierId) {
        payload.from = this.identifierId;
      }

      this.logger.log(`Dispatching SMS via AfroMessage to destination ${to.substring(0, 7)}****`);

      const response = await fetch(this.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timer);

      if (!response.ok) {
        const status = response.status;
        let errorDetails = '';
        try {
          const errJson = await response.json();
          errorDetails = JSON.stringify(errJson);
        } catch {
          errorDetails = await response.text();
        }

        this.logger.error(`AfroMessage request failed with HTTP ${status}: ${errorDetails}`);
        return {
          success: false,
          error: `AfroMessage gateway error (HTTP ${status})`,
        };
      }

      const resData = (await response.json()) as any;
      const messageId = resData?.response?.id ?? resData?.id ?? resData?.message_id;

      this.logger.log(`SMS successfully accepted by AfroMessage (messageId: ${messageId ?? 'unknown'})`);
      return {
        success: true,
        messageId: messageId ? String(messageId) : undefined,
      };
    } catch (err: any) {
      const isAbort = err?.name === 'AbortError';
      const msg = isAbort ? 'Request timed out after 10s' : (err?.message || 'Network error');
      this.logger.error(`AfroMessage SMS delivery error: ${msg}`);
      return {
        success: false,
        error: msg,
      };
    }
  }
}
