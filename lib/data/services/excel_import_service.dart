import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/abonnement.dart';
import '../../domain/entities/compte.dart';
import '../../domain/entities/transaction.dart';

/// Résultat d'un import
class ImportResult {
  final int transactions;
  final int abonnements;
  final int comptes;
  final List<String> errors;

  const ImportResult({
    required this.transactions,
    required this.abonnements,
    required this.comptes,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get total => transactions + abonnements + comptes;

  @override
  String toString() =>
      '$transactions transactions, $abonnements abonnements, $comptes comptes importés'
      '${hasErrors ? ' (${errors.length} erreur(s))' : ''}';
}

class ExcelImportService {
  static final _uuid = const Uuid();
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  /// Lit un fichier .xlsx et insère les données dans la base.
  /// Utilise INSERT OR REPLACE pour éviter les doublons si l'id existe.
  static Future<ImportResult> importFromFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    int nbTx = 0, nbAbo = 0, nbCptes = 0;
    final errors = <String>[];

    // ── Transactions ────────────────────────────────────────────────────────
    final txSheet = excel.sheets['Transactions'];
    if (txSheet != null) {
      final rows = txSheet.rows;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (_isEmptyRow(row)) continue;
        try {
          final t = _parseTransaction(row, i + 1);
          if (t != null) {
            await _upsert('transactions', t.toMap());
            nbTx++;
          }
        } catch (e) {
          errors.add('Transactions ligne ${i + 1}: $e');
        }
      }
    }

    // ── Abonnements ─────────────────────────────────────────────────────────
    final aboSheet = excel.sheets['Abonnements'];
    if (aboSheet != null) {
      final rows = aboSheet.rows;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (_isEmptyRow(row)) continue;
        try {
          final a = _parseAbonnement(row, i + 1);
          if (a != null) {
            await _upsert('abonnements', a.toMap());
            nbAbo++;
          }
        } catch (e) {
          errors.add('Abonnements ligne ${i + 1}: $e');
        }
      }
    }

