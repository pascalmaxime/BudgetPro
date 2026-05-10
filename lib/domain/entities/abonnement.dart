enum FrequenceType {
  mensuel('Mensuel'),
  annuel('Annuel');

  const FrequenceType(this.label);
  final String label;
}

enum CategorieAbonnement {
  streaming('Streaming vidéo'),
  musique('Musique'),
  sport('Sport & fitness'),
  logiciels('Logiciels'),
  presse('Presse & livres'),
  autre('Autre');

  const CategorieAbonnement(this.label);
  final String label;
}

class Abonnement {
  final String id;
  final String nom;
  final double montant;
  final FrequenceType frequence;
  final DateTime dateRenouvellement;
  final CategorieAbonnement categorie;
  final bool actif;

  const Abonnement({
    required this.id,
    required this.nom,
    required this.montant,
    required this.frequence,
    required this.dateRenouvellement,
    required this.categorie,
    this.actif = true,
  });

  double get montantMensuel =>
      frequence == FrequenceType.annuel ? montant / 12 : montant;

  int get joursAvantRenouvellement {
    final now = DateTime.now();
    final prochainRenouvellement = _prochainRenouvellement(now);
    return prochainRenouvellement.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  DateTime _prochainRenouvellement(DateTime now) {
    var date = dateRenouvellement;
    while (date.isBefore(now)) {
      date = frequence == FrequenceType.mensuel
          ? DateTime(date.year, date.month + 1, date.day)
          : DateTime(date.year + 1, date.month, date.day);
    }
    return date;
  }

  DateTime get prochainRenouvellement => _prochainRenouvellement(DateTime.now());

  Abonnement copyWith({
    String? nom,
    double? montant,
    FrequenceType? frequence,
    DateTime? dateRenouvellement,
    CategorieAbonnement? categorie,
    bool? actif,
  }) {
    return Abonnement(
      id: id,
      nom: nom ?? this.nom,
      montant: montant ?? this.montant,
      frequence: frequence ?? this.frequence,
      dateRenouvellement: dateRenouvellement ?? this.dateRenouvellement,
      categorie: categorie ?? this.categorie,
      actif: actif ?? this.actif,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'montant': montant,
        'frequence': frequence.name,
        'date_renouvellement': dateRenouvellement.toIso8601String(),
        'categorie': categorie.name,
        'actif': actif ? 1 : 0,
      };

  factory Abonnement.fromMap(Map<String, dynamic> map) => Abonnement(
        id: map['id'] as String,
        nom: map['nom'] as String,
        montant: (map['montant'] as num).toDouble(),
        frequence: FrequenceType.values.firstWhere((e) => e.name == map['frequence']),
        dateRenouvellement: DateTime.parse(map['date_renouvellement'] as String),
        categorie: CategorieAbonnement.values.firstWhere((e) => e.name == map['categorie']),
        actif: (map['actif'] as int) == 1,
      );
}
