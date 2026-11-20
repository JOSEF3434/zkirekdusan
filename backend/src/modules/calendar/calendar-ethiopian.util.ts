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

// ─────────────────────────────────────────────
// FASTING & HOLIDAY EVENT ARITHMETIC HELPERS
// ─────────────────────────────────────────────

export interface CalendarEventDateRange {
  isRecurring: boolean;
  ethiopianYear?: number | null;
  startMonth: number;
  startDay: number;
  startYear?: number | null;
  endMonth: number;
  endDay: number;
  endYear?: number | null;
}

export interface EventMonthDaysCoverage {
  overlaps: boolean;
  days: number[];
  isStartMonth: boolean;
  isEndMonth: boolean;
  startDay?: number;
  endDay?: number;
  durationDays: number;
}

/**
 * Calculates the total inclusive duration (in days) between two Ethiopian dates.
 */
export function calculateEventDuration(
  startYear: number,
  startMonth: number,
  startDay: number,
  endYear: number,
  endMonth: number,
  endDay: number,
): number {
  const startFixed = fixedFromEthiopic(startYear, startMonth, startDay);
  const endFixed = fixedFromEthiopic(endYear, endMonth, endDay);
  return Math.max(1, endFixed - startFixed + 1);
}

/**
 * Checks whether an event overlaps with a specified Ethiopian month of a given year.
 */
export function doesEventOverlapMonth(
  event: CalendarEventDateRange,
  queryYear: number,
  queryMonth: number,
): boolean {
  if (queryMonth < 1 || queryMonth > 13) return false;

  // Year-specific check
  if (!event.isRecurring) {
    const sYear = event.startYear ?? event.ethiopianYear;
    const eYear = event.endYear ?? event.ethiopianYear ?? sYear;
    if (sYear != null && eYear != null) {
      if (queryYear < sYear || queryYear > eYear) return false;
      if (sYear === eYear) {
        if (event.startMonth === event.endMonth) {
          return queryMonth === event.startMonth;
        }
        return queryMonth >= event.startMonth && queryMonth <= event.endMonth;
      }
      // Spans across multiple years (e.g. sYear: 2016, eYear: 2017)
      if (queryYear === sYear) {
        return queryMonth >= event.startMonth;
      }
      if (queryYear === eYear) {
        return queryMonth <= event.endMonth;
      }
      return true; // Middle year is entirely covered
    }
  }

  const startM = event.startMonth;
  const endM = event.endMonth;

  if (startM === endM) {
    return startM === queryMonth;
  }

  if (startM < endM) {
    return queryMonth >= startM && queryMonth <= endM;
  }

  // Crosses Ethiopian year boundary (e.g., month 13 into month 1)
  return queryMonth >= startM || queryMonth <= endM;
}

/**
 * Calculates the exact days of queryMonth covered by an event, along with duration and boundary flags.
 */
export function getEventMonthDaysCoverage(
  event: CalendarEventDateRange,
  queryYear: number,
  queryMonth: number,
): EventMonthDaysCoverage {
  const overlaps = doesEventOverlapMonth(event, queryYear, queryMonth);
  const startYear = event.startYear ?? event.ethiopianYear ?? queryYear;
  let endYear = event.endYear ?? event.ethiopianYear ?? queryYear;
  if (event.isRecurring && event.startMonth > event.endMonth) {
    endYear = startYear + 1;
  }

  const durationDays = calculateEventDuration(
    startYear,
    event.startMonth,
    event.startDay,
    endYear,
    event.endMonth,
    event.endDay,
  );

  if (!overlaps) {
    return {
      overlaps: false,
      days: [],
      isStartMonth: false,
      isEndMonth: false,
      durationDays,
    };
  }

  const daysInMonth = getDaysInEthiopianMonth(queryYear, queryMonth);
  const startM = event.startMonth;
  const endM = event.endMonth;

  let isStartMonth = false;
  let isEndMonth = false;
  let fromDay = 1;
  let toDay = daysInMonth;

  if (startM === endM) {
    isStartMonth = true;
    isEndMonth = true;
    fromDay = Math.min(event.startDay, daysInMonth);
    toDay = Math.min(event.endDay, daysInMonth);
  } else if (queryMonth === startM) {
    isStartMonth = true;
    fromDay = Math.min(event.startDay, daysInMonth);
    toDay = daysInMonth;
  } else if (queryMonth === endM) {
    isEndMonth = true;
    fromDay = 1;
    toDay = Math.min(event.endDay, daysInMonth);
  } else {
    // Middle month entirely covered
    fromDay = 1;
    toDay = daysInMonth;
  }

  const days: number[] = [];
  for (let d = fromDay; d <= toDay; d++) {
    days.push(d);
  }

  return {
    overlaps: true,
    days,
    isStartMonth,
    isEndMonth,
    startDay: isStartMonth ? fromDay : undefined,
    endDay: isEndMonth ? toDay : undefined,
    durationDays,
  };
}

