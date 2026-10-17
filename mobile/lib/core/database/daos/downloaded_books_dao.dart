// lib/core/database/daos/downloaded_books_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_downloaded_books_table.dart';

part 'downloaded_books_dao.g.dart';

@DriftAccessor(tables: [LocalDownloadedBooks])
class DownloadedBooksDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadedBooksDaoMixin {
  DownloadedBooksDao(super.db);

  /// All completed downloads for a user
  Stream<List<LocalDownloadedBookData>> watchDownloaded(String userId) {
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('completed')))
        .watch();
  }

  /// All downloads (any status) for a user
  Stream<List<LocalDownloadedBookData>> watchAll(String userId) {
    return (select(localDownloadedBooks)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  /// Active downloads (queued or downloading) for a user
  Stream<List<LocalDownloadedBookData>> watchActive(String userId) {
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.status.equals('queued') | t.status.equals('downloading'))))
        .watch();
  }

  Future<LocalDownloadedBookData?> getRecord(
      String bookId, String userId) {
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<bool> isDownloaded(String bookId, String userId) async {
    final record = await getRecord(bookId, userId);
    return record != null &&
        record.status == 'completed' &&
        record.localContentPath != null;
  }

  Future<void> upsertRecord(LocalDownloadedBooksCompanion record) async {
    await into(localDownloadedBooks).insertOnConflictUpdate(record);
  }

  Future<void> updateProgress(
      String bookId, String userId, double progress, int downloadedBytes) {
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          progress: Value(progress),
          downloadedBytes: Value(downloadedBytes),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markCompleted(
      String bookId, String userId, String localPath, String? checksum) {
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('completed'),
          progress: const Value(1.0),
          localContentPath: Value(localPath),
          contentChecksum: Value(checksum),
          downloadedAt: Value(DateTime.now()),
          lastVerifiedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markFailed(String bookId, String userId, String error) {
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('failed'),
          lastError: Value(error),
          retryCount: Value(0), // Will be incremented by caller
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markCancelled(String bookId, String userId) {
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> updateLastOpened(String bookId, String userId) {
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          lastOpenedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<int> deleteRecord(String bookId, String userId) {
    return (delete(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .go();
  }

  Future<List<LocalDownloadedBookData>> getAllCompleted(String userId) {
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.desc(t.downloadedAt)]))
        .get();
  }
}
