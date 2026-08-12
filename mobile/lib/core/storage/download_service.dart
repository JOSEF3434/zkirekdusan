// lib/core/storage/download_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DownloadMetadata {
  final String videoId;
  final String title;
  final String localPath;
  final String? thumbnailUrl;
  final int sizeBytes;

  DownloadMetadata({
    required this.videoId,
    required this.title,
    required this.localPath,
    this.thumbnailUrl,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'localPath': localPath,
    'thumbnailUrl': thumbnailUrl,
    'sizeBytes': sizeBytes,
  };

  factory DownloadMetadata.fromJson(Map<String, dynamic> json) =>
      DownloadMetadata(
        videoId: json['videoId'],
        title: json['title'],
        localPath: json['localPath'],
        thumbnailUrl: json['thumbnailUrl'],
        sizeBytes: json['sizeBytes'] ?? 0,
      );
}

class DownloadState {
  final Map<String, DownloadMetadata> downloads;
  final Map<String, double> progress;
  final Map<String, String> errors;
  final Set<String> downloading;

  const DownloadState({
    this.downloads = const {},
    this.progress = const {},
    this.errors = const {},
    this.downloading = const {},
  });

  DownloadState copyWith({
    Map<String, DownloadMetadata>? downloads,
    Map<String, double>? progress,
    Map<String, String>? errors,
    Set<String>? downloading,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      progress: progress ?? this.progress,
      errors: errors ?? this.errors,
      downloading: downloading ?? this.downloading,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  final StorageService _storage;
  final Dio _dio;
  static const _kDownloadsKey = 'offline_downloads';

  DownloadNotifier(this._storage, this._dio) : super(const DownloadState()) {
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final data = await _storage.getToken(key: _kDownloadsKey);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        final Map<String, DownloadMetadata> downloads = {};
        decoded.forEach((key, value) {
          downloads[key] = DownloadMetadata.fromJson(value);
        });
        state = state.copyWith(downloads: downloads);
      } catch (e) {
        // Ignore corrupted metadata
      }
    }
  }

  Future<void> _saveMetadata() async {
    final Map<String, dynamic> map = {};
    state.downloads.forEach((key, value) {
      map[key] = value.toJson();
    });
    await _storage.saveToken(jsonEncode(map), key: _kDownloadsKey);
  }

  Future<void> startDownload({
    required String videoId,
    required String url,
    required String title,
    String? thumbnailUrl,
  }) async {
    if (state.downloading.contains(videoId) ||
        state.downloads.containsKey(videoId)) {
      return;
    }

    try {
      state = state.copyWith(
        downloading: {...state.downloading, videoId},
        progress: {...state.progress, videoId: 0.0},
        errors: {...state.errors}..remove(videoId),
      );

      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/video_$videoId.mp4';
      final file = File(localPath);

      await _dio.download(
        url,
        localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final p = received / total;
            state = state.copyWith(progress: {...state.progress, videoId: p});
          }
        },
      );

      final size = await file.length();

      final metadata = DownloadMetadata(
        videoId: videoId,
        title: title,
        localPath: localPath,
        thumbnailUrl: thumbnailUrl,
        sizeBytes: size,
      );

      state = state.copyWith(
        downloading: {...state.downloading}..remove(videoId),
        progress: {...state.progress}..remove(videoId),
        downloads: {...state.downloads, videoId: metadata},
      );

      await _saveMetadata();
    } catch (e) {
      state = state.copyWith(
        downloading: {...state.downloading}..remove(videoId),
        progress: {...state.progress}..remove(videoId),
        errors: {...state.errors, videoId: e.toString()},
      );
    }
  }

  Future<void> deleteDownload(String videoId) async {
    final meta = state.downloads[videoId];
    if (meta != null) {
      try {
        final file = File(meta.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      final newDownloads = Map<String, DownloadMetadata>.from(state.downloads)
        ..remove(videoId);
      state = state.copyWith(downloads: newDownloads);
      await _saveMetadata();
    }
  }
}

final downloadServiceProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
      final dio =
          Dio(); // Clean dio instance without auth interceptors for raw file downloads
      return DownloadNotifier(ref.watch(storageServiceProvider), dio);
    });
