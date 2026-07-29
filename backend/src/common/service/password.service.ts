// src/common/service/password.service.ts
import { Injectable, Logger } from '@nestjs/common';
import bcrypt from 'bcrypt';
import { ConfigService } from '@nestjs/config';

/**
 * Centralized password hashing and comparison service.
 *
 * CRITICAL FIX: BCRYPT_ROUNDS was previously read as a string ("12") from .env,
 * causing bcrypt to interpret it as an invalid salt — producing HTTP 500 with
 * "Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue".
 *
 * Fix: parseInt() ensures the rounds value is always a valid integer.
 *
 * SAFE COMPARE: compare() guards against null/invalid hashes gracefully
 * returning false instead of throwing, preventing 500 errors for legacy records.
 */
@Injectable()
export class PasswordService {
  private readonly logger = new Logger(PasswordService.name);
  private readonly rounds: number;

  constructor(private readonly configService: ConfigService) {
    const raw = this.configService.get<string | number>('BCRYPT_ROUNDS');
    const parsed = parseInt(String(raw ?? '12'), 10);

    if (isNaN(parsed) || parsed < 10 || parsed > 31) {
      this.logger.warn(
        `BCRYPT_ROUNDS value "${raw}" is invalid or unsafe — defaulting to 12`,
      );
      this.rounds = 12;
    } else {
      this.rounds = parsed;
    }
  }

  async hash(plaintext: string): Promise<string> {
    return bcrypt.hash(plaintext, this.rounds);
  }

  /**
   * Safely compare a plaintext string against a stored hash.
   *
   * Guards against:
   * - null / undefined hash (missing passwordHash in DB)
   * - non-bcrypt strings (plain-text legacy passwords)
   *
   * Returns false in all invalid-hash cases instead of throwing.
   */
  async compare(plaintext: string, hash: string | null | undefined): Promise<boolean> {
    if (!hash || !hash.startsWith('$2')) {
      // Hash is null, empty, or not a bcrypt hash — safe rejection
      this.logger.warn(
        'compare() called with a non-bcrypt hash — returning false (possible legacy record)',
      );
      return false;
    }

    try {
      return await bcrypt.compare(plaintext, hash);
    } catch (err) {
      this.logger.error(
        `bcrypt.compare threw unexpectedly: ${(err as Error).message}`,
      );
      return false;
    }
  }
}
