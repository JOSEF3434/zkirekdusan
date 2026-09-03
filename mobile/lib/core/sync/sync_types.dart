// lib/core/sync/sync_types.dart

enum SyncOperationType {
  createMessage('CREATE_MESSAGE'),
  editMessage('EDIT_MESSAGE'),
  deleteMessage('DELETE_MESSAGE'),
  sendReaction('SEND_REACTION'),
  removeReaction('REMOVE_REACTION'),
  updateReadState('UPDATE_READ_STATE'),
  updateWatchHistory('UPDATE_WATCH_HISTORY'),
  createLike('CREATE_LIKE'),
  removeLike('REMOVE_LIKE');

  final String value;
  const SyncOperationType(this.value);

  static SyncOperationType fromString(String raw) {
    for (final op in SyncOperationType.values) {
      if (op.value == raw) return op;
    }
    return SyncOperationType.createMessage;
  }
}

enum SyncEntityType {
  message('MESSAGE'),
  reaction('REACTION'),
  readState('READ_STATE'),
  watchHistory('WATCH_HISTORY'),
  like('LIKE');

  final String value;
  const SyncEntityType(this.value);

  static SyncEntityType fromString(String raw) {
    for (final e in SyncEntityType.values) {
      if (e.value == raw) return e;
    }
    return SyncEntityType.message;
  }
}

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}
