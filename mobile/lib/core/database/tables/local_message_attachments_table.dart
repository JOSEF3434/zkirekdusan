// lib/core/database/tables/local_message_attachments_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalMessageAttachmentData')
class LocalMessageAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get messageLocalId => text()(); // References LocalMessages.localId
  TextColumn get fileId => text().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get localAttachmentPath => text().nullable()();
  TextColumn get fileType => text().withDefault(const Constant('IMAGE'))();
  TextColumn get mimeType => text()();
  TextColumn get originalName => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();

  // uploadStatus: pending, uploading, uploaded, failed
  TextColumn get uploadStatus => text().withDefault(const Constant('uploaded'))();
  // downloadStatus: not_downloaded, downloading, downloaded, failed
  TextColumn get downloadStatus => text().withDefault(const Constant('not_downloaded'))();

  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  RealColumn get duration => real().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
