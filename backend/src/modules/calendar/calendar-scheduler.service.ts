// src/modules/calendar/calendar-scheduler.service.ts
import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { CalendarPublicationService } from './calendar-publication.service.js';
import { getEthiopianDate } from './calendar-ethiopian.util.js';

@Injectable()
export class CalendarSchedulerService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CalendarSchedulerService.name);
  private timer: NodeJS.Timeout | null = null;
  private isProcessing = false;
  private testClock: Date | null = null;

  // Track the last publication date processed to avoid re-triggering during the same minute
  private lastMonthlyProcessedDate: string | null = null;
  private lastAnnualProcessedDate: string | null = null;

  constructor(
    private readonly publicationService: CalendarPublicationService,
  ) {}

  onModuleInit() {
    this.logger.log('Initializing Calendar Automated Publication Scheduler (Africa/Addis_Ababa)...');

    // Check immediately on startup for overdue recovery
    this.runTick().catch((err) => {
      this.logger.error('Error during initial calendar publication recovery check', err);
    });

    // Run tick every 60 seconds
    this.timer = setInterval(() => {
      this.runTick().catch((err) => {
        this.logger.error('Error during calendar scheduler tick', err);
      });
    }, 60 * 1000);

    this.logger.log('Calendar Automated Publication Scheduler active (60s tick interval)');
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  // ─── Injectable Test Clock (Requirement 12) ───────────────────────────────

  setTestClock(date: Date) {
    this.testClock = date;
    this.logger.log(`[CalendarScheduler] Test clock set to: ${date.toISOString()}`);
  }

  resetTestClock() {
    this.testClock = null;
    this.logger.log('[CalendarScheduler] Test clock reset to wall-clock time');
  }

  private getCurrentDate(): Date {
    return this.testClock ? new Date(this.testClock) : new Date();
  }

  // ─── Main Scheduler Tick ──────────────────────────────────────────────────

  async runTick(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;

    try {
      const now = this.getCurrentDate();
      const ethNow = getEthiopianDate(now);

      const hour = ethNow.hour;
      const minute = ethNow.minute;
      const dateKey = `${ethNow.year}-${ethNow.month}-${ethNow.day}`;

      // ─── 1. Monthly Publication at 12:00 PM Africa/Addis_Ababa ───────────
      // Triggers at 12:00 or recovers overdue if hour >= 12 and not yet processed today
      const isMonthlyTime = hour === 12 && minute >= 0 && minute < 10;
      const isMonthlyOverdue = hour > 12;

      if ((isMonthlyTime || isMonthlyOverdue) && this.lastMonthlyProcessedDate !== dateKey) {
        this.logger.log(
          `[CalendarScheduler] Triggering Monthly Feast Publication for Ethiopian date ${dateKey} (local time: ${hour}:${minute})`,
        );
        await this.publicationService.publishDueMonthlyFeasts(now);
        this.lastMonthlyProcessedDate = dateKey;
      }

      // ─── 2. Annual Publication at 12:10 PM Africa/Addis_Ababa ────────────
      // Triggers at 12:10 or recovers overdue if hour > 12 or (hour === 12 && minute >= 10)
      const isAnnualTime = (hour === 12 && minute >= 10) || hour > 12;

      if (isAnnualTime && this.lastAnnualProcessedDate !== dateKey) {
        this.logger.log(
          `[CalendarScheduler] Triggering Annual Feast Publication for Ethiopian date ${dateKey} (local time: ${hour}:${minute})`,
        );
        await this.publicationService.publishDueAnnualFeasts(now);
        this.lastAnnualProcessedDate = dateKey;
      }
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Manually trigger monthly publication check immediately (e.g. for testing/admin).
   */
  async triggerMonthlyNow(date?: Date) {
    return this.publicationService.publishDueMonthlyFeasts(date ?? this.getCurrentDate());
  }

  /**
   * Manually trigger annual publication check immediately (e.g. for testing/admin).
   */
  async triggerAnnualNow(date?: Date) {
    return this.publicationService.publishDueAnnualFeasts(date ?? this.getCurrentDate());
  }
}
