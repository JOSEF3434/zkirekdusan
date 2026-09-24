// src/modules/live-streaming/stream-reminder.service.ts
import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';
import { LiveStreamStatus, NotificationType } from '@prisma/client';

@Injectable()
export class StreamReminderService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(StreamReminderService.name);
  private timer: NodeJS.Timeout | null = null;
  private isProcessing = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  onModuleInit() {
    // Run both reminder checks every 60 seconds.
    this.timer = setInterval(() => {
      this.checkScheduledReminders().catch((err) => {
        this.logger.error('Error during scheduled stream reminders check', err);
      });
      this.checkLiveStreamNotifications().catch((err) => {
        this.logger.error('Error during live stream notification check', err);
      });
    }, 60 * 1000);
    this.logger.log('Scheduled live stream reminder service initialized (60s tick)');
  }

  onModuleDestroy() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  // ─── Pre-start scheduled reminders (existing logic, unchanged) ─────────────

  async checkScheduledReminders() {
    if (this.isProcessing) return;
    this.isProcessing = true;

    try {
      const now = new Date();
      // Fetch scheduled streams starting in the next 25 hours
      const maxFuture = new Date(now.getTime() + 25 * 60 * 60 * 1000);

      const streams = await this.prisma.liveStream.findMany({
        where: {
          status: LiveStreamStatus.SCHEDULED,
          deletedAt: null,
          scheduledAt: {
            gte: now,
            lte: maxFuture,
          },
        },
        include: {
          videoChannel: { select: { id: true, name: true } },
          group: { select: { id: true, name: true } },
        },
      });

      for (const stream of streams) {
        if (!stream.scheduledAt) continue;

        const diffMs = stream.scheduledAt.getTime() - now.getTime();
        const diffMinutes = Math.floor(diffMs / (60 * 1000));
        const tags = stream.tags || [];

        // 1 Day (24 hours: 1410 - 1470 minutes)
        if (diffMinutes >= 1410 && diffMinutes <= 1470 && !tags.includes('reminded_24h')) {
          await this.dispatchReminder(
            stream,
            'reminded_24h',
            `📅 Live Stream in 1 Day: ${stream.title}`,
            `"${stream.title}" on ${stream.videoChannel?.name ?? 'Live'} starts in 24 hours!`,
          );
        }
        // 5 Hours (285 - 315 minutes)
        else if (diffMinutes >= 285 && diffMinutes <= 315 && !tags.includes('reminded_5h')) {
          await this.dispatchReminder(
            stream,
            'reminded_5h',
            `⏰ Live Stream in 5 Hours: ${stream.title}`,
            `"${stream.title}" starts in 5 hours. Don't miss it!`,
          );
        }
        // 1 Hour (55 - 65 minutes)
        else if (diffMinutes >= 55 && diffMinutes <= 65 && !tags.includes('reminded_1h')) {
          await this.dispatchReminder(
            stream,
            'reminded_1h',
            `🔔 Starting in 1 Hour: ${stream.title}`,
            `"${stream.title}" begins in 1 hour!`,
          );
        }
        // 30 Minutes (25 - 35 minutes)
        else if (diffMinutes >= 25 && diffMinutes <= 35 && !tags.includes('reminded_30m')) {
          await this.dispatchReminder(
            stream,
            'reminded_30m',
            `⏳ Starting in 30 Minutes: ${stream.title}`,
            `"${stream.title}" starts in 30 minutes. Join the stream room now!`,
          );
        }
      }
    } finally {
      this.isProcessing = false;
    }
  }

  // ─── 2-minute still-live notification poller (new) ─────────────────────────

  /**
   * Fires the follower/subscriber "stream is live" notification only after the
   * stream has been actively LIVE for ≥ 2 minutes.
   *
   * Design decisions:
   *  - Window is [2 min, 3 min] past startedAt. At 60 s tick granularity the
   *    poller sees the window within one tick cycle.
   *  - `notifiedLiveAt IS NULL` is the idempotency guard — we stamp it in the
   *    same DB write as part of the notification dispatch, so a Render dyno
   *    restart cannot cause a duplicate send.
   *  - If the stream ends before the 2-minute window arrives, its status is
   *    no longer LIVE so the WHERE clause naturally excludes it — no extra check
   *    needed.
   */
  async checkLiveStreamNotifications() {
    const now = new Date();
    // [2 min ago, 3 min ago] window
    const twoMinutesAgo = new Date(now.getTime() - 2 * 60 * 1000);
    const threeMinutesAgo = new Date(now.getTime() - 3 * 60 * 1000);

    let streams: Array<{
      id: string;
      title: string;
      groupId: string;
      videoChannelId: string;
      tags: string[];
      videoChannel: { name: string } | null;
    }>;

    try {
      streams = await this.prisma.liveStream.findMany({
        where: {
          status: LiveStreamStatus.LIVE,
          deletedAt: null,
          startedAt: {
            // startedAt is between 3 min ago and 2 min ago
            gte: threeMinutesAgo,
            lte: twoMinutesAgo,
          },
          notifiedLiveAt: null, // not yet notified
        },
        select: {
          id: true,
          title: true,
          groupId: true,
          videoChannelId: true,
          tags: true,
          videoChannel: { select: { name: true } },
        },
      });
    } catch (err) {
      this.logger.error('[LivePoller] Failed to query live streams', err);
      return;
    }

    if (streams.length === 0) return;

    this.logger.log(
      `[LivePoller] Found ${streams.length} stream(s) that have been LIVE for ~2 minutes. Dispatching notifications.`,
    );

    for (const stream of streams) {
      try {
        await this.dispatchLiveNotification(stream);
      } catch (err) {
        this.logger.error(
          `[LivePoller] Failed to dispatch live notification for stream ${stream.id}`,
          err,
        );
      }
    }
  }

  private async dispatchLiveNotification(stream: {
    id: string;
    title: string;
    groupId: string;
    videoChannelId: string;
    tags: string[];
    videoChannel: { name: string } | null;
  }) {
    const channelName = stream.videoChannel?.name ?? 'Creator';
    const title = `🔴 ${channelName} is LIVE NOW!`;
    const body = `"${stream.title}" is streaming live. Tap to join now!`;
    const notifyAll = stream.tags.includes('notify_all');
    const notificationData = {
      streamId: stream.id,
      action: 'LIVE_STREAM_STARTED',
    };

    // ── Stamp notifiedLiveAt FIRST so the column is set even if
    //    notification delivery partially fails (avoids double-dispatch).
    await this.prisma.liveStream.update({
      where: { id: stream.id },
      data: { notifiedLiveAt: new Date() },
    });

    if (notifyAll) {
      await this.notificationsService.notifyAllUsers({
        title,
        body,
        type: NotificationType.SYSTEM,
        data: notificationData,
      });
      this.logger.log(
        `[LivePoller] Dispatched live notification to ALL users for stream ${stream.id}`,
      );
      return;
    }

    // Scoped: channel subscribers + group members
    const [subscribers, members] = await Promise.all([
      this.prisma.videoSubscription.findMany({
        where: { videoChannelId: stream.videoChannelId },
        select: { userId: true },
      }),
      this.prisma.groupMember.findMany({
        where: { groupId: stream.groupId },
        select: { userId: true },
      }),
    ]);

    const targetUserIds = Array.from(
      new Set([
        ...subscribers.map((s) => s.userId),
        ...members.map((m) => m.userId),
      ]),
    );

    for (const userId of targetUserIds) {
      await this.notificationsService
        .create({
          userId,
          type: NotificationType.SYSTEM,
          title,
          body,
          data: notificationData,
        })
        .catch(() => null);
    }

    this.logger.log(
      `[LivePoller] Dispatched live notification to ${targetUserIds.length} followers/members for stream ${stream.id}`,
    );
  }

  // ─── Pre-start scheduled-reminder helpers (existing, unchanged) ────────────

  private async dispatchReminder(
    stream: any,
    tagFlag: string,
    title: string,
    body: string,
  ) {
    try {
      // 1. Tag the stream so we don't send duplicate reminders
      const currentTags = stream.tags || [];
      const updatedTags = [...currentTags, tagFlag];

      await this.prisma.liveStream.update({
        where: { id: stream.id },
        data: { tags: updatedTags },
      });

      const notifyAll = currentTags.includes('notify_all');

      if (notifyAll) {
        // Broadcast to all users in the database
        await this.notificationsService.notifyAllUsers({
          title,
          body,
          type: NotificationType.SYSTEM,
          data: {
            streamId: stream.id,
            action: 'LIVE_STREAM_REMINDER',
            scheduledAt: stream.scheduledAt?.toISOString(),
          },
        });
        this.logger.log(`Dispatched ${tagFlag} reminder for stream ${stream.id} to ALL users`);
      } else {
        // Scoped to followers of the channel & group members
        const subscribers = await this.prisma.videoSubscription.findMany({
          where: { videoChannelId: stream.videoChannelId },
          select: { userId: true },
        });

        const members = await this.prisma.groupMember.findMany({
          where: { groupId: stream.groupId },
          select: { userId: true },
        });

        const targetUserIds = Array.from(
          new Set([
            ...subscribers.map((s) => s.userId),
            ...members.map((m) => m.userId),
          ]),
        );

        for (const userId of targetUserIds) {
          await this.notificationsService
            .create({
              userId,
              type: NotificationType.SYSTEM,
              title,
              body,
              data: {
                streamId: stream.id,
                action: 'LIVE_STREAM_REMINDER',
                scheduledAt: stream.scheduledAt?.toISOString(),
              },
            })
            .catch(() => null);
        }

        this.logger.log(
          `Dispatched ${tagFlag} reminder for stream ${stream.id} to ${targetUserIds.length} followers/members`,
        );
      }
    } catch (err) {
      this.logger.error(`Failed to dispatch ${tagFlag} for stream ${stream.id}`, err);
    }
  }
}
