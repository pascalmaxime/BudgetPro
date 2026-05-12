import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/entities/abonnement.dart';
import '../../domain/entities/compte.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../repositories/profile_repository.dart';

/// Résultat d'un import
class ImportResult {
  final int transactions;
  final int abonnements;
  final int comptes;
  final bool profilImporte;
  final List<String> errors;

  const ImportResult({
    required this.transactions,
    required this.abonnements,
    required this.comptes,
    this.profilImporte = false,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get total => transactions + abonnements + comptes;

  @override
  String toString() {
    final parts = <String>[];
    if (transactions > 0) parts.add('$transactions transactions');
    if (abonnements > 0) parts.add('$abonnements abonnements');
    if (comptes > 0) parts.add('$comptes comptes');
    if (profilImporte) parts.add('profil');
    final base = parts.isEmpty ? 'Aucune donnée importée' : '${parts.join(', ')} importés';
    return hasErrors ? '$base (${errors.length} erreur(s))' : base;
  }
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

    // ── Profil ──────────────────────────────────────────────────────────────
    bool profilImporte = false;
    final profilSheet = excel.sheets['Profil'];
    if (profilSheet != null) {
      try {
        final profile = _parseProfilSheet(profilSheet);
        if (profile != null) {
          // Preserve existing id if any
          final existing = await ProfileRepository().get();
          final toSave = profile.copyWith(id: existing?.id);
          await ProfileRepository().save(toSave);
          profilImporte = true;
        }
      } catch (e) {
        errors.add('Profil: $e');
      }
    }

    return ImportResult(
      transactions: nbTx,
      abonnements: nbAbo,
      comptes: nbCptes,
      profilImporte: profilImporte,
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

  // ── Parser profil ────────────────────────────────────────────────────────

  static UserProfile? _parseProfilSheet(Sheet sheet) {
    final rows = sheet.rows;
    if (rows.isEmpty) return null;

    // Passe 1 : collecter tous les couples clé/valeur reconnus,
    // quel que soit leur position (compatible export ET modèle).
    const knownKeys = {
      'type_contrat', 'situation_logement', 'loyer_mensuel',
      'objectif_epargne', 'rappel_jours_avant',
      'objectif_patrimoine', 'date_objectif_patrimoine',
    };
    final kv = <String, String>{};
    for (var i = 0; i < rows.length; i++) {
      final key = _str(rows[i], 0);
      if (knownKeys.contains(key)) {
        kv[key] = _str(rows[i], 1);
      }
    }

    final contratStr = kv['type_contrat'] ?? '';
    final logementStr = kv['situation_logement'] ?? '';
    if (contratStr.isEmpty || logementStr.isEmpty) return null;

    final contrat = ContratType.values.firstWhere(
      (e) => e.name == contratStr,
      orElse: () => ContratType.cdi,
    );
    final logement = LogementType.values.firstWhere(
      (e) => e.name == logementStr,
      orElse: () => LogementType.locataire,
    );
    final loyer = double.tryParse((kv['loyer_mensuel'] ?? '').replaceAll(',', '.'));
    final objectif = double.tryParse((kv['objectif_epargne'] ?? '0').replaceAll(',', '.')) ?? 0;
    final rappel = int.tryParse(kv['rappel_jours_avant'] ?? '3') ?? 3;

    // Objectif patrimoine
    final patrimoineStr = (kv['objectif_patrimoine'] ?? '').replaceAll(',', '.');
    final objectifPatrimoine = double.tryParse(patrimoineStr) ?? 0;

    DateTime? dateObjectifPatrimoine;
    final datePatrimoineStr = kv['date_objectif_patrimoine'] ?? '';
    if (datePatrimoineStr.isNotEmpty) {
      try {
        dateObjectifPatrimoine = _parseDate(datePatrimoineStr);
      } catch (_) {}
    }

    // Passe 2 : scanner les sections SOURCES_REVENUS / CHARGES_FIXES
    // (fonctionne quel que soit le décalage de ligne du marqueur).
    final sources = <SourceRevenu>[];
    final charges = <ChargeFixer>[];
    String? currentSection;

    for (var i = 0; i < rows.length; i++) {
      final col0 = _str(rows[i], 0);
      if (col0 == 'SOURCES_REVENUS') {
        currentSection = 'sources';
        continue; // ligne suivante = en-têtes
      }
      if (col0 == 'CHARGES_FIXES') {
        currentSection = 'charges';
        continue;
      }
      if (currentSection == null) continue;

      // Sauter les lignes d'en-tête et les lignes vides
      if (col0 == 'label' || col0 == 'Champ' || col0 == 'jour_du_mois') continue;
      if (_isEmptyRow(rows[i])) continue;

      final label = col0;
      final montant =
          double.tryParse(_str(rows[i], 1).replaceAll(',', '.')) ?? 0;
      final jour =
          (int.tryParse(_str(rows[i], 2)) ?? 1).clamp(1, 31);
      // Ignorer les lignes de commentaire (montant non numérique → 0)
      if (label.isEmpty || montant <= 0) continue;

      if (currentSection == 'sources') {
        sources.add(SourceRevenu(
            id: _uuid.v4(), label: label, montant: montant, jour: jour));
      } else if (currentSection == 'charges') {
        charges.add(ChargeFixer(
            id: _uuid.v4(), label: label, montant: montant, jour: jour));
      }
    }

    return UserProfile(
      typeContrat: contrat,
      situationLogement: logement,
      loyerMensuel: loyer,
      sources: sources,
      chargesFixes: charges,
      objectifEpargne: objectif,
      rappelJoursAvant: rappel,
      objectifPatrimoine: objectifPatrimoine,
      dateObjectifPatrimoine: dateObjectifPatrimoine,
    );
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
