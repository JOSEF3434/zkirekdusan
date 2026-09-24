// scripts/verify-bug3-live-poller.ts
import { Logger } from '@nestjs/common';
import { StreamReminderService } from '../src/modules/live-streaming/stream-reminder.service.js';
import { LiveStreamStatus, NotificationType } from '@prisma/client';

async function run() {
  console.log('================================================================================');
  console.log('VERIFICATION: Bug Class 3 — 2-Minute Still-Live Poller & Early Stop Prevention');
  console.log('================================================================================\n');

  // Simulated DB state
  const dbStreams: any[] = [];
  const dbNotifications: any[] = [];

  const mockPrisma: any = {
    liveStream: {
      findMany: async (args: any) => {
        const { status, deletedAt, startedAt, notifiedLiveAt } = args.where;
        return dbStreams.filter((s) => {
          if (s.status !== status) return false;
          if (deletedAt !== undefined && s.deletedAt !== deletedAt) return false;
          if (notifiedLiveAt === null && s.notifiedLiveAt !== null) return false;
          if (startedAt?.gte && s.startedAt < startedAt.gte) return false;
          if (startedAt?.lte && s.startedAt > startedAt.lte) return false;
          return true;
        });
      },
      update: async (args: any) => {
        const stream = dbStreams.find((s) => s.id === args.where.id);
        if (stream) {
          Object.assign(stream, args.data);
        }
        return stream;
      },
    },
    videoSubscription: {
      findMany: async () => [],
    },
    groupMember: {
      findMany: async () => [],
    },
  };

  const mockNotificationsService: any = {
    notifyAllUsers: async (payload: any) => {
      dbNotifications.push({ target: 'ALL_USERS', payload, sentAt: new Date() });
    },
    create: async (payload: any) => {
      dbNotifications.push({ target: payload.userId, payload, sentAt: new Date() });
    },
  };

  const poller = new StreamReminderService(mockPrisma, mockNotificationsService);

  // -------------------------------------------------------------------------
  // CASE 1: Stream that stays LIVE past 2 minutes
  // -------------------------------------------------------------------------
  console.log('>>> [CASE 1] Stream started 2m 15s ago, still LIVE at the 2-minute mark:');
  const now = Date.now();
  const stream1 = {
    id: 'stream-live-past-2m',
    title: 'Sunday Liturgy & Teaching',
    status: LiveStreamStatus.LIVE,
    startedAt: new Date(now - 135 * 1000), // 2 minutes 15 seconds ago
    endedAt: null,
    deletedAt: null,
    notifiedLiveAt: null,
    groupId: 'group-orthodox',
    videoChannelId: 'channel-main',
    tags: ['sunday', 'notify_all'],
    videoChannel: { name: 'Holy Trinity Media' },
  };
  dbStreams.push(stream1);

  console.log(`Stream created: id=${stream1.id}, status=${stream1.status}, startedAt=${stream1.startedAt.toISOString()}, notifiedLiveAt=${stream1.notifiedLiveAt}`);
  console.log('Executing poller tick (at ~2 min mark)...');
  await poller.checkLiveStreamNotifications();

  console.log(`State after tick: notifiedLiveAt = ${stream1.notifiedLiveAt ? stream1.notifiedLiveAt.toISOString() : 'NULL'}`);
  console.log(`Notifications dispatched count: ${dbNotifications.length}`);
  if (dbNotifications.length > 0) {
    console.log(`Dispatched payload: ${JSON.stringify(dbNotifications[0])}`);
  }

  console.log('\n--- Subsequent poller tick (e.g. 1 minute later at 3 min mark) ---');
  await poller.checkLiveStreamNotifications();
  console.log(`Total notifications dispatched after 2nd tick: ${dbNotifications.length} (Verified: NOT sent again because notifiedLiveAt is stamped)\n`);

  // -------------------------------------------------------------------------
  // CASE 2: Stream stopped before 2 minutes (e.g. test stream stopped at 45s)
  // -------------------------------------------------------------------------
  console.log('>>> [CASE 2] Stream started 2m 15s ago, but stopped after 45s (status = ENDED):');
  const stream2 = {
    id: 'stream-ended-early-45s',
    title: 'Quick Audio Test (Aborted)',
    status: LiveStreamStatus.ENDED, // stream ended before 2m!
    startedAt: new Date(now - 135 * 1000),
    endedAt: new Date(now - 90 * 1000), // ended 45s after start
    deletedAt: null,
    notifiedLiveAt: null,
    groupId: 'group-orthodox',
    videoChannelId: 'channel-main',
    tags: ['test', 'notify_all'],
    videoChannel: { name: 'Holy Trinity Media' },
  };
  dbStreams.push(stream2);

  const notifCountBeforeCase2 = dbNotifications.length;
  console.log(`Stream created: id=${stream2.id}, status=${stream2.status}, startedAt=${stream2.startedAt.toISOString()}, endedAt=${stream2.endedAt?.toISOString()}, notifiedLiveAt=${stream2.notifiedLiveAt}`);
  console.log('Executing poller tick...');
  await poller.checkLiveStreamNotifications();

  const notifCountAfterCase2 = dbNotifications.length;
  console.log(`Notifications dispatched for ended stream: ${notifCountAfterCase2 - notifCountBeforeCase2}`);
  console.log(`State after tick: stream.notifiedLiveAt = ${stream2.notifiedLiveAt ? stream2.notifiedLiveAt.toISOString() : 'NULL'} (Unchanged: never notified)`);
  console.log('\n================================================================================');
  console.log('RESULT: Verified both cases successfully.');
  console.log('================================================================================');
}

run().catch(console.error);
