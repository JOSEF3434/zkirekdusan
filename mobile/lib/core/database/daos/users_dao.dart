// lib/core/database/daos/users_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_users_table.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [LocalUsers])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<void> saveUser(LocalUserData user) {
    return into(localUsers).insertOnConflictUpdate(user);
  }

  Future<LocalUserData?> getUser(String id) {
    return (select(localUsers)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<LocalUserData?> watchUser(String id) {
    return (select(localUsers)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<int> deleteUser(String id) {
    return (delete(localUsers)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> clearUsers() {
    return delete(localUsers).go();
  }
}