// ─────────────────────────────────────────────
// BAHIRE HASAB (ባሕረ ሐሳብ) & MOVABLE FEASTS / FASTS
// ─────────────────────────────────────────────

export interface BahireHasabCalculation {
  year: number;
  evangelist: string;
  isLeapYear: boolean;
  meskerem1Weekday: number; // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  wenber: number;
  abekte: number;
  metqe: number;
  nenewe: {
    startMonth: number;
    startDay: number;
    endMonth: number;
    endDay: number;
  };
  abiyTsom: {
    startMonth: number;
    startDay: number;
    endMonth: number;
    endDay: number;
    durationDays: number;
  };
  debreZeyt: { month: number; day: number };
  hosanna: { month: number; day: number };
  tseloteHamus: { month: number; day: number };
  siklet: { month: number; day: number };
  kedamSeur: { month: number; day: number };
  fasika: { month: number; day: number };
  rikbeKahnat: { month: number; day: number };
  erget: { month: number; day: number };
  peraklitos: { month: number; day: number };
  apostlesFast: {
    startMonth: number;
    startDay: number;
    endMonth: number;
    endDay: number;
    durationDays: number;
  };
  bealeHamsa: {
    startMonth: number;
    startDay: number;
    endMonth: number;
    endDay: number;
  };
}

