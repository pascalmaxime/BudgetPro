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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
    await _createComptes(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createComptes(db);
    if (oldVersion < 3) await _addProfileJsonColumns(db);
    if (oldVersion < 4) await _addPatrimoineGoalColumns(db);
  }

  static Future<void> _addPatrimoineGoalColumns(Database db) async {
    await db.execute(
        'ALTER TABLE user_profile ADD COLUMN objectif_patrimoine REAL NOT NULL DEFAULT 0');
    await db.execute(
        'ALTER TABLE user_profile ADD COLUMN date_objectif_patrimoine TEXT');
  }

  static Future<void> _addProfileJsonColumns(Database db) async {
    await db.execute(
        "ALTER TABLE user_profile ADD COLUMN sources_json TEXT NOT NULL DEFAULT '[]'");
    await db.execute(
        "ALTER TABLE user_profile ADD COLUMN charges_fixes_json TEXT NOT NULL DEFAULT '[]'");
  }

  static Future<void> _createComptes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS comptes (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        type TEXT NOT NULL,
        solde REAL NOT NULL DEFAULT 0,
        banque TEXT,
        date_ouverture TEXT
      )
    ''');
  }

  /// Supprime toutes les données utilisateur (garde la structure des tables).
  static Future<void> resetAll() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('abonnements');
    await db.delete('comptes');
    await db.delete('user_profile');
  }
}
