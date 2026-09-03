// lib/core/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/users_dao.dart';
import 'package:mobile/core/database/daos/videos_dao.dart';
import 'package:mobile/core/database/daos/conversations_dao.dart';
import 'package:mobile/core/database/daos/messages_dao.dart';
import 'package:mobile/core/database/daos/watch_history_dao.dart';
import 'package:mobile/core/database/daos/sync_queue_dao.dart';
import 'package:mobile/core/database/daos/feed_dao.dart';
import 'package:mobile/core/database/daos/search_history_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final usersDaoProvider = Provider<UsersDao>((ref) {
  return ref.watch(appDatabaseProvider).usersDao;
});

final videosDaoProvider = Provider<VideosDao>((ref) {
  return ref.watch(appDatabaseProvider).videosDao;
});

final conversationsDaoProvider = Provider<ConversationsDao>((ref) {
  return ref.watch(appDatabaseProvider).conversationsDao;
});

final messagesDaoProvider = Provider<MessagesDao>((ref) {
  return ref.watch(appDatabaseProvider).messagesDao;
});

final watchHistoryDaoProvider = Provider<WatchHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).watchHistoryDao;
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  return ref.watch(appDatabaseProvider).syncQueueDao;
});

final feedDaoProvider = Provider<FeedDao>((ref) {
  return ref.watch(appDatabaseProvider).feedDao;
});

final searchHistoryDaoProvider = Provider<SearchHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).searchHistoryDao;
});
