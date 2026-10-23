import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/features/books/data/models/book_model.dart';
import 'package:mobile/features/books/data/repositories/book_download_service.dart';
import 'package:mobile/features/books/data/repositories/books_repository.dart';
import 'package:mobile/features/books/presentation/providers/book_download_settings_provider.dart';
import 'package:mobile/features/books/presentation/providers/books_providers.dart';
import 'package:mobile/features/books/presentation/screens/books_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBooksRepository extends Fake implements BooksRepository {
  final List<BookModel> mockBooks;
  final List<LocalDownloadedBookData> mockDownloads;
  bool shouldThrow;

  MockBooksRepository({
    this.mockBooks = const [],
    List<LocalDownloadedBookData>? mockDownloads,
    this.shouldThrow = false,
  }) : mockDownloads = mockDownloads != null ? List.from(mockDownloads) : [];

  @override
  Future<PaginatedBooks> getBooks({
    String? search,
    String? categoryId,
    String? format,
    String? language,
    String? tag,
    int page = 1,
    int limit = 20,
    String sortBy = 'sortOrder',
    String sortDir = 'asc',
  }) async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return PaginatedBooks(
      items: mockBooks,
      total: mockBooks.length,
      page: page,
      limit: limit,
      totalPages: 1,
      hasNext: false,
    );
  }

  @override
  Stream<List<LocalDownloadedBookData>> watchDownloads(String userId) {
    return Stream.value(mockDownloads);
  }

  @override
  Stream<List<LocalDownloadedBookData>> watchAllDownloads(String userId) {
    return Stream.value(mockDownloads);
  }

  @override
  Future<bool> isDownloaded(String bookId, String userId) async {
    return mockDownloads.any((d) => d.bookId == bookId && d.status == 'completed');
  }

  @override
  Future<void> removeDownload(String bookId, String userId) async {
    mockDownloads.removeWhere((d) => d.bookId == bookId);
  }

  @override
  bool isActiveDownload(String bookId) => false;

  @override
  Future<Map<String, dynamic>> getDownloadInfo(String bookId) async {
    return {
      'contentFile': {
        'url': 'https://res.cloudinary.com/test.pdf',
        'mimeType': 'application/pdf',
        'fileSize': 1024,
      }
    };
  }

  @override
  Future<DownloadResult> startDownload({
    required BookModel book,
    required String userId,
    required String contentUrl,
    BookDownloadDestination destination = BookDownloadDestination.inApp,
    String? mimeType,
    int? expectedBytes,
    void Function(double progress, int bytesReceived)? onProgress,
  }) async {
    final record = LocalDownloadedBookData(
      bookId: book.id,
      userId: userId,
      title: book.title,
      titleAm: book.titleAm,
      author: book.author,
      categoryName: 'General',
      format: 'pdf',
      pageCount: book.pageCount,
      localContentPath: '/storage/books/${book.id}.pdf',
      status: 'completed',
      progress: 1.0,
      retryCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockDownloads.add(record);
    return const DownloadResult.ok('/storage/books/test.pdf');
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
      format: BookFormat.pdf,
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
    );
  }
}

class FakeConnectivity extends Fake implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

