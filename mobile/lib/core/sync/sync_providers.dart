import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/sync/sync_manager.dart';
import 'package:mobile/core/sync/sync_types.dart';

final syncManagerProvider =
    StateNotifierProvider<SyncManager, SyncStatus>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  final connectivity = ref.watch(connectivityProvider.notifier);

  return SyncManager(apiClient, db, connectivity);
});

final syncStatusProvider = Provider<SyncStatus>((ref) {
  return ref.watch(syncManagerProvider);
});

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  if (kIsWeb) return Stream.value(0);
  final db = ref.watch(appDatabaseProvider);
  return db.syncQueueDao.watchPendingCount();
});

