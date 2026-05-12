import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/abonnement.dart';
import '../../domain/entities/compte.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../repositories/compte_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/transactions_repository.dart';
import '../repositories/abonnements_repository.dart';

class ExcelExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');

  /// Exporte toutes les données réelles vers un fichier .xlsx.
  /// Retourne le chemin du fichier créé.
  static Future<String> exportData() async {
    // Charger toutes les données
    final transactions = await TransactionsRepository().getAll();
    final abonnements = await AbonnementsRepository().getAll();
    final comptes = await CompteRepository().getAll();
    final profile = await ProfileRepository().get();

    final excel = Excel.createExcel();
    if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

    _buildInfoSheet(excel, transactions.length, abonnements.length, comptes.length);
    _buildTransactionsSheet(excel, transactions);
    _buildAbonnementsSheet(excel, abonnements);
    _buildComptesSheet(excel, comptes);
    _buildProfilSheet(excel, profile);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Échec de la génération du fichier');

    final dir = await _saveDirectory();
    final now = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final path = p.join(dir.path, 'BudgetPro_Export_$now.xlsx');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  // ── Répertoire cible ──────────────────────────────────────────────────────

  static Future<Directory> _saveDirectory() async {
    if (!kIsWeb) {
      if (Platform.isMacOS || Platform.isWindows) {
        final dir = await getDownloadsDirectory();
        if (dir != null) return dir;
      }
    }
    return getApplicationDocumentsDirectory();
  }

  // ── Helpers cellules ──────────────────────────────────────────────────────

  static void _h(Sheet s, int col, int row, String text) {
    final cell = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FF1A56DB'),
      fontColorHex: ExcelColor.white,
    );
  }

  static void _c(Sheet s, int col, int row, String text) {
    s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        TextCellValue(text);
  }

  // ── Feuille d'informations ────────────────────────────────────────────────

  static void _buildInfoSheet(Excel excel, int nbTx, int nbAbo, int nbCptes) {
    final s = excel['Export BudgetPro'];
    _c(s, 0, 0, 'BudgetPro — Sauvegarde des données');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = CellStyle(bold: true, fontSize: 14);

    _c(s, 0, 2, 'Date d\'export');
    _c(s, 1, 2, DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now()));

    _c(s, 0, 3, 'Transactions exportées');
    _c(s, 1, 3, '$nbTx');

    _c(s, 0, 4, 'Abonnements exportés');
    _c(s, 1, 4, '$nbAbo');

    _c(s, 0, 5, 'Comptes exportés');
    _c(s, 1, 5, '$nbCptes');

    _c(s, 0, 7,
        'Pour importer ce fichier sur un autre appareil, utilisez le bouton "Importer des données" dans les Paramètres.');

    s.setColumnWidth(0, 28);
    s.setColumnWidth(1, 40);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  static void _buildTransactionsSheet(Excel excel, List<Transaction> transactions) {
    final s = excel['Transactions'];
    final headers = ['id', 'mois', 'date', 'montant', 'description', 'categorie', 'type'];
    for (var i = 0; i < headers.length; i++) { _h(s, i, 0, headers[i]); }

    for (var r = 0; r < transactions.length; r++) {
      final t = transactions[r];
      _c(s, 0, r + 1, t.id);
      _c(s, 1, r + 1, t.mois);
      _c(s, 2, r + 1, _dateFmt.format(t.date));
      _c(s, 3, r + 1, t.montant.toStringAsFixed(2));
      _c(s, 4, r + 1, t.description);
      _c(s, 5, r + 1, t.categorie.name);
      _c(s, 6, r + 1, t.type.name);
    }

    s.setColumnWidth(0, 38);
    s.setColumnWidth(1, 10);
    s.setColumnWidth(2, 14);
    s.setColumnWidth(3, 12);
    s.setColumnWidth(4, 32);
    s.setColumnWidth(5, 20);
    s.setColumnWidth(6, 18);
  }

  // ── Abonnements ───────────────────────────────────────────────────────────

  static void _buildAbonnementsSheet(Excel excel, List<Abonnement> abonnements) {
    final s = excel['Abonnements'];
    final headers = ['id', 'nom', 'montant', 'frequence', 'date_renouvellement', 'categorie', 'actif'];
    for (var i = 0; i < headers.length; i++) { _h(s, i, 0, headers[i]); }

    for (var r = 0; r < abonnements.length; r++) {
      final a = abonnements[r];
      _c(s, 0, r + 1, a.id);
      _c(s, 1, r + 1, a.nom);
      _c(s, 2, r + 1, a.montant.toStringAsFixed(2));
      _c(s, 3, r + 1, a.frequence.name);
      _c(s, 4, r + 1, _dateFmt.format(a.dateRenouvellement));
      _c(s, 5, r + 1, a.categorie.name);
      _c(s, 6, r + 1, a.actif ? 'true' : 'false');
    }

    s.setColumnWidth(0, 38);
    s.setColumnWidth(1, 25);
    s.setColumnWidth(2, 12);
    s.setColumnWidth(3, 14);
    s.setColumnWidth(4, 22);
    s.setColumnWidth(5, 18);
    s.setColumnWidth(6, 8);
  }

  // ── Comptes ───────────────────────────────────────────────────────────────

  static void _buildComptesSheet(Excel excel, List<Compte> comptes) {
    final s = excel['Comptes'];
    final headers = ['id', 'nom', 'type', 'solde', 'banque', 'date_ouverture'];
    for (var i = 0; i < headers.length; i++) { _h(s, i, 0, headers[i]); }

    for (var r = 0; r < comptes.length; r++) {
      final c = comptes[r];
      _c(s, 0, r + 1, c.id);
      _c(s, 1, r + 1, c.nom);
      _c(s, 2, r + 1, c.type.name);
      _c(s, 3, r + 1, c.solde.toStringAsFixed(2));
      _c(s, 4, r + 1, c.banque ?? '');
      _c(s, 5, r + 1, c.dateOuverture != null ? _dateFmt.format(c.dateOuverture!) : '');
    }

    s.setColumnWidth(0, 38);
    s.setColumnWidth(1, 28);
    s.setColumnWidth(2, 18);
    s.setColumnWidth(3, 14);
    s.setColumnWidth(4, 22);
    s.setColumnWidth(5, 16);
  }

  // ── Profil ────────────────────────────────────────────────────────────────

  static void _buildProfilSheet(Excel excel, UserProfile? profile) {
    final s = excel['Profil'];
    if (profile == null) {
      _c(s, 0, 0, 'Aucun profil configuré');
      return;
    }

    // ── Informations de base ──
    _h(s, 0, 0, 'Champ');
    _h(s, 1, 0, 'Valeur');

    _c(s, 0, 1, 'type_contrat');
    _c(s, 1, 1, profile.typeContrat.name);

    _c(s, 0, 2, 'situation_logement');
    _c(s, 1, 2, profile.situationLogement.name);

    _c(s, 0, 3, 'loyer_mensuel');
    _c(s, 1, 3, profile.loyerMensuel != null
        ? profile.loyerMensuel!.toStringAsFixed(2)
        : '');

    _c(s, 0, 4, 'objectif_epargne');
    _c(s, 1, 4, profile.objectifEpargne.toStringAsFixed(2));

    _c(s, 0, 5, 'rappel_jours_avant');
    _c(s, 1, 5, '${profile.rappelJoursAvant}');

    _c(s, 0, 6, 'objectif_patrimoine');
    _c(s, 1, 6, profile.objectifPatrimoine > 0
        ? profile.objectifPatrimoine.toStringAsFixed(2)
        : '');

    _c(s, 0, 7, 'date_objectif_patrimoine');
    if (profile.dateObjectifPatrimoine != null) {
      final d = profile.dateObjectifPatrimoine!;
      _c(s, 1, 7,
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}');
    }

    // ── Sources de revenus (à partir de la ligne 9) ──
    const srcStart = 9;
    _c(s, 0, srcStart, 'SOURCES_REVENUS');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: srcStart))
        .cellStyle = CellStyle(bold: true, italic: true);
    _h(s, 0, srcStart + 1, 'label');
    _h(s, 1, srcStart + 1, 'montant');
    _h(s, 2, srcStart + 1, 'jour_du_mois');

    for (var i = 0; i < profile.sources.length; i++) {
      final src = profile.sources[i];
      _c(s, 0, srcStart + 2 + i, src.label);
      _c(s, 1, srcStart + 2 + i, src.montant.toStringAsFixed(2));
      _c(s, 2, srcStart + 2 + i, '${src.jour}');
    }

    // ── Charges fixes ──
    final chargesStart = srcStart + 2 + profile.sources.length + 1;
    _c(s, 0, chargesStart, 'CHARGES_FIXES');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: chargesStart))
        .cellStyle = CellStyle(bold: true, italic: true);
    _h(s, 0, chargesStart + 1, 'label');
    _h(s, 1, chargesStart + 1, 'montant');
    _h(s, 2, chargesStart + 1, 'jour_du_mois');

    for (var i = 0; i < profile.chargesFixes.length; i++) {
      final c = profile.chargesFixes[i];
      _c(s, 0, chargesStart + 2 + i, c.label);
      _c(s, 1, chargesStart + 2 + i, c.montant.toStringAsFixed(2));
      _c(s, 2, chargesStart + 2 + i, '${c.jour}');
    }

    s.setColumnWidth(0, 28);
    s.setColumnWidth(1, 16);
    s.setColumnWidth(2, 16);
  }
}
