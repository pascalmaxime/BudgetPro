import '../../core/database/database_helper.dart';
import '../../domain/entities/abonnement.dart';

class AbonnementsRepository {
  Future<List<Abonnement>> getAll() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('abonnements', orderBy: 'nom ASC');
    return rows.map(Abonnement.fromMap).toList();
  }

  Future<void> insert(Abonnement a) async {
    final db = await DatabaseHelper.database;
    await db.insert('abonnements', a.toMap());
  }

  Future<void> update(Abonnement a) async {
    final db = await DatabaseHelper.database;
    await db.update('abonnements', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('abonnements', where: 'id = ?', whereArgs: [id]);
  }
}