export function calculateBahireHasab(year: number): BahireHasabCalculation {
  const ameteAlem = 5500 + year;
  const evangelists = ['ዮሐንስ', 'ማቴዎስ', 'ማርቆስ', 'ሉቃስ'];
  const evangelist = evangelists[ameteAlem % 4];
  const isLeap = isEthiopianLeapYear(year);

  const rabeet = Math.floor(ameteAlem / 4);
  const meskerem1Weekday0 = (ameteAlem + rabeet) % 7; // 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
  const meskerem1Weekday = meskerem1Weekday0 + 1; // 1=Mon ... 7=Sun

  let wenber = (ameteAlem % 19) - 1;
  if (wenber < 0) wenber = 0;
  const abekte = (wenber * 11) % 30;
  const metqe = wenber === 0 ? 30 : (wenber * 19) % 30;
  const metqeMonth = metqe > 14 ? 1 : 2;

  let metqeWeekday0: number;
  if (metqeMonth === 1) {
    metqeWeekday0 = (meskerem1Weekday0 + metqe - 1) % 7;
  } else {
    const tikimt1Weekday0 = (meskerem1Weekday0 + 2) % 7;
    metqeWeekday0 = (tikimt1Weekday0 + metqe - 1) % 7;
  }

  // Tewsak: Fri=2, Thu=3, Wed=4, Tue=5, Mon=6, Sun=7, Sat=8
  const tewsakMap: Record<number, number> = { 4: 2, 3: 3, 2: 4, 1: 5, 0: 6, 6: 7, 5: 8 };
  const dayTewsak = tewsakMap[metqeWeekday0];

  let neneweMonth: number;
  let neneweDay: number;
  const total = metqe + dayTewsak;
  if (metqeMonth === 1) {
    if (total > 30) {
      neneweMonth = 6; // Yekatit
      neneweDay = total % 30 === 0 ? 30 : total % 30;
    } else {
      neneweMonth = 5; // Tir
      neneweDay = total;
    }
  } else {
    neneweMonth = 6; // Yekatit
    neneweDay = total % 30 === 0 ? 30 : total % 30;
  }

  function addDaysToNenewe(offset: number): { month: number; day: number } {
    let m = neneweMonth;
    let d = neneweDay + offset;
    while (d > 30) {
      d -= 30;
      m += 1;
    }
    return { month: m, day: d };
  }

  const neneweEnd = addDaysToNenewe(2);
  const abiyTsomStart = addDaysToNenewe(14);
  const abiyTsomEnd = addDaysToNenewe(68);
  const debreZeyt = addDaysToNenewe(41);
  const hosanna = addDaysToNenewe(62);
  const tseloteHamus = addDaysToNenewe(66);
  const siklet = addDaysToNenewe(67);
  const kedamSeur = addDaysToNenewe(68);
  const fasika = addDaysToNenewe(69);
  const rikbeKahnat = addDaysToNenewe(93);
  const erget = addDaysToNenewe(108);
  const peraklitos = addDaysToNenewe(118);
  const apostlesFastStart = addDaysToNenewe(119);
  const apostlesFastEnd = { month: 11, day: 5 }; // Hamle 5

  const apostlesDuration =
    (11 - apostlesFastStart.month) * 30 + (5 - apostlesFastStart.day) + 1;

  return {
    year,
    evangelist,
    isLeapYear: isLeap,
    meskerem1Weekday,
    wenber,
    abekte,
    metqe,
    nenewe: {
      startMonth: neneweMonth,
      startDay: neneweDay,
      endMonth: neneweEnd.month,
      endDay: neneweEnd.day,
    },
    abiyTsom: {
      startMonth: abiyTsomStart.month,
      startDay: abiyTsomStart.day,
      endMonth: abiyTsomEnd.month,
      endDay: abiyTsomEnd.day,
      durationDays: 55,
    },
    debreZeyt,
    hosanna,
    tseloteHamus,
    siklet,
    kedamSeur,
    fasika,
    rikbeKahnat,
    erget,
    peraklitos,
    apostlesFast: {
      startMonth: apostlesFastStart.month,
      startDay: apostlesFastStart.day,
      endMonth: apostlesFastEnd.month,
      endDay: apostlesFastEnd.day,
      durationDays: Math.max(1, apostlesDuration),
    },
    bealeHamsa: {
      startMonth: fasika.month,
      startDay: fasika.day,
      endMonth: peraklitos.month,
      endDay: peraklitos.day,
    },
  };
}

/**
 * Returns the weekday (1=Monday ... 7=Sunday) for any Ethiopian date.
 */
export function getEthiopianWeekday(year: number, month: number, day: number): number {
  const ameteAlem = 5500 + year;
  const rabeet = Math.floor(ameteAlem / 4);
  const meskerem1Weekday0 = (ameteAlem + rabeet) % 7;
  const daysSince = (month - 1) * 30 + (day - 1);
  return ((meskerem1Weekday0 + daysSince) % 7) + 1;
}

/**
 * Determines whether an Ethiopian date is a Wednesday or Friday fast (ጾመ ድኅነት).
 * Accounts for:
 * 1. 50-day exemption (በዓለ ኀምሳ) between Fasika and Pentecost.
 * 2. Great feast exemptions: Genna (Tahsas 29, or 28 on leap year) and Timket (Tir 11).
 */
export function isWednesdayFridayFastingDay(
  year: number,
  month: number,
  day: number,
): boolean {
  const weekday = getEthiopianWeekday(year, month, day);
  if (weekday !== 3 && weekday !== 5) {
    return false; // Only Wednesday (3) and Friday (5)
  }

  const bh = calculateBahireHasab(year);
  const dateScore = month * 100 + day;
  const bealeHamsaStart = bh.bealeHamsa.startMonth * 100 + bh.bealeHamsa.startDay;
  const bealeHamsaEnd = bh.bealeHamsa.endMonth * 100 + bh.bealeHamsa.endDay;

  // Between Easter (Fasika) and Pentecost (Peraklitos)
  if (dateScore >= bealeHamsaStart && dateScore <= bealeHamsaEnd) {
    return false;
  }

  // Christmas (Genna) exemption
  const gennaDay = bh.isLeapYear ? 28 : 29;
  if (month === 4 && day === gennaDay) {
    return false;
  }

  // Epiphany (Timket) exemption
  if (month === 5 && day === 11) {
    return false;
  }

  return true;
}

