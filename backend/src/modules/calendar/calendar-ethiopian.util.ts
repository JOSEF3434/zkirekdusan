// src/modules/calendar/calendar-ethiopian.util.ts
/**
 * Authoritative Ethiopian Calendar Utilities for Zikre Kedusan.
 * Aligns 1:1 with Abushakir calendar arithmetic and Africa/Addis_Ababa timezone (UTC+3).
 */

const ETHIOPIC_EPOCH = 2796;
const UNIX_EPOCH = 719163;
const ADDIS_OFFSET_MS = 3 * 3600 * 1000; // Africa/Addis_Ababa is permanently UTC+3

export interface EthiopianDate {
  year: number;
  month: number;
  day: number;
}

export interface EthiopianDateTime extends EthiopianDate {
  hour: number;
  minute: number;
  second: number;
}

export interface EthiopianRollingWindow {
  start: EthiopianDate;
  end: EthiopianDate;
  startFormatted: string;
  endFormatted: string;
}

/**
 * Ethiopian leap year occurs when year % 4 === 3.
 * Leap years have 6 days in Pagumen (month 13); normal years have 5 days.
 */
export function isEthiopianLeapYear(year: number): boolean {
  return year % 4 === 3;
}

/**
 * Returns number of days in the specified Ethiopian month (1-13).
 * Months 1-12 have 30 days. Month 13 (Pagume) has 5 (or 6 in leap years).
 */
export function getDaysInEthiopianMonth(year: number, month: number): number {
  if (month < 1 || month > 13) return 0;
  if (month === 13) {
    return isEthiopianLeapYear(year) ? 6 : 5;
  }
  return 30;
}

/**
 * Converts Ethiopian date to fixed day count since epoch.
 */
export function fixedFromEthiopic(year: number, month: number, day: number): number {
  return (
    ETHIOPIC_EPOCH -
    1 +
    365 * (year - 1) +
    Math.floor(year / 4) +
    30 * (month - 1) +
    day
  );
}

/**
 * Converts Unix timestamp (milliseconds) to fixed day count.
 */
export function fixedFromUnix(ms: number): number {
  return UNIX_EPOCH + Math.floor(ms / 86400000);
}

/**
 * Converts fixed day count to Ethiopian date.
 */
export function ethiopianFromFixed(fixed: number): EthiopianDate {
  const year = Math.floor((4 * (fixed - ETHIOPIC_EPOCH) + 1463) / 1461);
  const month = Math.floor((fixed - fixedFromEthiopic(year, 1, 1)) / 30) + 1;
  const day = fixed + 1 - fixedFromEthiopic(year, month, 1);
  return { year, month, day };
}

/**
 * Converts milliseconds since Unix epoch to Ethiopian date.
 */
export function ethiopianFromUnix(ms: number): EthiopianDate {
  const fixed = fixedFromUnix(ms);
  return ethiopianFromFixed(fixed);
}

/**
 * Converts broken down Ethiopian date and time to milliseconds since Unix epoch.
 */
export function dateToEpoch(
  year: number,
  month: number,
  day: number,
  hour = 0,
  minute = 0,
  second = 0,
  millisecond = 0,
): number {
  return (
    (fixedFromEthiopic(year, month, day) - UNIX_EPOCH) * 86400000 +
    hour * 3600000 +
    minute * 60000 +
    second * 1000 +
    millisecond
  );
}

/**
 * Get current Ethiopian date and time in Africa/Addis_Ababa timezone (UTC+3).
 */
export function getEthiopianDate(
  date: Date = new Date(),
  timezone = 'Africa/Addis_Ababa',
): EthiopianDateTime {
  // Add 3 hours to UTC timestamp for Africa/Addis_Ababa
  const localMs = date.getTime() + ADDIS_OFFSET_MS;
  const eth = ethiopianFromUnix(localMs);

  // Calculate local hours/minutes/seconds from local timestamp
  const utcDate = new Date(localMs);
  const hour = utcDate.getUTCHours();
  const minute = utcDate.getUTCMinutes();
  const second = utcDate.getUTCSeconds();

  return {
    ...eth,
    hour,
    minute,
    second,
  };
}

/**
 * Converts Ethiopian date and local time (Africa/Addis_Ababa) to UTC Date.
 */
export function ethiopianToGregorian(
  year: number,
  month: number,
  day: number,
  hour = 0,
  minute = 0,
  second = 0,
): Date {
  const localEpoch = dateToEpoch(year, month, day, hour, minute, second);
  // Subtract 3 hours to obtain true UTC instant
  const utcEpoch = localEpoch - ADDIS_OFFSET_MS;
  return new Date(utcEpoch);
}

/**
 * Formats Ethiopian date as YYYY-MM-DD.
 */
