import '../../core/database/database_helper.dart';
import '../../domain/entities/user_profile.dart';

class ProfileRepository {
  Future<UserProfile?> get() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<UserProfile> save(UserProfile profile) async {
    final db = await DatabaseHelper.database;
    if (profile.id == null) {
      final id = await db.insert('user_profile', profile.toMap());
      return profile.copyWith(id: id);
    } else {
      await db.update('user_profile', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
      return profile;
    }
  }
}
