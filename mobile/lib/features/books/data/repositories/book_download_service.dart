// lib/features/books/data/repositories/book_download_service.dart
// Handles file downloading, progress tracking, validation,
// and multi-destination local file management (In-App, Device File Manager, Both)
// across Android, Windows/Desktop, Web, and iOS.

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/downloaded_books_dao.dart';
import 'package:mobile/core/storage/web_download_helper.dart';
import '../models/book_download_setting_model.dart';
import '../models/book_model.dart';

/// Result of a download attempt across destinations
class DownloadResult {
  final bool success;
  final String? localPath;
  final String? externalPath;
  final String? error;
  final bool inAppSuccess;
  final bool externalSuccess;
  final bool isPartial;

  const DownloadResult.ok(this.localPath)
      : success = true,
        error = null,
        externalPath = null,
        inAppSuccess = true,
        externalSuccess = false,
        isPartial = false;

  const DownloadResult.externalOk(this.externalPath)
      : success = true,
        error = null,
        localPath = null,
        inAppSuccess = false,
        externalSuccess = true,
        isPartial = false;

  const DownloadResult.bothOk({
    required this.localPath,
    required this.externalPath,
  })  : success = true,
        error = null,
        inAppSuccess = true,
        externalSuccess = true,
        isPartial = false;

  const DownloadResult.partial({
    this.localPath,
    this.externalPath,
    required this.error,
    this.inAppSuccess = false,
    this.externalSuccess = false,
  })  : success = false,
        isPartial = true;

  const DownloadResult.err(this.error)
      : success = false,
        localPath = null,
        externalPath = null,
        inAppSuccess = false,
        externalSuccess = false,
        isPartial = false;
}

class BookDownloadService {
  final Dio _dio;
  final AppDatabase _db;

  /// Active CancelTokens keyed by bookId. Used to cancel in-progress downloads.
  final Map<String, CancelToken> _activeTokens = {};

  BookDownloadService(this._dio, this._db);

  DownloadedBooksDao get _dao => _db.downloadedBooksDao;

  /// Returns the in-app managed storage directory where books are kept offline.
  Future<Directory> _getBooksDir() async {
    if (kIsWeb) throw UnsupportedError('Local filesystem directory not supported on web');
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/zikre_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the local file path for in-app storage
  Future<String> _localPath(String bookId, String extension) async {
    final dir = await _getBooksDir();
    return '${dir.path}/$bookId.$extension';
  }

  /// Returns user-accessible device destination directory for the current platform
  Future<Directory> _getDeviceDownloadsDir() async {
    if (kIsWeb) throw UnsupportedError('File manager directory not supported on web');

    // 1. Desktop (Windows, macOS, Linux)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final d = await getDownloadsDirectory();
        if (d != null) {
          final target = Directory('${d.path}/ZikreBooks');
          if (!await target.exists()) await target.create(recursive: true);
          return target;
        }
      } catch (_) {}
    }

