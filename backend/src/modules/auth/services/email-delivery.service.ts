// src/modules/auth/services/email-delivery.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer, { Transporter } from 'nodemailer';

export interface EmailSendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

@Injectable()
export class EmailDeliveryService {
  private readonly logger = new Logger(EmailDeliveryService.name);
  private transporter: Transporter | null = null;
  private readonly isConfigured: boolean;
  private readonly fromAddress: string;
  private readonly fromName: string;
  private readonly appUrl: string;

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = parseInt(this.configService.get<string>('SMTP_PORT') ?? '587', 10);
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASSWORD');
    const secure =
      this.configService.get<string>('SMTP_SECURE') === 'true' || port === 465;

    this.fromAddress =
      this.configService.get<string>('MAIL_FROM') ??
      this.configService.get<string>('SMTP_FROM') ??
      'noreply@zikrekidusan.com';

    this.fromName =
      this.configService.get<string>('MAIL_FROM_NAME') ??
      this.configService.get<string>('SMTP_FROM_NAME') ??
      'ዝክረ ክዱሳን | Zikre Kedusan';

    this.appUrl = (
      this.configService.get<string>('APP_URL') ??
      this.configService.get<string>('RECOVERY_WEB_URL') ??
      'https://zikire-kdusan.onrender.com'
    ).replace(/\/$/, '');