export function formatEthiopianDate(year: number, month: number, day: number): string {
  const m = month.toString().padStart(2, '0');
  const d = day.toString().padStart(2, '0');
  return `${year}-${m}-${d}`;
}

/**
 * Parses YYYY-MM-DD Ethiopian date string.
 */
export function parseEthiopianDate(str: string): EthiopianDate {
  const parts = str.split('-').map(Number);
  if (parts.length < 3 || isNaN(parts[0]) || isNaN(parts[1]) || isNaN(parts[2])) {
    throw new Error(`Invalid Ethiopian date format: ${str}`);
  }
  return { year: parts[0], month: parts[1], day: parts[2] };
}

/**
 * Converts date to an integer score for monotonic chronological comparison:
 * year * 10000 + month * 100 + day.
 */
export function getEthiopianDateScore(year: number, month: number, day: number): number {
  return year * 10000 + month * 100 + day;
}

/**
 * Calculates the active rolling one-Ethiopian-year calendar window.
 * START: Same Ethiopian month/day in the previous Ethiopian year (clamped to month length).
 * END: Current Ethiopian date.
 * The window is inclusive and covers all 13 Ethiopian months.
 */
export function calculateRollingOneYearWindow(
  currentEth: EthiopianDate,
): EthiopianRollingWindow {
  const prevYear = currentEth.year - 1;
  const maxPrevDays = getDaysInEthiopianMonth(prevYear, currentEth.month);
  const startDay = Math.min(currentEth.day, maxPrevDays);

  const start: EthiopianDate = {
    year: prevYear,
    month: currentEth.month,
    day: startDay,
  };

  const end: EthiopianDate = {
    year: currentEth.year,
    month: currentEth.month,
    day: currentEth.day,
  };

  return {
    start,
    end,
    startFormatted: formatEthiopianDate(start.year, start.month, start.day),
    endFormatted: formatEthiopianDate(end.year, end.month, end.day),
  };
}

/**
 * Checks if an Ethiopian date falls within the inclusive rolling window.
 */
export function isDateInRollingWindow(
  date: EthiopianDate,
  window: EthiopianRollingWindow,
): boolean {
  const score = getEthiopianDateScore(date.year, date.month, date.day);
  const startScore = getEthiopianDateScore(
    window.start.year,
    window.start.month,
    window.start.day,
  );
  const endScore = getEthiopianDateScore(
    window.end.year,
    window.end.month,
    window.end.day,
  );
  return score >= startScore && score <= endScore;
}

/**
 * Calculates the next valid Ethiopian monthly occurrence for a given source day.
 * Handles month transitions, Pagume (5 or 6 days), and deterministic skipping
 * if sourceDay exceeds days in Pagume.
 */
export function getNextMonthlyOccurrence(
  sourceDay: number,
  currentEth: EthiopianDate,
): EthiopianDate {
  // If today matches sourceDay, today is the occurrence
  if (currentEth.day === sourceDay) {
    return { ...currentEth };
  }

  // Scan subsequent months (up to 24 months forward)
  for (let offset = 0; offset < 24; offset++) {
    const absoluteMonth = currentEth.month - 1 + offset;
    const year = currentEth.year + Math.floor(absoluteMonth / 13);
    const month = (absoluteMonth % 13) + 1;
    const maxDays = getDaysInEthiopianMonth(year, month);

    if (sourceDay <= maxDays) {
      if (
        year > currentEth.year ||
        (year === currentEth.year && month > currentEth.month) ||
        (year === currentEth.year && month === currentEth.month && sourceDay >= currentEth.day)
      ) {
        return { year, month, day: sourceDay };
      }
    }
  }

  // Fallback (should never be reached within 24 months)
  return { year: currentEth.year + 1, month: 1, day: Math.min(sourceDay, 30) };
}

/**
 * Calculates the next valid Ethiopian annual occurrence for a given source month and day.
 * Handles leap years and Pagume clamp if sourceDay is 6 in a non-leap year.
 */
export function getNextAnnualOccurrence(
  sourceMonth: number,
  sourceDay: number,
  currentEth: EthiopianDate,
): EthiopianDate {
  // Try current year first
  let targetYear = currentEth.year;
  let maxDays = getDaysInEthiopianMonth(targetYear, sourceMonth);
  let effectiveDay = Math.min(sourceDay, maxDays);

  const currentScore = getEthiopianDateScore(
    currentEth.year,
    currentEth.month,
    currentEth.day,
  );
  const occurrenceScore = getEthiopianDateScore(
    targetYear,
    sourceMonth,
    effectiveDay,
  );

  if (occurrenceScore < currentScore) {
    // Already passed in current year, roll to next year
    targetYear += 1;
    maxDays = getDaysInEthiopianMonth(targetYear, sourceMonth);
    effectiveDay = Math.min(sourceDay, maxDays);
  }

  return {
    year: targetYear,
    month: sourceMonth,
    day: effectiveDay,
  };
}
