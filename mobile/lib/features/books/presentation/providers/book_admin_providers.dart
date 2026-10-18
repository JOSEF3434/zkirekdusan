// lib/features/books/presentation/providers/book_admin_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book_model.dart';
import '../../data/models/book_category_model.dart';
import '../../data/repositories/books_repository.dart';
import 'books_providers.dart';

class BookAdminFilter {
  final String? search;
  final String? status; // null | 'ALL' | 'PUBLISHED' | 'DRAFT' | 'ARCHIVED'
  final String? categoryId;
  final String? format;
  final String? language;
  final String sortBy;
  final String sortDir;

  const BookAdminFilter({
    this.search,
    this.status,
    this.categoryId,
    this.format,
    this.language,
    this.sortBy = 'updatedAt',
    this.sortDir = 'desc',
  });

  BookAdminFilter copyWith({
    String? search,
    bool clearSearch = false,
    String? status,
    bool clearStatus = false,
    String? categoryId,
    bool clearCategory = false,
    String? format,
    bool clearFormat = false,
    String? language,
    bool clearLanguage = false,
    String? sortBy,
    String? sortDir,
  }) {
    return BookAdminFilter(
      search: clearSearch ? null : (search ?? this.search),
      status: clearStatus ? null : (status ?? this.status),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      format: clearFormat ? null : (format ?? this.format),
      language: clearLanguage ? null : (language ?? this.language),
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
    );
  }
}

class BookAdminState {
  final List<BookModel> books;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final BookAdminFilter filter;

  const BookAdminState({
    this.books = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filter = const BookAdminFilter(),
  });

  BookAdminState copyWith({
    List<BookModel>? books,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    BookAdminFilter? filter,
    bool clearError = false,
  }) {
    return BookAdminState(
      books: books ?? this.books,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

class BookAdminNotifier extends StateNotifier<BookAdminState> {
  final BooksRepository _repo;

  BookAdminNotifier(this._repo) : super(const BookAdminState()) {
    load();
  }

  Future<void> load({bool reset = true}) async {
    if (state.isLoading) return;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true, page: 1);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 1 : state.page + 1;
      final statusParam =
          (state.filter.status == null || state.filter.status == 'ALL')
              ? null
              : state.filter.status;

      final result = await _repo.getAdminBooks(
        search: state.filter.search,
        categoryId: state.filter.categoryId,
        format: state.filter.format,
        language: state.filter.language,
        status: statusParam,
        page: page,
        sortBy: state.filter.sortBy,
        sortDir: state.filter.sortDir,
      );

      state = state.copyWith(
        books: reset ? result.items : [...state.books, ...result.items],
        total: result.total,
        page: page,
        hasMore: result.hasNext,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await load(reset: false);
  }

  Future<void> applyFilter(BookAdminFilter filter) async {
    state = state.copyWith(filter: filter);
    await load(reset: true);
  }

  Future<void> refresh() => load(reset: true);
}

final bookAdminListProvider =
    StateNotifierProvider<BookAdminNotifier, BookAdminState>((ref) {
  return BookAdminNotifier(ref.watch(booksRepositoryProvider));
});

final adminCategoriesProvider =
    FutureProvider<List<BookCategoryModel>>((ref) async {
  return ref
      .watch(booksRepositoryProvider)
      .getAdminCategories(includeArchived: true);
});