    // ── Comptes (export BudgetPro ou modèle) ────────────────────────────────
    final comptesSheet = excel.sheets['Comptes'] ?? excel.sheets['Comptes_Epargne'];
    if (comptesSheet != null) {
      final rows = comptesSheet.rows;
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (_isEmptyRow(row)) continue;
        final firstCell = _str(row, 0);
        // Ignorer les lignes de légende du modèle
        if (firstCell.startsWith('──') || firstCell == 'id' || firstCell == 'nom *') continue;
        try {
          final c = _parseCompte(row, i + 1);
          if (c != null) {
            await _upsert('comptes', c.toMap());
            nbCptes++;
          }
        } catch (e) {
          errors.add('Comptes ligne ${i + 1}: $e');
        }
      }
    }

    return ImportResult(
      transactions: nbTx,
      abonnements: nbAbo,
      comptes: nbCptes,
      errors: errors,
    );
  }

  // ── Parsers ───────────────────────────────────────────────────────────────

  static Transaction? _parseTransaction(List<Data?> row, int lineNum) {
    // Format export (avec id UUID en col 0) vs format modèle (sans id)
    final col0 = _str(row, 0);
    final hasId = col0.length == 36 && col0.contains('-');

    final id = hasId ? col0 : _uuid.v4();
    final mois = hasId ? _str(row, 1) : '';
    final dateStr = _str(row, hasId ? 2 : 0);
    final montantStr = _str(row, hasId ? 3 : 1);
    final description = _str(row, hasId ? 4 : 2);
    final categorieStr = _str(row, hasId ? 5 : 3);
    final typeStr = _str(row, hasId ? 6 : 4);

    if (dateStr.isEmpty || montantStr.isEmpty || description.isEmpty) return null;

    final date = _parseDate(dateStr);
    final montant = double.parse(montantStr.replaceAll(',', '.'));
    final moisFinal = mois.isNotEmpty
        ? mois
        : '${date.year}-${date.month.toString().padLeft(2, '0')}';

    return Transaction(
      id: id,
      mois: moisFinal,
      montant: montant,
      description: description,
      categorie: _parseCategorieTransaction(categorieStr),
      date: date,
      type: _parseTransactionType(typeStr),
    );
  }

  static Abonnement? _parseAbonnement(List<Data?> row, int lineNum) {
    final col0 = _str(row, 0);
    final hasId = col0.length == 36 && col0.contains('-');

    final id = hasId ? col0 : _uuid.v4();
    final nom = _str(row, hasId ? 1 : 0);
    final montantStr = _str(row, hasId ? 2 : 1);
    final frequenceStr = _str(row, hasId ? 3 : 2);
    final dateStr = _str(row, hasId ? 4 : 3);
    final categorieStr = _str(row, hasId ? 5 : 4);
    final actifStr = _str(row, hasId ? 6 : 5);

    if (nom.isEmpty || montantStr.isEmpty || dateStr.isEmpty) return null;

    return Abonnement(
      id: id,
      nom: nom,
      montant: double.parse(montantStr.replaceAll(',', '.')),
      frequence: _parseFrequence(frequenceStr),
      dateRenouvellement: _parseDate(dateStr),
      categorie: _parseCategorieAbonnement(categorieStr),
      actif: actifStr != 'false' && actifStr != '0',
    );
  }

  static Compte? _parseCompte(List<Data?> row, int lineNum) {
    final col0 = _str(row, 0);
    final hasId = col0.length == 36 && col0.contains('-');

    final id = hasId ? col0 : _uuid.v4();
    final nom = _str(row, hasId ? 1 : 0);
    final typeStr = _str(row, hasId ? 2 : 1);
    final soldeStr = _str(row, hasId ? 3 : 2);
    final banque = _str(row, hasId ? 4 : 3);
    final dateStr = _str(row, hasId ? 5 : 4);

    if (nom.isEmpty || typeStr.isEmpty || soldeStr.isEmpty) return null;

    final type = TypeCompte.values.firstWhere(
      (e) => e.name == typeStr || e.label.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => TypeCompte.compteCourant,
    );

    return Compte(
      id: id,
      nom: nom,
      type: type,
      solde: double.parse(soldeStr.replaceAll(',', '.')),
      banque: banque.isEmpty ? null : banque,
      dateOuverture: dateStr.isNotEmpty ? _parseDate(dateStr) : null,
    );
  }

  // ── Mappers enums ─────────────────────────────────────────────────────────

  static TransactionType _parseTransactionType(String s) {
    const map = <String, TransactionType>{
      'revenu': TransactionType.revenu,
      'depenseFixe': TransactionType.depenseFixe,
      'depense_fixe': TransactionType.depenseFixe,
      'depenseVariable': TransactionType.depenseVariable,
      'depense_variable': TransactionType.depenseVariable,
      'epargne': TransactionType.epargne,
    };
    return map[s] ?? map[s.toLowerCase()] ?? TransactionType.depenseVariable;
  }

  static CategorieTransaction _parseCategorieTransaction(String s) {
    try {
      return CategorieTransaction.values.firstWhere((e) => e.name == s);
    } catch (_) {}
    const map = <String, CategorieTransaction>{
      'salaire': CategorieTransaction.salaire,
      'apl': CategorieTransaction.apl,
      'aide_logement': CategorieTransaction.apl,
      'autreRevenu': CategorieTransaction.autreRevenu,
      'autre_revenu': CategorieTransaction.autreRevenu,
      'loyer': CategorieTransaction.loyer,
      'logement': CategorieTransaction.loyer,
      'alimentation': CategorieTransaction.alimentation,
      'transport': CategorieTransaction.transport,
      'sante': CategorieTransaction.sante,
      'vetements': CategorieTransaction.vetements,
      'habillement': CategorieTransaction.vetements,
      'loisirs': CategorieTransaction.loisirs,
      'restaurant': CategorieTransaction.restaurant,
      'restauration': CategorieTransaction.restaurant,
      'epargne': CategorieTransaction.epargne,
      'epargne_virement': CategorieTransaction.epargne,
      'autre': CategorieTransaction.autre,
    };
    return map[s] ?? map[s.toLowerCase()] ?? CategorieTransaction.autre;
  }

  static FrequenceType _parseFrequence(String s) {
    const map = <String, FrequenceType>{
      'mensuel': FrequenceType.mensuel,
      'mensuelle': FrequenceType.mensuel,
      'monthly': FrequenceType.mensuel,
      'annuel': FrequenceType.annuel,
      'annuelle': FrequenceType.annuel,
      'yearly': FrequenceType.annuel,
      'trimestriel': FrequenceType.mensuel, // approximation
      'hebdomadaire': FrequenceType.mensuel, // approximation
    };
    return map[s] ?? map[s.toLowerCase()] ?? FrequenceType.mensuel;
  }

  static CategorieAbonnement _parseCategorieAbonnement(String s) {
    try {
      return CategorieAbonnement.values.firstWhere((e) => e.name == s);
    } catch (_) {}
    const map = <String, CategorieAbonnement>{
      'streaming': CategorieAbonnement.streaming,
      'musique': CategorieAbonnement.musique,
      'music': CategorieAbonnement.musique,
      'sport': CategorieAbonnement.sport,
      'fitness': CategorieAbonnement.sport,
      'logiciel': CategorieAbonnement.logiciels,
      'logiciels': CategorieAbonnement.logiciels,
      'software': CategorieAbonnement.logiciels,
      'presse': CategorieAbonnement.presse,
      'telephonie': CategorieAbonnement.autre,
      'assurance': CategorieAbonnement.autre,
      'autre': CategorieAbonnement.autre,
    };
    return map[s] ?? map[s.toLowerCase()] ?? CategorieAbonnement.autre;
  }

  // ── DB upsert ──────────────────────────────────────────────────────────────

  static Future<void> _upsert(String table, Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Utilitaires ───────────────────────────────────────────────────────────

  /// Extrait la valeur texte d'une cellule, quel que soit son type.
  static String _str(List<Data?> row, int col) {
    if (col >= row.length) return '';
    final v = row[col]?.value;
    if (v == null) return '';
    if (v is TextCellValue) {
      // TextCellValue.value est un TextSpan custom (excel 4.x)
      // toString() retourne le texte brut (texte + enfants concaténés)
      return v.value.toString().trim();
    }
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is DateCellValue) {
      return _dateFmt.format(DateTime(v.year, v.month, v.day));
    }
    return v.toString().trim();
  }

  static bool _isEmptyRow(List<Data?> row) {
    for (var i = 0; i < row.length; i++) {
      if (_str(row, i).isNotEmpty) return false;
    }
    return true;
  }

  static DateTime _parseDate(String s) {
    if (s.isEmpty) throw FormatException('Date vide');
    if (s.contains('/')) return _dateFmt.parse(s);
    return DateTime.parse(s);
  }
}
