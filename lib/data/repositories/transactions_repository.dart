import '../../core/database/database_helper.dart';
import '../../domain/entities/transaction.dart';

class TransactionsRepository {
  Future<List<Transaction>> getByMois(String mois) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('transactions',
        where: 'mois = ?', whereArgs: [mois], orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<String>> getMoisDisponibles() async {
    final db = await DatabaseHelper.database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT mois FROM transactions ORDER BY mois DESC');
    return rows.map((r) => r['mois'] as String).toList();
  }

  Future<void> insert(Transaction t) async {
    final db = await DatabaseHelper.database;
    await db.insert('transactions', t.toMap());
  }

  Future<void> update(Transaction t) async {
    final db = await DatabaseHelper.database;
    await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getAll() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }
}
