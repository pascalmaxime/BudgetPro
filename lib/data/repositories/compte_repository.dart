import '../../core/database/database_helper.dart';
import '../../domain/entities/compte.dart';

class CompteRepository {
  Future<List<Compte>> getAll() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('comptes', orderBy: 'type ASC, nom ASC');
    return rows.map(Compte.fromMap).toList();
  }

  Future<void> insert(Compte c) async {
    final db = await DatabaseHelper.database;
    await db.insert('comptes', c.toMap());
  }

  Future<void> update(Compte c) async {
    final db = await DatabaseHelper.database;
    await db.update('comptes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('comptes', where: 'id = ?', whereArgs: [id]);
  }
}
