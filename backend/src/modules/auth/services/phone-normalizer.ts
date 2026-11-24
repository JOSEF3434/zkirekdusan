// src/modules/auth/services/phone-normalizer.ts

export type EthiopianCarrier = 'ETHIO_TELECOM' | 'SAFARICOM' | 'UNKNOWN';

export interface EthiopianPhoneDetails {
  isValid: boolean;
  e164: string | null;
  national: string | null;
  carrier: EthiopianCarrier;
}

/**
 * Normalizes and validates Ethiopian phone numbers.
 *
 * Supported formats:
 * - Ethio Telecom (mobile starts with 9):
 *     +2519XXXXXXXX, 2519XXXXXXXX, 09XXXXXXXX, 9XXXXXXXX
 * - Safaricom Ethiopia (mobile starts with 7):
 *     +2517XXXXXXXX, 2517XXXXXXXX, 07XXXXXXXX, 7XXXXXXXX
 */
export function parseEthiopianPhoneNumber(rawPhone: string): EthiopianPhoneDetails {
  if (!rawPhone || typeof rawPhone !== 'string') {
    return { isValid: false, e164: null, national: null, carrier: 'UNKNOWN' };
  }

  // Remove whitespace, dashes, parentheses, dots
  let cleaned = rawPhone.replace(/[\s\-\(\)\.]/g, '').trim();

  // If starts with +, remove + for parsing
  if (cleaned.startsWith('+')) {
    cleaned = cleaned.substring(1);
  }

  let subscriberDigits = '';
  let carrier: EthiopianCarrier = 'UNKNOWN';

  if (cleaned.startsWith('251')) {
    subscriberDigits = cleaned.substring(3);
  } else if (cleaned.startsWith('0')) {
    subscriberDigits = cleaned.substring(1);
  } else {
    subscriberDigits = cleaned;
  }

  // An Ethiopian mobile number has 9 subscriber digits (e.g. 911223344 or 711223344)
  if (/^[0-9]{9}$/.test(subscriberDigits)) {
    if (subscriberDigits.startsWith('9')) {
      carrier = 'ETHIO_TELECOM';
    } else if (subscriberDigits.startsWith('7')) {
      carrier = 'SAFARICOM';
    }
  }

  if (carrier === 'UNKNOWN') {
    return { isValid: false, e164: null, national: null, carrier: 'UNKNOWN' };
  }

  const e164 = `+251${subscriberDigits}`;
  const national = `0${subscriberDigits}`;

  return {
    isValid: true,
    e164,
    national,
    carrier,
  };
}

export function normalizeEthiopianPhoneNumber(rawPhone: string): string | null {
  const parsed = parseEthiopianPhoneNumber(rawPhone);
  return parsed.isValid ? parsed.e164 : null;
}

export function isValidEthiopianPhoneNumber(rawPhone: string): boolean {
  return parseEthiopianPhoneNumber(rawPhone).isValid;
}

export function getEthiopianCarrier(rawPhone: string): EthiopianCarrier {
  return parseEthiopianPhoneNumber(rawPhone).carrier;
}
