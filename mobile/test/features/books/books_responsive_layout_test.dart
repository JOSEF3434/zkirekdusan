// test/features/books/books_responsive_layout_test.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/books/data/models/book_category_model.dart';
import 'package:mobile/features/books/data/models/book_model.dart';
import 'package:mobile/features/books/data/repositories/books_repository.dart';
import 'package:mobile/features/books/presentation/providers/books_providers.dart';
import 'package:mobile/features/books/presentation/screens/book_detail_screen.dart';
import 'package:mobile/features/books/presentation/screens/books_screen.dart';
import 'package:mobile/features/library/presentation/library_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthState(status: AuthStatus.unauthenticated));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectivity extends Fake implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => const Stream.empty();
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];
}

class _TestConnectivityNotifier extends ConnectivityNotifier {
  _TestConnectivityNotifier(ConnectivityState initialState)
      : super(_FakeConnectivity()) {
    state = initialState;
  }
}

class _FakeBooksRepository extends Fake implements BooksRepository {
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
    return PaginatedBooks(
      items: [
        BookModel(
          id: 'b1',
          title: 'Test Book Title',
          categoryName: 'General',
          language: BookLanguage.amharic,
          format: BookFormat.pdf,
          status: BookStatus.published,
          tags: const [],
          sortOrder: 0,
          viewsCount: 0,
          bookmarksCount: 0,
          chapters: const [],
          attachments: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      total: 1,
      page: 1,
      limit: 20,
      totalPages: 1,
      hasNext: false,
    );
  }

  @override
  Future<List<BookCategoryModel>> getCategories() async => [];

  @override
  Stream<List<LocalDownloadedBookData>> watchDownloads(String userId) => Stream.value([]);

  @override
  Stream<List<LocalDownloadedBookData>> watchAllDownloads(String userId) => Stream.value([]);
}

void main() {
  Widget buildApp(Widget home) {
    return ProviderScope(
      overrides: [
        trProvider.overrideWithValue((key, [args]) => key),
        authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        booksRepositoryProvider.overrideWithValue(_FakeBooksRepository()),
        connectivityProvider.overrideWith(
          (ref) => _TestConnectivityNotifier(
            const ConnectivityState(
              status: ConnectivityStatus.online,
              isReachable: true,
            ),
          ),
        ),
        bookCategoriesProvider.overrideWith((ref) async => <BookCategoryModel>[]),
      ],
      child: MaterialApp(home: home),
    );
  }

  testWidgets('BooksScreen applies responsive max reading width on large displays (1920x1080)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const BooksScreen()));
    await tester.pumpAndSettle();

    // Verify BooksScreen renders
    expect(find.byType(BooksScreen), findsOneWidget);

    // Verify NestedScrollView is bounded to maxWidth <= 1200 on a 1920px screen
    final nestedScrollViewFinder = find.byType(NestedScrollView);
    expect(nestedScrollViewFinder, findsOneWidget);
    final size = tester.getSize(nestedScrollViewFinder);
    expect(size.width, lessThanOrEqualTo(1200));
    expect(size.width, greaterThan(800));
  });

  testWidgets('LibraryScreen applies responsive max reading width on large displays (1920x1080)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildApp(const LibraryScreen()));
    await tester.pumpAndSettle();

    // Verify LibraryScreen renders
    expect(find.byType(LibraryScreen), findsOneWidget);

    // Verify ListView is bounded to maxWidth <= 800 on a 1920px screen
    final listViewFinder = find.byType(ListView);
    expect(listViewFinder, findsOneWidget);
    final size = tester.getSize(listViewFinder);
    expect(size.width, lessThanOrEqualTo(800));
  });

  testWidgets(
      'BookDetailScreen applies responsive max reading width on large displays (1920x1080) without hiding body',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final testBook = BookModel(
      id: 'b1',
      title: 'Detailed Test Book',
      categoryName: 'Theology',
      language: BookLanguage.amharic,
      format: BookFormat.pdf,
      status: BookStatus.published,
      contentUrl: 'https://example.com/book.pdf',
      tags: const [],
      sortOrder: 0,
      viewsCount: 0,
      bookmarksCount: 0,
      chapters: const [],
      attachments: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trProvider.overrideWithValue((key, [args]) => key),
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          booksRepositoryProvider.overrideWithValue(_FakeBooksRepository()),
          connectivityProvider.overrideWith(
            (ref) => _TestConnectivityNotifier(
              const ConnectivityState(
                status: ConnectivityStatus.online,
                isReachable: true,
              ),
            ),
          ),
          bookDetailProvider('b1').overrideWith((ref) async => testBook),
        ],
        child: const MaterialApp(home: BookDetailScreen(bookId: 'b1')),
      ),
    );
    await tester.pumpAndSettle();

    // Verify BookDetailScreen renders
    expect(find.byType(BookDetailScreen), findsOneWidget);

    // Verify title and header are visible
    expect(find.text('Detailed Test Book'), findsOneWidget);

    // Verify bottom button is visible at bottom
    expect(find.text('Read Book'), findsOneWidget);

    // Verify the bottom button is positioned near the bottom of the screen (not floating in the middle)
    final buttonFinder = find.text('Read Book');
    final buttonOffset = tester.getTopLeft(buttonFinder);
    expect(buttonOffset.dy, greaterThan(800));
  });
}