/**
 * Returns all day numbers in a given Ethiopian month that are fasting Wednesdays and Fridays.
 */
export function getWednesdayFridayFastDaysForMonth(
  year: number,
  month: number,
): number[] {
  const maxDays = getDaysInEthiopianMonth(year, month);
  const fastDays: number[] = [];
  for (let d = 1; d <= maxDays; d++) {
    if (isWednesdayFridayFastingDay(year, month, d)) {
      fastDays.push(d);
    }
  }
  return fastDays;
}

/**
 * Returns dynamically calculated movable fasts and feasts for any given Ethiopian year.
 */
export function getMovableEventsForYear(year: number): any[] {
  const bh = calculateBahireHasab(year);

  return [
    {
      id: `movable-nenewe-${year}`,
      name: 'ጾመ ነነዌ',
      nameEn: 'Fast of Nineveh',
      type: 'FAST',
      category: 'MAJOR_FAST',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.nenewe.startMonth,
      startDay: bh.nenewe.startDay,
      endMonth: bh.nenewe.endMonth,
      endDay: bh.nenewe.endDay,
      durationDays: 3,
      description: 'የነነዌ ሰዎች በነቢዩ ዮናስ ስብከት ንስሐ የገቡበት የ፫ (3) ቀናት ታላቅ ጾም።',
      spiritualMeaning: 'በንስሐ እና በእንባ ወደ እግዚአብሔር በመመለስ ምሕረት የምናገኝበት የበረከት ጾም።',
      fastingRules: 'ከእንስሳት ተዋጽኦ ሙሉ በሙሉ መከልከል፣ እስከ ፱ (9) ሰዓት መጾም እና በጸሎት መትጋት።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-abiy-tsom-${year}`,
      name: 'ዐቢይ ጾም (ሁዳዴ)',
      nameEn: 'Great Lent (Hudadi)',
      type: 'FAST',
      category: 'MAJOR_FAST',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.abiyTsom.startMonth,
      startDay: bh.abiyTsom.startDay,
      endMonth: bh.abiyTsom.endMonth,
      endDay: bh.abiyTsom.endDay,
      durationDays: 55,
      description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ በገዳመ ቆሮንቶስ የጾመው የ፶፭ (55) ቀናት ታላቁ ዐቢይ ጾም።',
      spiritualMeaning: 'የዲያብሎስን ፈተና ድል የነሣበት፣ የጾም እና የጸሎት ቁንጮ የሆነ ታላቅ ጾም። ጾመ ሕርቃል፣ አርብዓ ጾምና ሰሙነ ሕማማትን ያጠቃልላል።',
      fastingRules: 'ከእንስሳት ተዋጽኦ ሙሉ በሙሉ መከልከል፣ በየቀኑ እስከ ቀትር/ምሽት መጾም፣ ስግደትና ምህላ ማድረግ።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-debre-zeyt-${year}`,
      name: 'ደብረ ዘይት',
      nameEn: 'Debre Zeyt (Mount of Olives)',
      type: 'HOLIDAY',
      category: 'MINOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.debreZeyt.month,
      startDay: bh.debreZeyt.day,
      endMonth: bh.debreZeyt.month,
      endDay: bh.debreZeyt.day,
      description: 'የዐቢይ ጾም እኩሌታ (፭ኛው ሰንበት)፤ ጌታችን በደብረ ዘይት ተራራ ስለ ዳግም ምጽአቱ ያስተማረበት ዕለት።',
      spiritualMeaning: 'የጌታችንን ዳግም ምጽአት በማሰብ በንቃትና በጸሎት እንድንዘጋጅ የሚያሳስብ ዕለት።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'SPECIAL',
      isActive: true,
    },
    {
      id: `movable-hosanna-${year}`,
      name: 'ሆሣዕና',
      nameEn: 'Hosanna (Palm Sunday)',
      type: 'HOLIDAY',
      category: 'MAJOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.hosanna.month,
      startDay: bh.hosanna.day,
      endMonth: bh.hosanna.month,
      endDay: bh.hosanna.day,
      description: 'ጌታችን በውርንጫይቱ ላይ ተቀምጦ በክብር ወደ ኢየሩሳሌም የገባበት ታላቅ በዓል።',
      spiritualMeaning: 'ሆሣዕና በአርያም፤ በጌታ ስም የሚመጣ የተባረከ ነው! የድኅነት ድል የታየበት ቀን።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-tselote-hamus-${year}`,
      name: 'ጸሎተ ሐሙስ (ሐሙስ ሕማማት)',
      nameEn: 'Maundy Thursday',
      type: 'HOLIDAY',
      category: 'MAJOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.tseloteHamus.month,
      startDay: bh.tseloteHamus.day,
      endMonth: bh.tseloteHamus.month,
      endDay: bh.tseloteHamus.day,
      description: 'ጌታችን የደቀ መዛሙርቱን እግር ያጠበበት፣ ቅዱስ ቁርባንን የመሠረተበትና በጌቴሴማኒ የጸለየበት ዕለት።',
      spiritualMeaning: 'የፍቅርና የትሕትና ትምህርት የተሰጠበት እና የሕይወት ማዕድ (ምሥጢረ ቁርባን) የተመሠረተበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-siklet-${year}`,
      name: 'ዓርበ ስቅለት (ስቅለት)',
      nameEn: 'Siklet (Good Friday)',
      type: 'FAST',
      category: 'MAJOR_FAST',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.siklet.month,
      startDay: bh.siklet.day,
      endMonth: bh.siklet.month,
      endDay: bh.siklet.day,
      description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ ስለ ሰው ልጅ ድኅነት በመስቀል ላይ የተሰቀለበት ታላቅ ዕለት።',
      spiritualMeaning: 'በደሙ የታተመ የዘላለም ድኅነት የተሰጠንበት እና ሞት በመስቀል ሞት የተሻረበት ዕለት።',
      fastingRules: 'እስከ ምሽት ጥብቅ ጾም፣ ስግደትና የሕማማት ንባባት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-kedam-seur-${year}`,
      name: 'ቀዳም ስዑር (የትንሣኤ ዋዜማ)',
      nameEn: 'Holy Saturday (Eve of Easter)',
      type: 'FAST',
      category: 'MAJOR_FAST',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.kedamSeur.month,
      startDay: bh.kedamSeur.day,
      endMonth: bh.kedamSeur.month,
      endDay: bh.kedamSeur.day,
      description: 'ጌታችን በሥጋው በመቃብር ሲያርፍ በነፍሱ ወደ ሲኦል ወርዶ ምርኮኞችን ነፃ ያወጣበት ቅዳሜ።',
      spiritualMeaning: 'በዓመቱ ውስጥ የሚጾመው ብቸኛው ቅዳሜ፤ ወደ ሲኦል የወረደውን ብርሃን በማሰብ ይጾማል።',
      fastingRules: 'እስከ ምሽተ ትንሣኤ የሚጾም ቅዳሜ።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'SPECIAL',
      isActive: true,
    },
    {
      id: `movable-fasika-${year}`,
      name: 'ትንሣኤ (ፋሲካ)',
      nameEn: 'Fasika (Ethiopian Easter)',
      type: 'HOLIDAY',
      category: 'MAJOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.fasika.month,
      startDay: bh.fasika.day,
      endMonth: bh.fasika.month,
      endDay: bh.fasika.day,
      description: 'ጌታችንና መድኃኒታችን ኢየሱስ ክርስቶስ ሞትን ድል አድርጎ የተነሣበት የትንሣኤ ታላቅ በዓል።',
      spiritualMeaning: 'ክርስቶስ ተንሥአ እሙታን! በሞቱ ሞትን ሻረው፤ ለሙታንም ሕይወትን ሰጠ! የሕይወት እና የድል በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-rikbe-kahnat-${year}`,
      name: 'ርክበ ካህናት',
      nameEn: 'Rikbe Kahnat (Council of Priests)',
      type: 'HOLIDAY',
      category: 'MINOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.rikbeKahnat.month,
      startDay: bh.rikbeKahnat.day,
      endMonth: bh.rikbeKahnat.month,
      endDay: bh.rikbeKahnat.day,
      description: 'ከትንሣኤ በ፳፭ኛው ቀን የሚከበር፤ ሐዋርያት የተሰበሰቡበት እና የካህናት ጉባኤ መታሰቢያ።',
      spiritualMeaning: 'የቤተ ክርስቲያን አንድነትና የክህነት አገልግሎት በረከት።',
      primaryColor: '#DC2626',
      isMajor: false,
      importance: 'NORMAL',
      isActive: true,
    },
    {
      id: `movable-erget-${year}`,
      name: 'ዕርገት',
      nameEn: 'Erget (Ascension)',
      type: 'HOLIDAY',
      category: 'MAJOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.erget.month,
      startDay: bh.erget.day,
      endMonth: bh.erget.month,
      endDay: bh.erget.day,
      description: 'ጌታችን ከትንሣኤው በ፵ኛው (40th) ቀን በክብር ወደ ሰማይ ያረገበት ታላቅ በዓል።',
      spiritualMeaning: 'የሰው ልጅ ተፈጥሮ ወደ ሰማያዊው ክብር ከፍ ማለቱን የምናከብርበት በዓል።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-peraklitos-${year}`,
      name: 'ጰራቅሊጦስ (በዓለ ኀምሳ)',
      nameEn: 'Pentecost (Paraclete)',
      type: 'HOLIDAY',
      category: 'MAJOR_HOLIDAY',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.peraklitos.month,
      startDay: bh.peraklitos.day,
      endMonth: bh.peraklitos.month,
      endDay: bh.peraklitos.day,
      description: 'መንፈስ ቅዱስ በእሳት አምሳል በሐዋርያት ላይ የወረደበት እና ቤተ ክርስቲያን የተመሠረተችበት በዓል።',
      spiritualMeaning: 'የመንፈስ ቅዱስ ስጦታዎች የተሰጡበት እና የወንጌል አገልግሎት የተጀመረበት ዕለት።',
      primaryColor: '#DC2626',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
    {
      id: `movable-apostles-fast-${year}`,
      name: 'ጾመ ሐዋርያት (የሰኔ ጾም)',
      nameEn: 'Fast of the Apostles',
      type: 'FAST',
      category: 'MAJOR_FAST',
      isRecurring: false,
      ethiopianYear: year,
      startMonth: bh.apostlesFast.startMonth,
      startDay: bh.apostlesFast.startDay,
      endMonth: bh.apostlesFast.endMonth,
      endDay: bh.apostlesFast.endDay,
      durationDays: bh.apostlesFast.durationDays,
      description: `ሐዋርያት መንፈስ ቅዱስን ከተቀበሉ በኋላ ለወንጌል አገልግሎት ከመሰማራታቸው በፊት የጾሙት የ${bh.apostlesFast.durationDays} ቀናት ጾም። እስከ ሐምሌ ፭ (ቅዱሳን ጴጥሮስ ወጳውሎስ) ይጾማል።`,
      spiritualMeaning: 'የሐዋርያትን አርአያ በመከተል ለእግዚአብሔር መንግሥት አገልግሎት የምንተጋበት ጾም።',
      fastingRules: 'ከእንስሳት ተዋጽኦ መከልከል፣ በየቀኑ እስከ ፱ (9) ሰዓት መጾም።',
      primaryColor: '#F59E0B',
      isMajor: true,
      importance: 'MAJOR',
      isActive: true,
    },
  ];
}
