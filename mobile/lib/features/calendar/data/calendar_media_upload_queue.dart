import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/calendar/data/calendar_media_service.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum UploadStatus { pending, uploading, done, failed }

class UploadQueueItem {
  final String id; // unique ID for this queue item
  final String localPath;
  final String noteId;
  final int order;
  final UploadStatus status;
  final double progress; // 0.0 – 1.0
  final String? errorMessage;
  final String? uploadedFileId; // set when status == done

  const UploadQueueItem({
    required this.id,
    required this.localPath,
    required this.noteId,
    required this.order,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.uploadedFileId,
  });

  UploadQueueItem copyWith({
    UploadStatus? status,
    double? progress,
    String? errorMessage,
    String? uploadedFileId,
  }) {
    return UploadQueueItem(
      id: id,
      localPath: localPath,
      noteId: noteId,
      order: order,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedFileId: uploadedFileId ?? this.uploadedFileId,
    );
  }
}

class MediaUploadQueueNotifier extends StateNotifier<List<UploadQueueItem>> {
  final CalendarMediaService _mediaService;
  final Ref _ref;
  bool _isProcessing = false;

  MediaUploadQueueNotifier(this._mediaService, this._ref) : super([]);

  /// Enqueue a new media upload and immediately start processing.
  Future<void> enqueue({
    required String localPath,
    required String noteId,
    required int order,
  }) async {
    final item = UploadQueueItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_$order',
      localPath: localPath,
      noteId: noteId,
      order: order,
    );
    state = [...state, item];
    await _processQueue();
  }

  /// Enqueue multiple files at once.
  Future<void> enqueueAll({
    required List<String> localPaths,
    required String noteId,
    int startOrder = 0,
  }) async {
    final newItems = localPaths.asMap().entries.map((e) {
      return UploadQueueItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${startOrder + e.key}',
        localPath: e.value,
        noteId: noteId,
        order: startOrder + e.key,
      );
    }).toList();

    state = [...state, ...newItems];
    await _processQueue();
  }

  /// Retry all failed items.
  Future<void> retryFailed() async {
    state = state.map((item) {
      if (item.status == UploadStatus.failed) {
        return item.copyWith(status: UploadStatus.pending, progress: 0.0);
      }
      return item;
    }).toList();
    await _processQueue();
  }

  /// Remove a completed or failed item from the queue.
  void remove(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Clear all done items.
  void clearCompleted() {
    state = state.where((item) => item.status != UploadStatus.done).toList();
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (true) {
        // Find the next pending item
        final pendingIndex = state.indexWhere(
          (item) => item.status == UploadStatus.pending,
        );
        if (pendingIndex == -1) break;

        final item = state[pendingIndex];
        _updateItem(item.id, item.copyWith(status: UploadStatus.uploading));

        try {
          // Check connectivity before uploading
          final connectivity = await Connectivity().checkConnectivity();
          if (connectivity.contains(ConnectivityResult.none)) {
            developer.log(
              '📵 No connectivity — pausing upload queue',
              name: 'MediaUploadQueue',
            );
            _updateItem(
              item.id,
              item.copyWith(
                status: UploadStatus.failed,
                errorMessage: 'No internet connection',
              ),
            );
            break;
          }

          // Upload file
          final fileData = await _mediaService.uploadFile(
            filePath: item.localPath,
            onProgress: (sent, total) {
              if (total > 0) {
                _updateItemProgress(item.id, sent / total);
              }
            },
          );

          final fileId = (fileData['id'] ?? fileData['fileId']) as String?;
          if (fileId == null) {
            throw Exception('Upload response missing file id: $fileData');
          }

          // Attach to note remotely if online
          try {
            await _mediaService.addMediaToNote(
              noteId: item.noteId,
              fileId: fileId,
              order: item.order,
            );
          } catch (e) {
            developer.log(
              '⚠️ Remote addMediaToNote warning: $e',
              name: 'MediaUploadQueue',
              error: e,
            );
          }

          // Also save media locally so it shows immediately in UI
          try {
            await _ref.read(calendarOfflineRepositoryProvider).addMedia(
              noteId: item.noteId,
              fileId: fileId,
              order: item.order,
              fileUrl: fileData['url'] as String?,
              fileName: fileData['fileName'] as String?,
              mimeType: fileData['mimeType'] as String?,
              fileSize: fileData['size'] as int?,
            );
            // Invalidate providers to refresh UI with new media
            _ref.invalidate(calendarNotesForDateProvider);
            _ref.invalidate(calendarNotesForMonthProvider);
          } catch (e) {
            developer.log(
              '⚠️ Local addMedia warning: $e',
              name: 'MediaUploadQueue',
              error: e,
            );
          }

          _updateItem(
            item.id,
            item.copyWith(
              status: UploadStatus.done,
              progress: 1.0,
              uploadedFileId: fileId,
            ),
          );

          developer.log(
            '✅ Uploaded media ${item.localPath} → $fileId',
            name: 'MediaUploadQueue',
          );
        } catch (e) {
          developer.log(
            '❌ Upload failed for ${item.localPath}: $e',
            name: 'MediaUploadQueue',
          );
          _updateItem(
            item.id,
            item.copyWith(
              status: UploadStatus.failed,
              errorMessage: e.toString(),
            ),
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _updateItem(String id, UploadQueueItem updated) {
    state = state.map((item) => item.id == id ? updated : item).toList();
  }

  void _updateItemProgress(String id, double progress) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(progress: progress.clamp(0.0, 1.0));
      }
      return item;
    }).toList();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final mediaUploadQueueProvider =
    StateNotifierProvider<MediaUploadQueueNotifier, List<UploadQueueItem>>(
      (ref) =>
          MediaUploadQueueNotifier(ref.watch(calendarMediaServiceProvider), ref),
    );

/// Convenience: items for a specific note
final noteUploadQueueProvider = Provider.family<List<UploadQueueItem>, String>((
  ref,
  noteId,
) {
  return ref
      .watch(mediaUploadQueueProvider)
      .where((item) => item.noteId == noteId)
      .toList();
});

/// True if any upload for a note is in-progress
final noteUploadingProvider = Provider.family<bool, String>((ref, noteId) {
  final items = ref.watch(noteUploadQueueProvider(noteId));
  return items.any((item) => item.status == UploadStatus.uploading);
});
