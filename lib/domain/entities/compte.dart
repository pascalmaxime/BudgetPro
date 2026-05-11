enum CategorieCompte {
  livrets('Livrets réglementés'),
  epargneLogement('Épargne logement'),
  retraite('Retraite'),
  investissement('Investissements'),
  courant('Comptes courants');

  const CategorieCompte(this.label);
  final String label;
}

enum TypeCompte {
  // ── Livrets réglementés ────────────────────────────────────────
  livretA(
    'Livret A',
    CategorieCompte.livrets,
    description: 'Épargne liquide, garantie par l\'État',
    tauxAnnuel: 2.4,
    plafond: 22950,
  ),
  ldd(
    'LDD / LDDS',
    CategorieCompte.livrets,
    description: 'Livret de Développement Durable et Solidaire',
    tauxAnnuel: 2.4,
    plafond: 12000,
  ),
  lep(
    'LEP',
    CategorieCompte.livrets,
    description: 'Livret d\'Épargne Populaire (sous conditions)',
    tauxAnnuel: 3.5,
    plafond: 10000,
  ),
  livretJeune(
    'Livret Jeune',
    CategorieCompte.livrets,
    description: 'Réservé aux 12-25 ans',
    tauxAnnuel: 3.0,
    plafond: 1600,
  ),
  livretBancaire(
    'Livret bancaire',
    CategorieCompte.livrets,
    description: 'Épargne libre chez votre banque',
    tauxAnnuel: null,
    plafond: null,
  ),

  // ── Épargne logement ───────────────────────────────────────────
  pel(
    'PEL',
    CategorieCompte.epargneLogement,
    description: 'Plan d\'Épargne Logement',
    tauxAnnuel: 1.75,
    plafond: 61200,
  ),
  cel(
    'CEL',
    CategorieCompte.epargneLogement,
    description: 'Compte Épargne Logement',
    tauxAnnuel: 1.5,
    plafond: 15300,
  ),

  // ── Retraite ───────────────────────────────────────────────────
  per(
    'PER',
    CategorieCompte.retraite,
    description: 'Plan d\'Épargne Retraite individuel',
    tauxAnnuel: null,
    plafond: null,
  ),
  perco(
    'PERCO / PERO',
    CategorieCompte.retraite,
    description: 'Plan d\'épargne retraite collectif entreprise',
    tauxAnnuel: null,
    plafond: null,
  ),

  // ── Investissements ───────────────────────────────────────────
  pea(
    'PEA',
    CategorieCompte.investissement,
    description: 'Plan d\'Épargne en Actions (max 150 000 €)',
    tauxAnnuel: null,
    plafond: 150000,
  ),
  peaPme(
    'PEA-PME',
    CategorieCompte.investissement,
    description: 'PEA dédié aux PME-ETI (max 225 000 €)',
    tauxAnnuel: null,
    plafond: 225000,
  ),
  assuranceVie(
    'Assurance-vie',
    CategorieCompte.investissement,
    description: 'Enveloppe fiscale avantageuse après 8 ans',
    tauxAnnuel: null,
    plafond: null,
  ),
  cto(
    'CTO',
    CategorieCompte.investissement,
    description: 'Compte-Titres Ordinaire — flexible',
    tauxAnnuel: null,
    plafond: null,
  ),
  crypto(
    'Crypto',
    CategorieCompte.investissement,
    description: 'Portefeuille crypto-actifs',
    tauxAnnuel: null,
    plafond: null,
  ),

  // ── Courants ──────────────────────────────────────────────────
  compteCourant(
    'Compte courant',
    CategorieCompte.courant,
    description: 'Compte de transaction du quotidien',
    tauxAnnuel: null,
    plafond: null,
  ),
  comptePro(
    'Compte pro',
    CategorieCompte.courant,
    description: 'Compte professionnel / freelance',
    tauxAnnuel: null,
    plafond: null,
  );

  const TypeCompte(
    this.label,
    this.categorie, {
    required this.description,
    required this.tauxAnnuel,
    required this.plafond,
  });

  final String label;
  final CategorieCompte categorie;
  final String description;
  final double? tauxAnnuel;
  final int? plafond;

  bool get isInvestissement =>
      categorie == CategorieCompte.investissement ||
      categorie == CategorieCompte.retraite;

  String get tauxLabel =>
      tauxAnnuel != null ? '${tauxAnnuel!.toStringAsFixed(2)} %/an' : '—';

  String get plafondLabel =>
      plafond != null ? '${(plafond! / 1000).toStringAsFixed(0)} k€ max' : '—';
}

class Compte {
  final String id;
  final String nom;
  final TypeCompte type;
  final double solde;
  final String? banque;
  final DateTime? dateOuverture;

  const Compte({
    required this.id,
    required this.nom,
    required this.type,
    required this.solde,
    this.banque,
    this.dateOuverture,
  });

  double? get progressVersPlafond =>
      type.plafond != null ? (solde / type.plafond!).clamp(0.0, 1.0) : null;

  double? get interetsAnnuelsEstimes =>
      type.tauxAnnuel != null ? solde * type.tauxAnnuel! / 100 : null;

  Compte copyWith({
    String? nom,
    TypeCompte? type,
    double? solde,
    String? banque,
    DateTime? dateOuverture,
  }) {
    return Compte(
      id: id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      solde: solde ?? this.solde,
      banque: banque ?? this.banque,
      dateOuverture: dateOuverture ?? this.dateOuverture,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'type': type.name,
        'solde': solde,
        'banque': banque,
        'date_ouverture': dateOuverture?.toIso8601String(),
      };

  factory Compte.fromMap(Map<String, dynamic> map) => Compte(
        id: map['id'] as String,
        nom: map['nom'] as String,
        type: TypeCompte.values.firstWhere((e) => e.name == map['type']),
        solde: (map['solde'] as num).toDouble(),
        banque: map['banque'] as String?,
        dateOuverture: map['date_ouverture'] != null
            ? DateTime.parse(map['date_ouverture'] as String)
            : null,
      );
}