class TestConnectivityNotifier extends ConnectivityNotifier {
  TestConnectivityNotifier(ConnectivityState initialState)
      : super(FakeConnectivity()) {
    state = initialState;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testBook = BookModel(
    id: 'book-1',
    title: 'Test Book One',
    titleAm: 'የሙከራ መጽሐፍ አንድ',
    author: 'Author One',
    language: BookLanguage.amharic,
    format: BookFormat.pdf,
    status: BookStatus.published,
    pageCount: 100,
    tags: const [],
    sortOrder: 0,
    viewsCount: 0,
    bookmarksCount: 0,
    chapters: const [],
    attachments: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testDownloadedRecord = LocalDownloadedBookData(
    bookId: 'book-1',
    userId: 'guest',
    title: 'Test Book One',
    titleAm: 'የሙከራ መጽሐፍ አንድ',
    author: 'Author One',
    categoryName: 'General',
    format: 'pdf',
    pageCount: 100,
    localContentPath: '/storage/books/book-1.pdf',
    status: 'completed',
    progress: 1.0,
    retryCount: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('BooksScreen - Online Only Tab & Delete Download Tests', () {
    testWidgets('1. Displays "All Books Downloaded" when online and all available books are downloaded', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [testBook],
        mockDownloads: [testDownloadedRecord],
      );

      final container = ProviderContainer(
        overrides: [
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Online Only tab
      final onlineTabFinder = find.text('Online Only');
      expect(onlineTabFinder, findsOneWidget);
      await tester.tap(onlineTabFinder);
      await tester.pumpAndSettle();

      // Should show "All Books Downloaded" state with Amharic subtitle
      expect(find.text('All Books Downloaded'), findsOneWidget);
      expect(find.text('ሁሉም መጽሐፍት ወርደዋል'), findsOneWidget);
      expect(find.text('Online Books Unavailable'), findsNothing);
      expect(find.text('Go to Downloaded Books (1)'), findsOneWidget);
      expect(find.text('Browse All Books'), findsOneWidget);
    });

    testWidgets('2. Displays "Online Books Unavailable" only when user is genuinely offline or error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [],
        mockDownloads: [testDownloadedRecord],
        shouldThrow: true,
      );

      final container = ProviderContainer(
        overrides: [
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.offline,
              isReachable: false,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Online Only tab
      final onlineTabFinder = find.text('Online Only');
      expect(onlineTabFinder, findsOneWidget);
      await tester.tap(onlineTabFinder);
      await tester.pumpAndSettle();

      // Should show "Online Books Unavailable" because user is offline
      expect(find.text('Online Books Unavailable'), findsOneWidget);
    });

    testWidgets('3. Tapping delete on downloaded book pops up confirmation dialog and removes from local storage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [testBook],
        mockDownloads: [testDownloadedRecord],
      );

      final container = ProviderContainer(
        overrides: [
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go to Downloaded tab
      final downloadedTabFinder = find.widgetWithText(Tab, 'Downloaded');
      expect(downloadedTabFinder, findsOneWidget);
      await tester.tap(downloadedTabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap the delete icon on the downloaded book
      final deleteIconFinder = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIconFinder, findsWidgets);
      await tester.tap(deleteIconFinder.first);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear with the requested text
      expect(find.text('Delete Downloaded Book'), findsOneWidget);
      expect(
        find.textContaining('Do you want to delete "Test Book One" from local storage?'),
        findsOneWidget,
      );

      // Tap Delete from Local Storage
      final confirmDeleteBtn = find.text('Delete from Local Storage');
      expect(confirmDeleteBtn, findsOneWidget);
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Verify repo had its download removed
      expect(repo.mockDownloads.isEmpty, isTrue);

      // Verify dialog is dismissed and BooksScreen remains on screen
      expect(find.text('Delete Downloaded Book'), findsNothing);
      expect(find.byType(BooksScreen), findsOneWidget);
    });

    testWidgets('4. Tapping cancel on delete confirmation dialog closes dialog safely without popping screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [testBook],
        mockDownloads: [testDownloadedRecord],
      );

      final container = ProviderContainer(
        overrides: [
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go to Downloaded tab
      final downloadedTabFinder = find.widgetWithText(Tab, 'Downloaded');
      await tester.tap(downloadedTabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap delete icon to open dialog
      final deleteIconFinder = find.byIcon(Icons.delete_outline_rounded);
      await tester.tap(deleteIconFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Downloaded Book'), findsOneWidget);

      // Tap Cancel
      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Verify dialog is gone, screen is still mounted, download was NOT removed
      expect(find.text('Delete Downloaded Book'), findsNothing);
      expect(find.byType(BooksScreen), findsOneWidget);
      expect(repo.mockDownloads.length, 1);
    });

    testWidgets('5. Filter & Sort sheet immediately highlights selected chip upon tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [testBook],
        mockDownloads: [],
      );

      final container = ProviderContainer(
        overrides: [
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open Filter & Sort sheet
      final filterBtn = find.byIcon(Icons.filter_list);
      expect(filterBtn, findsOneWidget);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort'), findsOneWidget);

      // Tap PDF format chip
      final pdfChipFinder = find.widgetWithText(FilterChip, 'PDF');
      expect(pdfChipFinder, findsOneWidget);
      await tester.tap(pdfChipFinder);
      await tester.pump(); // Immediate frame without pumpAndSettle

      // PDF FilterChip should immediately be selected
      final pdfChipWidget = tester.widget<FilterChip>(pdfChipFinder);
      expect(pdfChipWidget.selected, isTrue);
    });

    testWidgets('6. Finishing a book download immediately changes badge and action icon to Downloaded without requiring refresh', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final repo = MockBooksRepository(
        mockBooks: [testBook],
        mockDownloads: [],
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              user: AuthUser(
                id: 'user-1',
                email: 'test@example.com',
                role: 'USER',
              ),
            ),
          )),
          booksRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: BooksScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, book displays Online badge and cloud download icon
      expect(find.text('Online'), findsOneWidget);
      final downloadBtn = find.byIcon(Icons.cloud_download_outlined);
      expect(downloadBtn, findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

      // Tap download button
      await tester.tap(downloadBtn);
      await tester.pumpAndSettle();

      // Immediately, badge changes to Downloaded (now 2: the Tab + the book badge)
      // and action icon changes to delete icon
      expect(find.text('Downloaded'), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download_outlined), findsNothing);
    });
  });
}
