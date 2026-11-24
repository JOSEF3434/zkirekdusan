// src/modules/auth/services/sms-provider.interface.ts

export interface SmsSendResult {
  success: boolean;
  messageId?: string;
  error?: string;
  carrier?: string;
}

export interface SmsProvider {
  readonly name: string;
  sendSms(to: string, message: string): Promise<SmsSendResult>;
}
