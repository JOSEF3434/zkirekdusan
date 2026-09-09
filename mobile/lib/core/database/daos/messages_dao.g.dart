// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_dao.dart';

// ignore_for_file: type=lint
mixin _$MessagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalMessagesTable get localMessages => attachedDatabase.localMessages;
  MessagesDaoManager get managers => MessagesDaoManager(this);
}

class MessagesDaoManager {
  final _$MessagesDaoMixin _db;
  MessagesDaoManager(this._db);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db.attachedDatabase, _db.localMessages);
}
