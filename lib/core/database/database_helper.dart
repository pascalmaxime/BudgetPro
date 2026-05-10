import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'budget_pro.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_contrat TEXT NOT NULL,
        situation_logement TEXT NOT NULL,
        loyer_mensuel REAL,
        objectif_epargne REAL NOT NULL DEFAULT 0,
        rappel_jours_avant INTEGER NOT NULL DEFAULT 3
      )
    ''');

    await db.execute('''
      CREATE TABLE abonnements (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        montant REAL NOT NULL,
        frequence TEXT NOT NULL,
        date_renouvellement TEXT NOT NULL,
        categorie TEXT NOT NULL,
        actif INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        mois TEXT NOT NULL,
        montant REAL NOT NULL,
        description TEXT NOT NULL,
        categorie TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_mois ON transactions(mois)');
  }
}