    // 2. Android
    if (Platform.isAndroid) {
      // Primary public downloads location on Android
      try {
        final publicDownload = Directory('/storage/emulated/0/Download/ZikreBooks');
        if (!await publicDownload.exists()) {
          await publicDownload.create(recursive: true);
        }
        return publicDownload;
      } catch (_) {
        // Fallback to app external storage
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            final target = Directory('${ext.path}/ZikreBooks');
            if (!await target.exists()) await target.create(recursive: true);
            return target;
          }
        } catch (_) {}
      }
    }

    // 3. iOS or generic fallback
    final base = await getApplicationDocumentsDirectory();
    final target = Directory('${base.path}/ZikreBooks');
    if (!await target.exists()) await target.create(recursive: true);
    return target;
  }

  /// Derive extension from mimeType / format
  String _extensionFor(String? mimeType, BookFormat format) {
    if (mimeType != null) {
      if (mimeType.contains('pdf')) return 'pdf';
      if (mimeType.contains('epub')) return 'epub';
      if (mimeType.contains('text')) return 'txt';
      if (mimeType.contains('audio')) return 'mp3';
    }
    switch (format) {
      case BookFormat.pdf:
        return 'pdf';
      case BookFormat.epub:
        return 'epub';
      case BookFormat.text:
        return 'txt';
      case BookFormat.audio:
        return 'mp3';
      default:
        return 'bin';
    }
  }

  String _sanitizeFileName(String title, String ext) {
    final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safeTitle.isNotEmpty ? safeTitle : 'book'}.$ext';
  }

  /// Starts a download for a book respecting the configured download destination.
  /// Options:
  /// - `inApp`: Saved to application's managed internal offline storage.
  /// - `deviceFileManager`: Saved to user-accessible device Downloads location.
  /// - `both`: Saved in-app AND exported to device Downloads location.
  Future<DownloadResult> downloadBook({
    required BookModel book,
    required String userId,
    required String contentUrl,
    required String? mimeType,
    required int? expectedBytes,
    BookDownloadDestination destination = BookDownloadDestination.inApp,
    void Function(double progress, int downloaded)? onProgress,
  }) async {
    // ── Web Handling ────────────────────────────────────────────────────────
    if (kIsWeb) {
      if (_activeTokens.containsKey(book.id)) {
        return const DownloadResult.err('Download already in progress');
      }

      final token = CancelToken();
      _activeTokens[book.id] = token;

      try {
        final response = await _dio.get<List<int>>(
          contentUrl,
          cancelToken: token,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 30),
          ),
          onReceiveProgress: (received, total) {
            final effectiveTotal = total > 0 ? total : (expectedBytes ?? received);
            final progress = effectiveTotal > 0 ? received / effectiveTotal : 0.0;
            onProgress?.call(progress.clamp(0.0, 1.0), received);
          },
        );

        _activeTokens.remove(book.id);

        if (response.data == null || response.data!.isEmpty) {
          return const DownloadResult.err('Downloaded file is empty or missing');
        }

        final ext = _extensionFor(mimeType, book.format);
        final filename = _sanitizeFileName(book.title, ext);

        // For deviceFileManager or both: trigger browser save dialog
        if (destination == BookDownloadDestination.deviceFileManager ||
            destination == BookDownloadDestination.both) {
          WebDownloadHelper.triggerBrowserSaveOnly(
            bytes: response.data!,
            filename: filename,
          );
        }

        // Always record in local DB (Drift / Web store) so downloaded books appear in the app
        final effectiveUserId = userId.isNotEmpty ? userId : 'guest';
        try {
          await _dao.upsertRecord(LocalDownloadedBooksCompanion.insert(
            bookId: book.id,
            userId: effectiveUserId,
            title: book.title,
            titleAm: Value(book.titleAm),
            coverUrl: Value(book.coverUrl),
            author: Value(book.author),
            categoryName: Value(book.categoryName),
            format: book.format.name.toUpperCase(),
            pageCount: Value(book.pageCount),
            status: const Value('completed'),
            progress: const Value(1.0),
            expectedBytes: Value(expectedBytes ?? response.data!.length),
            contentVersion: Value(book.updatedAt.toIso8601String()),
            localContentPath: Value(contentUrl),
            downloadedAt: Value(DateTime.now()),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (e) {
          debugPrint('[BookDownloadService] Web download DB upsert error: $e');
        }

        if (destination == BookDownloadDestination.deviceFileManager) {
          return DownloadResult.externalOk(filename);
        } else if (destination == BookDownloadDestination.both) {
          return DownloadResult.bothOk(localPath: contentUrl, externalPath: filename);
        } else {
          return DownloadResult.ok(contentUrl);
        }
      } on DioException catch (e) {
        _activeTokens.remove(book.id);
        if (e.type == DioExceptionType.cancel) {
          return const DownloadResult.err('Download cancelled');
        }
        return DownloadResult.err(e.message ?? 'Network error during download');
      } catch (e) {
        _activeTokens.remove(book.id);
        return DownloadResult.err(e.toString());
      }
    }

    // ── Native (Android / Windows / iOS / Desktop) ──────────────────────────
    if (_activeTokens.containsKey(book.id)) {
      return const DownloadResult.err('Download already in progress');
    }

    final token = CancelToken();
    _activeTokens[book.id] = token;

    final ext = _extensionFor(mimeType, book.format);
    final filename = _sanitizeFileName(book.title, ext);
    final inAppFinalPath = await _localPath(book.id, ext);
    final tempPath = await _localPath('${book.id}_tmp', ext);

    try {
      // Record download intent in local DB
      await _dao.upsertRecord(LocalDownloadedBooksCompanion.insert(
        bookId: book.id,
        userId: userId,
        title: book.title,
        titleAm: Value(book.titleAm),
        coverUrl: Value(book.coverUrl),
        author: Value(book.author),
        format: book.format.name.toUpperCase(),
        pageCount: Value(book.pageCount),
        status: const Value('downloading'),
        progress: const Value(0.0),
        expectedBytes: Value(expectedBytes),
        contentVersion: Value(book.updatedAt.toIso8601String()),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 1. Download file once over network into temp path
      await _dio.download(
        contentUrl,
        tempPath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          final effectiveTotal = total > 0 ? total : (expectedBytes ?? received);
          final progress = effectiveTotal > 0 ? received / effectiveTotal : 0.0;
          onProgress?.call(progress.clamp(0.0, 1.0), received);
          _dao.updateProgress(book.id, userId, progress.clamp(0.0, 1.0), received);
        },
        options: Options(receiveTimeout: const Duration(minutes: 30)),
      );

      final tempFile = File(tempPath);
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        await _dao.markFailed(book.id, userId, 'Downloaded file is empty or missing');
        _activeTokens.remove(book.id);
        return const DownloadResult.err('Downloaded file is empty or missing');
      }

      // Checksum for validation
      final bytes = await tempFile.readAsBytes();
      final checksum = md5.convert(bytes).toString();

      // 2. Route based on destination
      if (destination == BookDownloadDestination.inApp) {
        // Option A: In-App Only
        await tempFile.rename(inAppFinalPath);
        await _dao.markCompleted(book.id, userId, inAppFinalPath, checksum);
        _activeTokens.remove(book.id);
        return DownloadResult.ok(inAppFinalPath);
      } else if (destination == BookDownloadDestination.deviceFileManager) {
        // Option B: Device File Manager Only
        final deviceDir = await _getDeviceDownloadsDir();
        final externalFilePath = '${deviceDir.path}/$filename';

        await tempFile.copy(externalFilePath);
        try {
          await tempFile.delete();
        } catch (_) {}

        // Still record in DB so app knows user downloaded it, referencing external path
        await _dao.markCompleted(book.id, userId, externalFilePath, checksum);
        _activeTokens.remove(book.id);
        return DownloadResult.externalOk(externalFilePath);
      } else {
        // Option C: Both (In-App + Device File Manager)
        // Move to in-app final path first
        await tempFile.rename(inAppFinalPath);
        await _dao.markCompleted(book.id, userId, inAppFinalPath, checksum);

        // Now copy to device file manager
        String? externalFilePath;
        bool externalSuccess = false;
        String? externalError;

        try {
          final deviceDir = await _getDeviceDownloadsDir();
          externalFilePath = '${deviceDir.path}/$filename';
          await File(inAppFinalPath).copy(externalFilePath);
          externalSuccess = true;
        } catch (e) {
          externalError = 'Failed to copy to device Downloads: $e';
        }

        _activeTokens.remove(book.id);

        if (externalSuccess && externalFilePath != null) {
          return DownloadResult.bothOk(
            localPath: inAppFinalPath,
            externalPath: externalFilePath,
          );
        } else {
          // Report partial result: in-app succeeded, external failed
          return DownloadResult.partial(
            localPath: inAppFinalPath,
            inAppSuccess: true,
            externalSuccess: false,
            error: externalError ?? 'Failed to export to device file manager',
          );
        }
      }
    } on DioException catch (e) {
      _activeTokens.remove(book.id);
      try {
        await File(tempPath).delete();
      } catch (_) {}

      if (e.type == DioExceptionType.cancel) {
        await _dao.markCancelled(book.id, userId);
        return const DownloadResult.err('Download cancelled');
      }
      final msg = e.message ?? 'Network error during download';
      await _dao.markFailed(book.id, userId, msg);
      return DownloadResult.err(msg);
    } catch (e) {
      _activeTokens.remove(book.id);
      try {
        await File(tempPath).delete();
      } catch (_) {}
      await _dao.markFailed(book.id, userId, e.toString());
      return DownloadResult.err(e.toString());
    }
  }

  /// Exports an existing in-app downloaded book to the device file manager (retry mechanism).
  Future<DownloadResult> exportInAppToDevice(BookModel book, String userId) async {
    final record = await _dao.getRecord(book.id, userId);
    if (record == null || record.localContentPath == null) {
      return const DownloadResult.err('In-app book file not found');
    }

    final inAppFile = File(record.localContentPath!);
    if (!await inAppFile.exists()) {
      return const DownloadResult.err('Local file is missing on storage');
    }

    try {
      final ext = _extensionFor(null, book.format);
      final filename = _sanitizeFileName(book.title, ext);
      final deviceDir = await _getDeviceDownloadsDir();
      final externalFilePath = '${deviceDir.path}/$filename';

      await inAppFile.copy(externalFilePath);
      return DownloadResult.bothOk(
        localPath: record.localContentPath,
        externalPath: externalFilePath,
      );
    } catch (e) {
      return DownloadResult.partial(
        localPath: record.localContentPath,
        inAppSuccess: true,
        externalSuccess: false,
        error: 'Export to device failed: $e',
      );
    }
  }

  /// Opens downloaded file using native OS registered viewer
  static Future<OpenResult> openDownloadedFile(String filePath) async {
    return OpenFilex.open(filePath);
  }

  /// Shares downloaded file via OS share sheet
  static Future<void> shareDownloadedFile(String filePath, {String? subject}) async {
    await Share.shareXFiles([XFile(filePath)], subject: subject);
  }

  /// Cancel an active download
  Future<void> cancelDownload(String bookId, String userId) async {
    _activeTokens[bookId]?.cancel('User cancelled');
    _activeTokens.remove(bookId);
    await _dao.markCancelled(bookId, userId);
  }

  /// Remove a downloaded book's in-app local files and database record.
  /// Note: removing from in-app library MUST NOT silently delete a user-managed external copy.
  Future<void> removeDownload(String bookId, String userId) async {
    final record = await _dao.getRecord(bookId, userId);
    if (!kIsWeb && record != null && record.localContentPath != null) {
      try {
        final path = record.localContentPath!;
        // Only delete if it resides inside app's private zikre_books directory
        if (path.contains('zikre_books')) {
          final f = File(path);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
    }
    await _dao.deleteRecord(bookId, userId);
  }

  /// Verify a downloaded file still exists and checksum matches
  Future<bool> verifyDownload(String bookId, String userId) async {
    final record = await _dao.getRecord(bookId, userId);
    if (record == null || record.localContentPath == null) return false;
    if (record.status != 'completed') return false;

    if (kIsWeb) return true;

    final file = File(record.localContentPath!);
    if (!await file.exists()) return false;

    if (record.contentChecksum != null) {
      final bytes = await file.readAsBytes();
      final actual = md5.convert(bytes).toString();
      if (actual != record.contentChecksum) return false;
    }

    // Update verification timestamp
    await _db.downloadedBooksDao.upsertRecord(
      LocalDownloadedBooksCompanion(
        bookId: Value(bookId),
        userId: Value(userId),
        lastVerifiedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return true;
  }

  bool isActiveDownload(String bookId) => _activeTokens.containsKey(bookId);
}
