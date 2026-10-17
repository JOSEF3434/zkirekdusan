// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_books_dao.dart';

// ignore_for_file: type=lint
mixin _$DownloadedBooksDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalDownloadedBooksTable get localDownloadedBooks =>
      attachedDatabase.localDownloadedBooks;
  DownloadedBooksDaoManager get managers => DownloadedBooksDaoManager(this);
}

class DownloadedBooksDaoManager {
  final _$DownloadedBooksDaoMixin _db;
  DownloadedBooksDaoManager(this._db);
  $$LocalDownloadedBooksTableTableManager get localDownloadedBooks =>
      $$LocalDownloadedBooksTableTableManager(
        _db.attachedDatabase,
        _db.localDownloadedBooks,
      );
}
