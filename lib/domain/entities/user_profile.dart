import 'dart:convert';

// ── Sources de revenus ────────────────────────────────────────────────────────

class SourceRevenu {
  final String id;
  final String label;
  final double montant;
  /// Jour du mois pour l'auto-injection (1 = 1er du mois, 25 = le 25, etc.)
  final int jour;

  const SourceRevenu({
    required this.id,
    required this.label,
    required this.montant,
    this.jour = 1,
  });

  SourceRevenu copyWith({String? label, double? montant, int? jour}) =>
      SourceRevenu(
        id: id,
        label: label ?? this.label,
        montant: montant ?? this.montant,
        jour: jour ?? this.jour,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'montant': montant, 'jour': jour};

  factory SourceRevenu.fromJson(Map<String, dynamic> j) => SourceRevenu(
        id: j['id'] as String,
        label: j['label'] as String,
        montant: (j['montant'] as num).toDouble(),
        jour: (j['jour'] as int?) ?? 1,
      );
}

// ── Charges fixes mensuelles ──────────────────────────────────────────────────

class ChargeFixer {
  final String id;
  final String label;
  final double montant;
  /// Jour du mois pour l'auto-injection
  final int jour;

  const ChargeFixer({
    required this.id,
    required this.label,
    required this.montant,
    this.jour = 1,
  });

  ChargeFixer copyWith({String? label, double? montant, int? jour}) =>
      ChargeFixer(
        id: id,
        label: label ?? this.label,
        montant: montant ?? this.montant,
        jour: jour ?? this.jour,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'montant': montant, 'jour': jour};

  factory ChargeFixer.fromJson(Map<String, dynamic> j) => ChargeFixer(
        id: j['id'] as String,
        label: j['label'] as String,
        montant: (j['montant'] as num).toDouble(),
        jour: (j['jour'] as int?) ?? 1,
      );
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ContratType {
  cdi('CDI'),
  cdd('CDD'),
  alternant('Alternant'),
  freelance('Freelance'),
  etudiant('Étudiant'),
  sansEmploi('Sans emploi'),
  retraite('Retraité');

  const ContratType(this.label);
  final String label;
}

enum LogementType {
  proprietaire('Propriétaire'),
  locataire('Locataire'),
  heberge('Hébergé (sans loyer)');

  const LogementType(this.label);
  final String label;
}

// ── Profil utilisateur ────────────────────────────────────────────────────────

class UserProfile {
  final int? id;
  final ContratType typeContrat;
  final LogementType situationLogement;
  final double? loyerMensuel;
  final List<SourceRevenu> sources;
  final List<ChargeFixer> chargesFixes;

  /// 0 = auto-calculé depuis sources × tauxRecommandé
  final double objectifEpargne;
  final int rappelJoursAvant;

  /// Objectif patrimoine total à atteindre (0 = non défini)
  final double objectifPatrimoine;

  /// Date limite pour atteindre l'objectif patrimoine
  final DateTime? dateObjectifPatrimoine;

  const UserProfile({
    this.id,
    required this.typeContrat,
    required this.situationLogement,
    this.loyerMensuel,
    this.sources = const [],
    this.chargesFixes = const [],
    required this.objectifEpargne,
    this.rappelJoursAvant = 3,
    this.objectifPatrimoine = 0,
    this.dateObjectifPatrimoine,
  });

  // ── Calculé ───────────────────────────────────────────────────────────────

  double get revenuMensuelTotal => sources.fold(0.0, (s, r) => s + r.montant);

  double get chargesFixesTotales =>
      chargesFixes.fold(0.0, (s, c) => s + c.montant) + (loyerMensuel ?? 0);

  double get tauxEpargneRecommande => switch (typeContrat) {
        ContratType.cdi => 20.0,
        ContratType.cdd => 15.0,
        ContratType.alternant => 15.0,
        ContratType.freelance => 25.0,
        ContratType.etudiant => 10.0,
        ContratType.sansEmploi => 5.0,
        ContratType.retraite => 10.0,
      };