    if (host && user && pass) {
      try {
        this.transporter = nodemailer.createTransport({
          host,
          port,
          secure,
          auth: {
            user,
            pass,
          },
          pool: true,
          maxConnections: 5,
          maxMessages: 100,
        });
        this.isConfigured = true;
        this.logger.log(`SMTP transporter initialized with host: ${host}:${port}`);
      } catch (err: any) {
        this.logger.error(`Failed to initialize SMTP transporter: ${err?.message}`);
        this.isConfigured = false;
      }
    } else {
      this.logger.warn(
        'EmailDeliveryService running in UNCONFIGURED mode. Set SMTP_HOST, SMTP_USER, and SMTP_PASSWORD in environment.',
      );
      this.isConfigured = false;
    }
  }

  get configured(): boolean {
    return this.isConfigured;
  }

  /**
   * Sends a branded password reset email with secure recovery link.
   */
  async sendPasswordResetEmail(
    to: string,
    resetToken: string,
    recipientName?: string,
  ): Promise<EmailSendResult> {
    const resetUrl = `${this.appUrl}/reset-password?token=${encodeURIComponent(resetToken)}`;

    const subject = 'Password Recovery Instructions — ዝክረ ክዱሳን';
    const nameDisplay = recipientName ? ` ${recipientName}` : '';

    const plainText = `
Selam${nameDisplay},

You recently requested to reset your password for your Zikre Kedusan account.

Please use the link below to set a new password:
${resetUrl}

SECURITY NOTICE:
- This link is single-use and will expire in 15 minutes.
- If you did not request this password reset, please ignore this email or contact support. Your password will remain unchanged.

Best regards,
The Zikre Kedusan Team
ዝክረ ክዱሳን
`.trim();

    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${subject}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F3F4F6; margin: 0; padding: 24px 12px; color: #1F2937; }
    .container { max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E5E7EB; }
    .header { background: linear-gradient(135deg, #1E3A8A 0%, #172554 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
    .header h1 { margin: 0 0 6px 0; font-size: 24px; font-weight: 700; color: #F59E0B; letter-spacing: 0.5px; }
    .header p { margin: 0; font-size: 14px; color: #E0E7FF; }
    .content { padding: 32px 28px; line-height: 1.6; }
    .btn-container { text-align: center; margin: 32px 0; }
    .btn { display: inline-block; background-color: #1E3A8A; color: #ffffff !important; padding: 14px 32px; border-radius: 10px; font-weight: 600; text-decoration: none; font-size: 15px; box-shadow: 0 2px 4px rgba(30, 58, 138, 0.3); }
    .note-box { background-color: #FEF3C7; border-left: 4px solid #D97706; padding: 14px 16px; border-radius: 6px; font-size: 13px; color: #92400E; margin: 24px 0; }
    .fallback-url { font-size: 12px; color: #6B7280; word-break: break-all; background: #F9FAFB; padding: 10px 12px; border-radius: 6px; border: 1px solid #E5E7EB; }
    .footer { text-align: center; padding: 24px; font-size: 12px; color: #9CA3AF; border-top: 1px solid #F3F4F6; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>ዝክረ ክዱሳን</h1>
      <p>Zikre Kedusan Spiritual Sanctuary</p>
    </div>
    <div class="content">
      <h2 style="font-size: 20px; color: #111827; margin-top: 0;">Password Recovery Request</h2>
      <p>Selam${nameDisplay},</p>
      <p>We received a request to recover the password for your Zikre Kedusan account. Click the button below to choose a new password:</p>

      <div class="btn-container">
        <a href="${resetUrl}" class="btn" target="_blank">Reset My Password</a>
      </div>

      <div class="note-box">
        <strong>Important Security Notice:</strong>
        <ul style="margin: 6px 0 0 0; padding-left: 20px;">
          <li>This link is single-use and expires in <strong>15 minutes</strong>.</li>
          <li>If you did not request this recovery, please ignore this email or review your account security.</li>
        </ul>
      </div>

      <p style="font-size: 13px; color: #6B7280; margin-bottom: 6px;">If the button above does not work, copy and paste this link into your browser:</p>
      <div class="fallback-url">${resetUrl}</div>
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} Zikre Kedusan. All rights reserved.<br>
      Preserving Orthodox Christian Spiritual Heritage.
    </div>
  </div>
</body>
</html>
`.trim();

    return this.sendMail(to, subject, plainText, html);
  }

  /**
   * Sends an advisory email notifying the user that their password was changed.
   */
  async sendPasswordChangedNotificationEmail(
    to: string,
    recipientName?: string,
  ): Promise<EmailSendResult> {
    const subject = 'Your Password Was Changed — ዝክረ ክዱሳን';
    const nameDisplay = recipientName ? ` ${recipientName}` : '';

    const plainText = `
Selam${nameDisplay},

Your Zikre Kedusan account password was successfully updated on ${new Date().toUTCString()}.

If you made this change, no further action is required.
If you did NOT make this change, please contact support or perform account recovery immediately.

Best regards,
The Zikre Kedusan Team
`.trim();

    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${subject}</title>
</head>
<body style="font-family: sans-serif; background-color: #F9FAFB; padding: 24px; color: #1F2937;">
  <div style="max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 12px; padding: 28px; border: 1px solid #E5E7EB;">
    <h2 style="color: #1E3A8A; margin-top: 0;">Password Changed Successfully</h2>
    <p>Selam${nameDisplay},</p>
    <p>The password for your <strong>Zikre Kedusan</strong> account was changed on <strong>${new Date().toUTCString()}</strong>.</p>
    <p style="background: #FEF2F2; color: #991B1B; padding: 12px; border-radius: 6px; font-size: 13px;">
      If you did not initiate this change, someone else may have gained access to your account. Please recover your account immediately.
    </p>
    <p style="font-size: 13px; color: #6B7280;">Warm regards,<br>Zikre Kedusan Security Team</p>
  </div>
</body>
</html>
`.trim();

    return this.sendMail(to, subject, plainText, html);
  }

  private async sendMail(
    to: string,
    subject: string,
    text: string,
    html: string,
  ): Promise<EmailSendResult> {
    if (!this.transporter || !this.isConfigured) {
      this.logger.warn(
        `Email dispatch to ${to} skipped — SMTP is not configured in this environment.`,
      );
      return {
        success: false,
        error: 'SMTP service is not configured on this server.',
      };
    }

    try {
      const info = await this.transporter.sendMail({
        from: `"${this.fromName}" <${this.fromAddress}>`,
        to,
        subject,
        text,
        html,
      });

      this.logger.log(`Email dispatched successfully to ${to} (messageId: ${info.messageId})`);
      return {
        success: true,
        messageId: info.messageId,
      };
    } catch (err: any) {
      this.logger.error(`Failed to send email to ${to}: ${err?.message}`);
      return {
        success: false,
        error: err?.message || 'SMTP dispatch error',
      };
    }
  }
}
