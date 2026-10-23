// test/core/database/concurrency_regression_test.dart
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Concurrency & FeedDao Batch Transaction Tests', () {
    test(
      'upsertFeedItems atomically caches feed items in a single transaction',
      () async {
        final now = DateTime.now();
        final items = List.generate(
          5,
          (i) => LocalFeedItemsCompanion(
            id: drift.Value('item_$i'),
            feedType: const drift.Value('LATEST'),
            title: drift.Value('Video $i'),
            authorDisplayName: const drift.Value('Author'),
            createdAt: drift.Value(now),
            cachedAt: drift.Value(now),
            publishedAt: drift.Value(now),
          ),
        );

        await db.feedDao.upsertFeedItems(items);

        final cached = await db.feedDao.getFeedItems(feedType: 'LATEST');
        expect(cached.length, equals(5));
        expect(
          cached.map((e) => e.id).toList(),
          containsAll(['item_0', 'item_1', 'item_2', 'item_3', 'item_4']),
        );
      },
    );

    test(
      'upsertFeedItems with empty list is a safe no-op that preserves existing cache',
      () async {
        final now = DateTime.now();
        final items = [
          LocalFeedItemsCompanion(
            id: const drift.Value('preserve_1'),
            feedType: const drift.Value('LATEST'),
            title: const drift.Value('Preserved Video'),
            authorDisplayName: const drift.Value('Author'),
            createdAt: drift.Value(now),
            cachedAt: drift.Value(now),
            publishedAt: drift.Value(now),
          ),
        ];

        await db.feedDao.upsertFeedItems(items);
        expect(
          (await db.feedDao.getFeedItems(feedType: 'LATEST')).length,
          equals(1),
        );

        // Attempt empty upsert
        await db.feedDao.upsertFeedItems([]);

        // Preserved because empty list returns early
        final after = await db.feedDao.getFeedItems(feedType: 'LATEST');
        expect(after.length, equals(1));
        expect(after.first.id, equals('preserve_1'));
      },
    );

    test(
      'Simultaneous concurrent writes do not cause corruption or deadlock',
      () async {
        final now = DateTime.now();

        // Launch multiple overlapping operations simultaneously
        final future1 = db.feedDao.upsertFeedItems(
          List.generate(
            10,
            (i) => LocalFeedItemsCompanion(
              id: drift.Value('latest_$i'),
              feedType: const drift.Value('LATEST'),
              title: drift.Value('Latest Video $i'),
              createdAt: drift.Value(now),
              cachedAt: drift.Value(now),
            ),
          ),
        );

        final future2 = db.feedDao.upsertFeedItems(
          List.generate(
            8,
            (i) => LocalFeedItemsCompanion(
              id: drift.Value('trending_$i'),
              feedType: const drift.Value('TRENDING'),
              title: drift.Value('Trending Video $i'),
              createdAt: drift.Value(now),
              cachedAt: drift.Value(now),
            ),
          ),
        );

        final future3 = db.videosDao.upsertVideo(
          LocalVideosCompanion(
            id: const drift.Value('concurrent_vid_1'),
            title: const drift.Value('Concurrent Video'),
            createdAt: drift.Value(now),
          ),
        );

        // Await all concurrent operations
        await Future.wait<dynamic>([future1, future2, future3]);

        final latest = await db.feedDao.getFeedItems(feedType: 'LATEST');
        final trending = await db.feedDao.getFeedItems(feedType: 'TRENDING');
        final video = await db.videosDao.getVideoById('concurrent_vid_1');

        expect(latest.length, equals(10));
        expect(trending.length, equals(8));
        expect(video, isNotNull);
        expect(video!.title, equals('Concurrent Video'));
      },
    );
  });
}
