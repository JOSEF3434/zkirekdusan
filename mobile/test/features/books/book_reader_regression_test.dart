// test/features/books/book_reader_regression_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/books/data/models/book_model.dart';
import 'package:mobile/features/books/data/repositories/books_repository.dart';
import 'package:mobile/features/books/presentation/providers/books_providers.dart';
import 'package:mobile/features/books/presentation/screens/book_reader_screen.dart';

class MockBooksRepository extends Fake implements BooksRepository {
  final BookModel testBook;
  ReadingProgressModel? initialProgress;
  int saveProgressCallCount = 0;
  int updateLastOpenedCallCount = 0;
  Map<String, dynamic>? lastSavedData;
  String? lastUpdatedBookId;
  String? lastUpdatedUserId;
  bool shouldThrowOnSave;
  bool shouldThrowOnUpdateLastOpened;
  bool shouldThrowOnGetBook;
  Completer<void>? delayedSaveCompleter;
  bool downloadedStatus;
  LocalDownloadedBookData? mockDownloadRecord;

  MockBooksRepository({
    required this.testBook,
    this.initialProgress,
    this.downloadedStatus = false,
    this.shouldThrowOnSave = false,
    this.shouldThrowOnUpdateLastOpened = false,
    this.shouldThrowOnGetBook = false,
    this.mockDownloadRecord,
  });

  @override
  Future<BookModel> getBook(
    String id, {
    bool authenticated = false,
    String? userId,
  }) async {
    if (shouldThrowOnGetBook) {
      if (mockDownloadRecord != null &&
          mockDownloadRecord!.status == 'completed') {
        return bookFromDownloadRecord(mockDownloadRecord!);
      }
      throw Exception('SocketException: Failed host lookup: api.example.com');
    }
    return testBook;
  }

  @override
  Future<LocalDownloadedBookData?> getDownloadRecord(
    String bookId,
    String userId,
  ) async {
    return mockDownloadRecord;
  }

  @override
  BookModel bookFromDownloadRecord(LocalDownloadedBookData d) {
    return BookModel(
      id: d.bookId,
      title: d.title,
      titleAm: d.titleAm,
      author: d.author,
      categoryName: d.categoryName,
      language: BookLanguage.amharic,
      format: BookFormat.values.firstWhere(
        (f) => f.name.toUpperCase() == d.format.toUpperCase(),
        orElse: () => BookFormat.pdf,
      ),
      status: BookStatus.published,
      pageCount: d.pageCount,
      tags: const [],
      sortOrder: 0,
      viewsCount: 0,
      bookmarksCount: 0,
      coverUrl: d.coverUrl,
      contentUrl: d.localContentPath,
      chapters: const [],
      attachments: const [],
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      description: 'Downloaded offline book content',
    );
  }

  @override
  Future<ReadingProgressModel> getProgress(String bookId) async {
    return initialProgress ??
        ReadingProgressModel(
          bookId: bookId,
          percentComplete: 0,
          isCompleted: false,
        );
  }

