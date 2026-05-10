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

class UserProfile {
  final int? id;
  final ContratType typeContrat;
  final LogementType situationLogement;
  final double? loyerMensuel;
  final double objectifEpargne;
  final int rappelJoursAvant;

  const UserProfile({
    this.id,
    required this.typeContrat,
    required this.situationLogement,
    this.loyerMensuel,
    required this.objectifEpargne,
    this.rappelJoursAvant = 3,
  });

  UserProfile copyWith({
    int? id,
    ContratType? typeContrat,
    LogementType? situationLogement,
    double? loyerMensuel,
    bool clearLoyer = false,
    double? objectifEpargne,
    int? rappelJoursAvant,
  }) {
    return UserProfile(
      id: id ?? this.id,
      typeContrat: typeContrat ?? this.typeContrat,
      situationLogement: situationLogement ?? this.situationLogement,
      loyerMensuel: clearLoyer ? null : loyerMensuel ?? this.loyerMensuel,
      objectifEpargne: objectifEpargne ?? this.objectifEpargne,
      rappelJoursAvant: rappelJoursAvant ?? this.rappelJoursAvant,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type_contrat': typeContrat.name,
        'situation_logement': situationLogement.name,
        'loyer_mensuel': loyerMensuel,
        'objectif_epargne': objectifEpargne,
        'rappel_jours_avant': rappelJoursAvant,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as int?,
        typeContrat: ContratType.values.firstWhere((e) => e.name == map['type_contrat']),
        situationLogement: LogementType.values.firstWhere((e) => e.name == map['situation_logement']),
        loyerMensuel: map['loyer_mensuel'] as double?,
        objectifEpargne: (map['objectif_epargne'] as num).toDouble(),
        rappelJoursAvant: map['rappel_jours_avant'] as int? ?? 3,
      );
}
