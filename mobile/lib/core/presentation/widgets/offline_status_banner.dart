// lib/core/presentation/widgets/offline_status_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/sync/sync_providers.dart';
import 'package:mobile/core/sync/sync_types.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;

    final isOffline = connectivity.isOffline;
    final isSyncing = connectivity.isOnline && syncStatus == SyncStatus.syncing;
    final isSuccess = connectivity.isOnline && syncStatus == SyncStatus.success;

    final isVisible = isOffline || isSyncing || isSuccess;

    Color backgroundColor;
    Widget content;

    if (isOffline) {
      backgroundColor = const Color(0xFF2C2518); // Elegant dark amber
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFFFFB300)),
          const SizedBox(width: 6),
          Text(
            pendingCount > 0
                ? 'Offline • $pendingCount changes pending sync'
                : 'Offline Mode • Viewing cached content',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFFE082),
            ),
          ),
        ],
      );
    } else if (isSyncing) {
      backgroundColor = const Color(0xFF132238); // Dark blue
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Syncing with server...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF90CAF9),
            ),
          ),
        ],
      );
    } else if (isSuccess) {
      backgroundColor = const Color(0xFF142B1B); // Dark green
      content = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF81C784)),
          SizedBox(width: 6),
          Text(
            'Synced with server',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA5D6A7),
            ),
          ),
        ],
      );
    } else {
      backgroundColor = Colors.transparent;
      content = const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: isVisible ? 26 : 0,
      color: backgroundColor,
      alignment: Alignment.center,
      child: isVisible ? content : null,
    );
  }
}
