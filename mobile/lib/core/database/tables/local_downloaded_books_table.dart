// lib/core/database/tables/local_downloaded_books_table.dart
// Stores download metadata for books downloaded for offline reading.
// Actual content bytes are stored in the app's documents/cache directory;
// this table holds the reference path and integrity metadata only.
import 'package:drift/drift.dart';

/// Download status matching backend/download lifecycle
enum LocalDownloadStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

@DataClassName('LocalDownloadedBookData')
class LocalDownloadedBooks extends Table {
  /// Matches Book.id on the backend
  TextColumn get bookId => text()();

  /// User who downloaded (device-local; one download per user/book)
  TextColumn get userId => text()();

  /// Book title (cached for display without network)
  TextColumn get title => text()();
  TextColumn get titleAm => text().nullable()();

  /// Cover URL (cached for display)
  TextColumn get coverUrl => text().nullable()();

  /// Author
  TextColumn get author => text().nullable()();

  /// Category name
  TextColumn get categoryName => text().nullable()();

  /// Format: PDF | TEXT | AUDIO | EPUB | EXTERNAL_LINK
  TextColumn get format => text()();

  /// Total page count (informational)
  IntColumn get pageCount => integer().nullable()();

  // ── Download state ──────────────────────────────────────────────────────

  /// Status enum stored as string
  TextColumn get status => text().withDefault(const Constant('queued'))();

  /// 0.0–1.0 download progress fraction
  RealColumn get progress => real().withDefault(const Constant(0.0))();

  /// Expected total file size in bytes
  IntColumn get expectedBytes => integer().nullable()();

  /// Bytes received so far
  IntColumn get downloadedBytes => integer().nullable()();

  // ── Local file references ───────────────────────────────────────────────

  /// Absolute path to the downloaded main content file (PDF, etc.)
  /// Null until download completes successfully.
  TextColumn get localContentPath => text().nullable()();

  /// Absolute path to the cached cover image
  TextColumn get localCoverPath => text().nullable()();

  /// SHA-256 or MD5 checksum of content file (for integrity verification)
  TextColumn get contentChecksum => text().nullable()();

  // ── Content versioning ──────────────────────────────────────────────────

  /// The updatedAt timestamp from the Book record at download time.
  /// Used to detect whether the book content has changed server-side.
  TextColumn get contentVersion => text().nullable()();

  // ── Error tracking ──────────────────────────────────────────────────────

  TextColumn get lastError => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  // ── Timestamps ──────────────────────────────────────────────────────────

  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {bookId, userId};
}