  @override
  Future<ReadingProgressModel> saveProgress(
    String bookId,
    Map<String, dynamic> data,
  ) async {
    saveProgressCallCount++;
    lastSavedData = data;
    if (delayedSaveCompleter != null) {
      await delayedSaveCompleter!.future;
    }
    if (shouldThrowOnSave) {
      throw Exception('Network error during saveProgress');
    }
    return ReadingProgressModel(
      bookId: bookId,
      currentPage: data['currentPage'] as int?,
      percentComplete: (data['percentComplete'] as num?)?.toDouble() ?? 0,
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  @override
  Future<void> updateLastOpened(String bookId, String userId) async {
    updateLastOpenedCallCount++;
    lastUpdatedBookId = bookId;
    lastUpdatedUserId = userId;
    if (shouldThrowOnUpdateLastOpened) {
      throw Exception('Database error during updateLastOpened');
    }
  }

  @override
  Future<bool> isDownloaded(String bookId, String userId) async {
    return downloadedStatus;
  }
}

class MockAuthRepository extends Fake implements AuthRepository {
  final AuthUser? user;
  MockAuthRepository({this.user});

  @override
  Future<String?> getStoredFlag(String key) async => 'false';

  @override
  Future<bool> isAuthenticated() async => user != null;

  @override
  Future<AuthUser?> getCachedUser() async => user;

  @override
  Future<AuthUser> fetchMe() async => user!;

  @override
  Future<void> logout() async {}
}

const testUser = AuthUser(
  id: 'usr-42',
  email: 'reader@example.com',
  username: 'reader',
  role: 'USER',
);

final samplePdfBook = BookModel(
  id: 'book-pdf-1',
  title: 'PDF Reader Test Book',
  format: BookFormat.pdf,
  status: BookStatus.published,
  language: BookLanguage.amharic,
  tags: const [],
  sortOrder: 1,
  viewsCount: 10,
  bookmarksCount: 2,
  contentUrl: 'https://example.com/sample.pdf',
  chapters: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final sampleTextBook = BookModel(
  id: 'book-text-1',
  title: 'Text Reader Test Book',
  description: 'Sample text content for regression testing.',
  format: BookFormat.text,
  status: BookStatus.published,
  language: BookLanguage.amharic,
  tags: const [],
  sortOrder: 1,
  viewsCount: 5,
  bookmarksCount: 1,
  chapters: const [],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget createTestApp({
  required Widget child,
  required MockBooksRepository repo,
  bool isAuthenticated = true,
}) {
  final authRepo = MockAuthRepository(user: isAuthenticated ? testUser : null);

  return ProviderScope(
    overrides: [
      booksRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(authRepo),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('BookReaderScreen - Riverpod Disposal & Lifecycle Safety Regression Tests', () {
    testWidgets(
      '1. Disposing/closing reader widget does NOT throw StateError (Cannot use ref after disposed)',
      (tester) async {
        final repo = MockBooksRepository(testBook: sampleTextBook);

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const BookReaderScreen(bookId: 'book-text-1'),
                    ),
                  );
                },
                child: const Text('Open Reader'),
              ),
            ),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Open reader
        await tester.tap(find.text('Open Reader'));
        await tester.pumpAndSettle();
        expect(find.text('Text Reader Test Book'), findsOneWidget);

        // Now pop the reader (which triggers dispose())
        // In Riverpod 2.x, if dispose() accesses `ref`, this throws `StateError: Cannot use "ref" after the widget was disposed.`
        Navigator.of(tester.element(find.text('Text Reader Test Book'))).pop();
        await tester.pumpAndSettle();

        // Verify it closed cleanly and returned to the initial screen with no crash
        expect(find.text('Open Reader'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Closing reader when unauthenticated does not call saveProgress or updateLastOpened',
      (tester) async {
        final repo = MockBooksRepository(testBook: sampleTextBook);

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-text-1'),
            repo: repo,
            isAuthenticated: false,
          ),
        );
        await tester.pumpAndSettle();

        // Set page and unmount
        final state = tester.state<BookReaderScreenState>(
          find.byType(BookReaderScreen),
        );
        state.setPageForTesting(5, 10);

        // Unmount by pumping a replacement widget
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(repo.saveProgressCallCount, 0);
        expect(repo.updateLastOpenedCallCount, 0);
      },
    );

    testWidgets(
      '3. Saves final page position, accurate percentage, isCompleted, and updates lastOpened upon disposal',
      (tester) async {
        final repo = MockBooksRepository(testBook: sampleTextBook);

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const BookReaderScreen(bookId: 'book-text-1'),
                    ),
                  );
                },
                child: const Text('Open Reader'),
              ),
            ),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Open reader
        await tester.tap(find.text('Open Reader'));
        await tester.pumpAndSettle();

        // Simulate reading up to page 8 out of 10
        final state = tester.state<BookReaderScreenState>(
          find.byType(BookReaderScreen),
        );
        state.setPageForTesting(8, 10);

        // Close reader (pops and disposes)
        Navigator.of(tester.element(find.text('Text Reader Test Book'))).pop();
        await tester.pumpAndSettle();

        // Verify that progress was persisted during disposal
        expect(repo.saveProgressCallCount, 1);
        expect(repo.lastSavedData?['currentPage'], 8);
        expect(repo.lastSavedData?['percentComplete'], 80.0);
        expect(repo.lastSavedData?['isCompleted'], false);

        // Verify lastOpened was updated for the authenticated user
        expect(repo.updateLastOpenedCallCount, 1);
        expect(repo.lastUpdatedBookId, 'book-text-1');
        expect(repo.lastUpdatedUserId, 'usr-42');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. Marks book as completed when final page reaches totalPages',
      (tester) async {
        final repo = MockBooksRepository(testBook: sampleTextBook);

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-text-1'),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<BookReaderScreenState>(
          find.byType(BookReaderScreen),
        );
        state.setPageForTesting(10, 10);
        state.flushFinalProgressForTesting();
        await tester.pumpAndSettle();

        expect(repo.saveProgressCallCount, 1);
        expect(repo.lastSavedData?['currentPage'], 10);
        expect(repo.lastSavedData?['percentComplete'], 100.0);
        expect(repo.lastSavedData?['isCompleted'], true);
      },
    );

    testWidgets('5. Prevents duplicate saves when page has not changed', (
      tester,
    ) async {
      final repo = MockBooksRepository(testBook: sampleTextBook);

      await tester.pumpWidget(
        createTestApp(
          child: const BookReaderScreen(bookId: 'book-text-1'),
          repo: repo,
          isAuthenticated: true,
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<BookReaderScreenState>(
        find.byType(BookReaderScreen),
      );
      state.setPageForTesting(4, 20);

      // First flush
      state.flushFinalProgressForTesting();
      await tester.pumpAndSettle();
      expect(repo.saveProgressCallCount, 1);

      // Second flush with unchanged page
      state.flushFinalProgressForTesting();
      await tester.pumpAndSettle();
      expect(repo.saveProgressCallCount, 1); // Deduplicated!
    });

    testWidgets(
      '6. Navigating away during asynchronous save does not crash or throw unhandled errors',
      (tester) async {
        final repo = MockBooksRepository(
          testBook: sampleTextBook,
          shouldThrowOnSave: true,
          shouldThrowOnUpdateLastOpened: true,
        );

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-text-1'),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<BookReaderScreenState>(
          find.byType(BookReaderScreen),
        );
        state.setPageForTesting(3, 15);

        // Unmount while errors occur in async callbacks
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pumpAndSettle();

        // Handled safely without uncaught exceptions
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7. Delayed async save finishes safely after widget disposal without ref access',
      (tester) async {
        final completer = Completer<void>();
        final repo = MockBooksRepository(testBook: sampleTextBook);
        repo.delayedSaveCompleter = completer;

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-text-1'),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        final state = tester.state<BookReaderScreenState>(
          find.byType(BookReaderScreen),
        );
        state.setPageForTesting(7, 25);

        // Dispose reader widget
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump();

        // Now complete the delayed save in the background
        completer.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(repo.saveProgressCallCount, 1);
        expect(repo.lastSavedData?['currentPage'], 7);
      },
    );
  });

  group('BookReaderScreen - Download Icon Before and After Download', () {
    testWidgets('8. Displays cloud download icon in sky blue before download', (
      tester,
    ) async {
      final repo = MockBooksRepository(
        testBook: sampleTextBook,
        downloadedStatus: false,
      );

      await tester.pumpWidget(
        createTestApp(
          child: const BookReaderScreen(
            bookId: 'book-text-1',
            isDownloaded: false,
          ),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // In Text reader, verify download icon before download
      final downloadIconFinder = find.byIcon(Icons.cloud_download_outlined);
      expect(downloadIconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(downloadIconFinder);
      expect(iconWidget.color, const Color(0xFF38BDF8));

      // Check tooltip
      expect(find.byTooltip('Download for offline reading'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets(
      '9. Displays check circle icon in emerald green after download',
      (tester) async {
        final repo = MockBooksRepository(
          testBook: sampleTextBook,
          downloadedStatus: true,
        );

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(
              bookId: 'book-text-1',
              isDownloaded: true,
            ),
            repo: repo,
          ),
        );
        await tester.pumpAndSettle();

        // In Text reader, verify download icon after download
        final completedIconFinder = find.byIcon(Icons.check_circle_rounded);
        expect(completedIconFinder, findsOneWidget);

        final iconWidget = tester.widget<Icon>(completedIconFinder);
        expect(iconWidget.color, const Color(0xFF059669));

        // Check tooltip
        expect(
          find.byTooltip('Downloaded • Available Offline'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cloud_download_outlined), findsNothing);
      },
    );
  });

  group('BookReaderScreen - Offline Reading & Redirection', () {
    testWidgets(
      '10. Opens downloaded book successfully without network when remote getBook throws SocketException',
      (tester) async {
        final downloadedRecord = LocalDownloadedBookData(
          bookId: 'book-text-offline-1',
          userId: 'usr-42',
          title: 'Offline Downloaded Book',
          titleAm: 'የወረደ መጽሐፍ',
          author: 'St. Author',
          categoryName: 'Spiritual',
          format: 'TEXT',
          status: 'completed',
          progress: 1.0,
          retryCount: 0,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          localContentPath: null,
        );

        final repo = MockBooksRepository(
          testBook: sampleTextBook,
          shouldThrowOnGetBook: true,
          mockDownloadRecord: downloadedRecord,
        );

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-text-offline-1'),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Ensure no crash occurred and reader opened with title from download record
        expect(tester.takeException(), isNull);
        expect(find.text('Offline Downloaded Book'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Displays error screen with Go to Downloaded Books action button when undownloaded book is opened offline',
      (tester) async {
        final repo = MockBooksRepository(
          testBook: sampleTextBook,
          shouldThrowOnGetBook: true,
          mockDownloadRecord: null, // Not downloaded
        );

        await tester.pumpWidget(
          createTestApp(
            child: const BookReaderScreen(bookId: 'book-undownloaded-1'),
            repo: repo,
            isAuthenticated: true,
          ),
        );
        await tester.pumpAndSettle();

        // Displays error message and Go to Downloaded Books button
        expect(find.textContaining('Failed host lookup'), findsOneWidget);
        expect(find.text('Go to Downloaded Books'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      },
    );
  });
}
