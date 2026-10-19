// lib/features/books/data/repositories/book_download_service.dart
// Handles actual file downloading, progress tracking, validation,
// and local file management for offline reading.

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/downloaded_books_dao.dart';
import 'package:mobile/core/storage/web_download_helper.dart';
import '../models/book_model.dart';

/// Result of a download attempt
class DownloadResult {
  final bool success;
  final String? localPath;
  final String? error;
  const DownloadResult.ok(this.localPath)
      : success = true,
        error = null;
  const DownloadResult.err(this.error)
      : success = false,
        localPath = null;
}

class BookDownloadService {
  final Dio _dio;
  final AppDatabase _db;

  /// Active CancelTokens keyed by bookId. Used to cancel in-progress downloads.
  final Map<String, CancelToken> _activeTokens = {};

  BookDownloadService(this._dio, this._db);

  DownloadedBooksDao get _dao => _db.downloadedBooksDao;

  /// Returns the directory where book content files are stored.
  Future<Directory> _getBooksDir() async {
    if (kIsWeb) throw UnsupportedError('Offline download not supported on web');
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/zikre_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Returns the local file path for a given bookId
  Future<String> _localPath(String bookId, String extension) async {
    final dir = await _getBooksDir();
    return '${dir.path}/$bookId.$extension';
  }

  /// Derive extension from mimeType / format
  String _extensionFor(String? mimeType, BookFormat format) {
    if (mimeType != null) {
      if (mimeType.contains('pdf')) return 'pdf';
      if (mimeType.contains('epub')) return 'epub';
      if (mimeType.contains('text')) return 'txt';
    }
    switch (format) {
      case BookFormat.pdf: return 'pdf';
      case BookFormat.epub: return 'epub';
      case BookFormat.text: return 'txt';
      case BookFormat.audio: return 'mp3';
      default: return 'bin';
    }
  }

  /// Starts a download for a book. Returns a stream of progress (0.0–1.0).
  /// Callers should handle the returned Future for completion status.
  Future<DownloadResult> downloadBook({
    required BookModel book,
    required String userId,
    required String contentUrl,
    required String? mimeType,
    required int? expectedBytes,
    void Function(double progress, int downloaded)? onProgress,
  }) async {
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
            final effectiveTotal =
                total > 0 ? total : (expectedBytes ?? received);
            final progress =
                effectiveTotal > 0 ? received / effectiveTotal : 0.0;
            onProgress?.call(progress.clamp(0.0, 1.0), received);
          },
        );

        _activeTokens.remove(book.id);

        if (response.data == null || response.data!.isEmpty) {
          return const DownloadResult.err('Downloaded file is empty or missing');
        }

        final ext = _extensionFor(mimeType, book.format);
        final safeTitle = book.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
        final filename = '${safeTitle.isNotEmpty ? safeTitle : 'book'}.$ext';

        WebDownloadHelper.triggerBrowserSaveOnly(
          bytes: response.data!,
          filename: filename,
        );

        // Record in local Drift db on web
        try {
          await _dao.upsertRecord(LocalDownloadedBooksCompanion.insert(
            bookId: book.id,
            userId: userId,
            title: book.title,
            titleAm: Value(book.titleAm),
            coverUrl: Value(book.coverUrl),
            author: Value(book.author),
            format: book.format.name.toUpperCase(),
            pageCount: Value(book.pageCount),
            status: const Value('completed'),
            progress: const Value(1.0),
            expectedBytes: Value(expectedBytes ?? response.data!.length),
            contentVersion: Value(book.updatedAt.toIso8601String()),
            localContentPath: Value(contentUrl),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } catch (_) {}

        return DownloadResult.ok(contentUrl);
      } on DioException catch (e) {
        _activeTokens.remove(book.id);
        if (e.type == DioExceptionType.cancel) {
          return const DownloadResult.err('Download cancelled');
        }
        final msg = e.message ?? 'Network error during download';
        return DownloadResult.err(msg);
      } catch (e) {
        _activeTokens.remove(book.id);
        return DownloadResult.err(e.toString());
      }
    }

    // Prevent duplicate concurrent downloads
    if (_activeTokens.containsKey(book.id)) {
      return const DownloadResult.err('Download already in progress');
    }

    final token = CancelToken();
    _activeTokens[book.id] = token;

    final ext = _extensionFor(mimeType, book.format);
    final tempPath = await _localPath('${book.id}_tmp', ext);
    final finalPath = await _localPath(book.id, ext);

    try {
      // Mark as downloading
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

      await _dio.download(
        contentUrl,
        tempPath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          final effectiveTotal =
              total > 0 ? total : (expectedBytes ?? received);
          final progress =
              effectiveTotal > 0 ? received / effectiveTotal : 0.0;
          onProgress?.call(progress.clamp(0.0, 1.0), received);
          _dao.updateProgress(book.id, userId, progress.clamp(0.0, 1.0), received);
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
        ),
      );

      // Validate: ensure file exists and is non-empty
      final tempFile = File(tempPath);
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        await _dao.markFailed(book.id, userId, 'Downloaded file is empty or missing');
        return const DownloadResult.err('Downloaded file is empty or missing');
      }

      // Calculate checksum
      final bytes = await tempFile.readAsBytes();
      final checksum = md5.convert(bytes).toString();

      // Move temp → final location atomically
      await tempFile.rename(finalPath);

      await _dao.markCompleted(book.id, userId, finalPath, checksum);
      _activeTokens.remove(book.id);
      return DownloadResult.ok(finalPath);
    } on DioException catch (e) {
      _activeTokens.remove(book.id);
      // Clean up temp file
      try { await File(tempPath).delete(); } catch (_) {}

      if (e.type == DioExceptionType.cancel) {
        await _dao.markCancelled(book.id, userId);
        return const DownloadResult.err('Download cancelled');
      }
      final msg = e.message ?? 'Network error during download';
      await _dao.markFailed(book.id, userId, msg);
      return DownloadResult.err(msg);
    } catch (e) {
      _activeTokens.remove(book.id);
      try { await File(tempPath).delete(); } catch (_) {}
      await _dao.markFailed(book.id, userId, e.toString());
      return DownloadResult.err(e.toString());
    }
  }

  /// Cancel an active download
  Future<void> cancelDownload(String bookId, String userId) async {
    _activeTokens[bookId]?.cancel('User cancelled');
    _activeTokens.remove(bookId);
    await _dao.markCancelled(bookId, userId);
  }

  /// Remove a downloaded book's local files and database record
  Future<void> removeDownload(String bookId, String userId) async {
    final record = await _dao.getRecord(bookId, userId);
    if (!kIsWeb && record != null && record.localContentPath != null) {
      try {
        final f = File(record.localContentPath!);
        if (await f.exists()) await f.delete();
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