  double get objectifEpargneEffectif => objectifEpargne > 0
      ? objectifEpargne
      : revenuMensuelTotal * tauxEpargneRecommande / 100;

  double get fondsUrgenceRecommande => chargesFixesTotales * 3;

  String get conseilEpargne => switch (typeContrat) {
        ContratType.cdi => 'CDI : visez 20 % — Livret A, PEA, assurance-vie',
        ContratType.cdd => 'CDD : constituez un fonds de précaution (3 mois de charges)',
        ContratType.alternant => 'Alternant : profitez du LEP, Livret Jeune ou PEL',
        ContratType.freelance => 'Freelance : provisionnez 25-30 % (charges sociales + épargne)',
        ContratType.etudiant => 'Étudiant : commencez par le Livret A ou Livret Jeune',
        ContratType.sansEmploi => 'Priorité : fonds de précaution, limitez les dépenses variables',
        ContratType.retraite => 'Retraité : orientez l\'épargne vers assurance-vie ou PER',
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  UserProfile copyWith({
    int? id,
    ContratType? typeContrat,
    LogementType? situationLogement,
    double? loyerMensuel,
    bool clearLoyer = false,
    List<SourceRevenu>? sources,
    List<ChargeFixer>? chargesFixes,
    double? objectifEpargne,
    int? rappelJoursAvant,
    double? objectifPatrimoine,
    DateTime? dateObjectifPatrimoine,
    bool clearDateObjectif = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      typeContrat: typeContrat ?? this.typeContrat,
      situationLogement: situationLogement ?? this.situationLogement,
      loyerMensuel: clearLoyer ? null : loyerMensuel ?? this.loyerMensuel,
      sources: sources ?? this.sources,
      chargesFixes: chargesFixes ?? this.chargesFixes,
      objectifEpargne: objectifEpargne ?? this.objectifEpargne,
      rappelJoursAvant: rappelJoursAvant ?? this.rappelJoursAvant,
      objectifPatrimoine: objectifPatrimoine ?? this.objectifPatrimoine,
      dateObjectifPatrimoine: clearDateObjectif
          ? null
          : dateObjectifPatrimoine ?? this.dateObjectifPatrimoine,
    );
  }

  // ── Sérialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type_contrat': typeContrat.name,
        'situation_logement': situationLogement.name,
        'loyer_mensuel': loyerMensuel,
        'objectif_epargne': objectifEpargne,
        'rappel_jours_avant': rappelJoursAvant,
        'sources_json': jsonEncode(sources.map((s) => s.toJson()).toList()),
        'charges_fixes_json': jsonEncode(chargesFixes.map((c) => c.toJson()).toList()),
        'objectif_patrimoine': objectifPatrimoine,
        'date_objectif_patrimoine': dateObjectifPatrimoine?.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    List<SourceRevenu> sources = [];
    List<ChargeFixer> chargesFixes = [];
    try {
      final s = map['sources_json'] as String?;
      if (s != null && s.length > 2) {
        sources = (jsonDecode(s) as List)
            .map((j) => SourceRevenu.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    try {
      final c = map['charges_fixes_json'] as String?;
      if (c != null && c.length > 2) {
        chargesFixes = (jsonDecode(c) as List)
            .map((j) => ChargeFixer.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return UserProfile(
      id: map['id'] as int?,
      typeContrat: ContratType.values.firstWhere((e) => e.name == map['type_contrat']),
      situationLogement:
          LogementType.values.firstWhere((e) => e.name == map['situation_logement']),
      loyerMensuel: map['loyer_mensuel'] as double?,
      sources: sources,
      chargesFixes: chargesFixes,
      objectifEpargne: (map['objectif_epargne'] as num).toDouble(),
      rappelJoursAvant: map['rappel_jours_avant'] as int? ?? 3,
      objectifPatrimoine:
          (map['objectif_patrimoine'] as num?)?.toDouble() ?? 0,
      dateObjectifPatrimoine: map['date_objectif_patrimoine'] != null
          ? DateTime.tryParse(map['date_objectif_patrimoine'] as String)
          : null,
    );
  }
}
