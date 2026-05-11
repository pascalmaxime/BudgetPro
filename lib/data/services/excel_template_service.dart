import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ExcelTemplateService {
  // ── Public API ──────────────────────────────────────────────────────────────

  /// Génère le modèle .xlsx et retourne le chemin du fichier créé.
  static Future<String> generateTemplate() async {
    final excel = Excel.createExcel();

    // Supprimer la feuille par défaut
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    _buildGuideSheet(excel);
    _buildTransactionsSheet(excel);
    _buildAbonnementsSheet(excel);
    _buildComptesSheet(excel);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Échec de la génération du fichier Excel');

    final dir = await _saveDirectory();
    final path = p.join(dir.path, 'BudgetPro_Modele_Import.xlsx');
    await File(path).writeAsBytes(bytes);
    return path;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Future<Directory> _saveDirectory() async {
    if (!kIsWeb) {
      if (Platform.isMacOS || Platform.isWindows) {
        final dir = await getDownloadsDirectory();
        if (dir != null) return dir;
      }
    }
    return getApplicationDocumentsDirectory();
  }

  /// Écriture d'une cellule en-tête (fond bleu, texte blanc, gras)
  static void _header(Sheet sheet, int col, int row, String text) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#FF1A56DB'),
      fontColorHex: ExcelColor.white,
    );
  }

  /// Écriture d'une cellule texte normale
  static void _cell(Sheet sheet, int col, int row, String text) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue(text);
  }

  /// Écriture d'une cellule commentaire (gris clair, italique)
  static void _comment(Sheet sheet, int col, int row, String text) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(text);
    cell.cellStyle = CellStyle(
      italic: true,
      fontColorHex: ExcelColor.fromHexString('#FF6B7280'),
    );
  }

  // ── Feuille : Mode d'emploi ─────────────────────────────────────────────────

  static void _buildGuideSheet(Excel excel) {
    final s = excel['Mode d\'emploi'];

    _cell(s, 0, 0, 'BudgetPro — Modèle d\'import de données');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = CellStyle(bold: true, fontSize: 14);

    _cell(s, 0, 2,
        'Ce fichier vous permet d\'importer facilement vos données existantes dans BudgetPro.');

    _cell(s, 0, 4, 'FEUILLES DISPONIBLES');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .cellStyle = CellStyle(bold: true);

    final feuilles = [
      ('Transactions', 'Vos revenus, dépenses fixes/variables et virements épargne'),
      ('Abonnements', 'Vos abonnements récurrents (streaming, assurances, etc.)'),
      ('Comptes_Epargne',
          'Vos comptes bancaires, livrets, PEA, assurance-vie, etc.'),
    ];
    for (var i = 0; i < feuilles.length; i++) {
      _cell(s, 0, 5 + i, '• ${feuilles[i].$1}');
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5 + i))
          .cellStyle = CellStyle(bold: true);
      _cell(s, 1, 5 + i, feuilles[i].$2);
    }

    _cell(s, 0, 9, 'INSTRUCTIONS');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .cellStyle = CellStyle(bold: true);

    final instructions = [
      '1. Remplissez chaque feuille en vous basant sur les lignes d\'exemple.',
      '2. Ne modifiez PAS la ligne d\'en-tête (ligne 1 de chaque feuille).',
      '3. Les colonnes marquées * sont obligatoires.',
      '4. Respectez exactement les valeurs autorisées (sensibles à la casse).',
      '5. Les dates doivent être au format JJ/MM/AAAA (ex : 15/01/2025).',
      '6. Les montants sont en euros, nombres décimaux avec point (ex : 1500.00).',
      '7. Supprimez les lignes d\'exemple avant d\'importer.',
    ];
    for (var i = 0; i < instructions.length; i++) {
      _cell(s, 0, 10 + i, instructions[i]);
    }

    s.setColumnWidth(0, 50);
    s.setColumnWidth(1, 60);
  }

  // ── Feuille : Transactions ──────────────────────────────────────────────────

  static void _buildTransactionsSheet(Excel excel) {
    final s = excel['Transactions'];

    // En-têtes
    final headers = ['date *', 'montant *', 'description *', 'categorie *', 'type *'];
    for (var i = 0; i < headers.length; i++) {
      _header(s, i, 0, headers[i]);
    }

    // Ligne de commentaire
    _comment(s, 0, 1, 'JJ/MM/AAAA');
    _comment(s, 1, 1, 'nombre positif');
    _comment(s, 2, 1, 'texte libre');
    _comment(s, 3, 1,
        'alimentation | transport | logement | sante | loisirs | habillement | restauration | salaire | autre_revenu | epargne_virement | autre');
    _comment(s, 4, 1,
        'revenu | depense_fixe | depense_variable | epargne');

    // Exemples
    final exemples = [
      ['01/05/2025', '2800.00', 'Salaire mai', 'salaire', 'revenu'],
      ['01/05/2025', '800.00', 'Loyer', 'logement', 'depense_fixe'],
      ['03/05/2025', '120.00', 'Courses semaine', 'alimentation', 'depense_variable'],
      ['05/05/2025', '200.00', 'Virement Livret A', 'epargne_virement', 'epargne'],
      ['10/05/2025', '45.00', 'Restaurant vendredi', 'restauration', 'depense_variable'],
      ['15/05/2025', '350.00', 'Freelance mission', 'autre_revenu', 'revenu'],
    ];
    for (var r = 0; r < exemples.length; r++) {
      for (var c = 0; c < exemples[r].length; c++) {
        _cell(s, c, 2 + r, exemples[r][c]);
      }
    }

    s.setColumnWidth(0, 14);
    s.setColumnWidth(1, 14);
    s.setColumnWidth(2, 30);
    s.setColumnWidth(3, 45);
    s.setColumnWidth(4, 20);
  }

  // ── Feuille : Abonnements ───────────────────────────────────────────────────

  static void _buildAbonnementsSheet(Excel excel) {
    final s = excel['Abonnements'];

    final headers = [
      'nom *',
      'montant *',
      'frequence *',
      'date_renouvellement *',
      'categorie *',
      'actif',
    ];
    for (var i = 0; i < headers.length; i++) {
      _header(s, i, 0, headers[i]);
    }

    _comment(s, 0, 1, 'ex: Netflix');
    _comment(s, 1, 1, 'montant par occurrence');
    _comment(s, 2, 1, 'mensuel | trimestriel | annuel | hebdomadaire');
    _comment(s, 3, 1, 'JJ/MM/AAAA — prochain renouvellement');
    _comment(s, 4, 1, 'streaming | sport | logiciel | telephonie | assurance | autre');
    _comment(s, 5, 1, 'true | false (défaut: true)');

    final exemples = [
      ['Netflix', '17.99', 'mensuel', '01/06/2025', 'streaming', 'true'],
      ['Spotify', '10.99', 'mensuel', '15/06/2025', 'streaming', 'true'],
      ['Salle de sport', '29.90', 'mensuel', '05/06/2025', 'sport', 'true'],
      ['Adobe CC', '59.99', 'mensuel', '20/06/2025', 'logiciel', 'true'],
      ['Assurance habitation', '280.00', 'annuel', '01/09/2025', 'assurance', 'true'],
      ['Forfait mobile', '14.99', 'mensuel', '10/06/2025', 'telephonie', 'true'],
    ];
    for (var r = 0; r < exemples.length; r++) {
      for (var c = 0; c < exemples[r].length; c++) {
        _cell(s, c, 2 + r, exemples[r][c]);
      }
    }

    s.setColumnWidth(0, 25);
    s.setColumnWidth(1, 14);
    s.setColumnWidth(2, 18);
    s.setColumnWidth(3, 22);
    s.setColumnWidth(4, 22);
    s.setColumnWidth(5, 10);
  }

  // ── Feuille : Comptes_Epargne ───────────────────────────────────────────────

  static void _buildComptesSheet(Excel excel) {
    final s = excel['Comptes_Epargne'];

    final headers = [
      'nom *',
      'type *',
      'solde *',
      'banque',
      'date_ouverture',
    ];
    for (var i = 0; i < headers.length; i++) {
      _header(s, i, 0, headers[i]);
    }

    _comment(s, 0, 1, 'Nom personnalisé (ex: Livret A CA)');
    _comment(s, 1, 1,
        'livretA | ldd | lep | livretJeune | livretBancaire | pel | cel | per | perco | pea | peaPme | assuranceVie | cto | crypto | compteCourant | comptePro');
    _comment(s, 2, 1, 'solde actuel en euros');
    _comment(s, 3, 1, 'optionnel — ex: BNP Paribas');
    _comment(s, 4, 1, 'optionnel — JJ/MM/AAAA');

    final exemples = [
      // Livrets réglementés
      ['Livret A', 'livretA', '15000.00', 'Crédit Agricole', '15/03/2015'],
      ['LDDS', 'ldd', '8500.00', 'BNP Paribas', '10/06/2018'],
      ['LEP', 'lep', '6200.00', 'La Banque Postale', '01/01/2020'],
      // Épargne logement
      ['PEL Boursorama', 'pel', '32000.00', 'Boursorama', '15/04/2019'],
      // Investissements
      ['PEA Bourse', 'pea', '45000.00', 'Fortuneo', '20/02/2020'],
      ['Assurance-vie Spirica', 'assuranceVie', '28000.00', 'Spirica', '01/03/2016'],
      ['CTO Degiro', 'cto', '12000.00', 'Degiro', '05/11/2021'],
      // Retraite
      ['PER Individuel', 'per', '9500.00', 'Linxea', '15/01/2022'],
      // Courants
      ['Compte courant principal', 'compteCourant', '3200.00', 'Crédit Agricole', ''],
      ['Compte pro freelance', 'comptePro', '5800.00', 'Shine', '10/07/2022'],
    ];
    for (var r = 0; r < exemples.length; r++) {
      for (var c = 0; c < exemples[r].length; c++) {
        _cell(s, c, 2 + r, exemples[r][c]);
      }
    }

    // Légende des types en bas
    _cell(s, 0, 14, '── TYPES DE COMPTES DISPONIBLES ──');
    s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14))
        .cellStyle = CellStyle(bold: true);

    final types = [
      ('livretA', 'Livret A — taux 2,4 %/an, plafond 22 950 €'),
      ('ldd', 'LDD / LDDS — taux 2,4 %/an, plafond 12 000 €'),
      ('lep', 'LEP — taux 3,5 %/an, plafond 10 000 € (sous conditions)'),
      ('livretJeune', 'Livret Jeune — taux 3 %/an, plafond 1 600 €'),
      ('livretBancaire', 'Livret bancaire classique'),
      ('pel', 'PEL — Plan Épargne Logement, plafond 61 200 €'),
      ('cel', 'CEL — Compte Épargne Logement, plafond 15 300 €'),
      ('per', 'PER — Plan Épargne Retraite individuel'),
      ('perco', 'PERCO / PERO — épargne retraite entreprise'),
      ('pea', 'PEA — Plan Épargne en Actions, plafond 150 000 €'),
      ('peaPme', 'PEA-PME — PEA dédié PME, plafond 225 000 €'),
      ('assuranceVie', 'Assurance-vie — fiscalité avantageuse après 8 ans'),
      ('cto', 'CTO — Compte-Titres Ordinaire'),
      ('crypto', 'Crypto — portefeuille crypto-actifs'),
      ('compteCourant', 'Compte courant bancaire'),
      ('comptePro', 'Compte professionnel / freelance'),
    ];
    for (var i = 0; i < types.length; i++) {
      _cell(s, 0, 15 + i, types[i].$1);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 15 + i))
          .cellStyle = CellStyle(bold: true);
      _cell(s, 1, 15 + i, types[i].$2);
    }

    s.setColumnWidth(0, 28);
    s.setColumnWidth(1, 18);
    s.setColumnWidth(2, 14);
    s.setColumnWidth(3, 22);
    s.setColumnWidth(4, 16);
  }
}
