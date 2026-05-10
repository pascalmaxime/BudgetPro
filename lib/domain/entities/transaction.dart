enum TransactionType {
  revenu('Revenu'),
  depenseFixe('Dépense fixe'),
  depenseVariable('Dépense variable'),
  epargne('Épargne');

  const TransactionType(this.label);
  final String label;
}

enum CategorieTransaction {
  salaire('Salaire'),
  apl('APL / Aide logement'),
  autreRevenu('Autre revenu'),
  loyer('Loyer / Charges'),
  alimentation('Alimentation'),
  transport('Transport'),
  sante('Santé'),
  vetements('Vêtements'),
  loisirs('Loisirs'),
  restaurant('Restaurant & sorties'),
  epargne('Épargne'),
  autre('Autre');

  const CategorieTransaction(this.label);
  final String label;
}

class Transaction {
  final String id;
  final String mois; // YYYY-MM
  final double montant;
  final String description;
  final CategorieTransaction categorie;
  final DateTime date;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.mois,
    required this.montant,
    required this.description,
    required this.categorie,
    required this.date,
    required this.type,
  });

  Transaction copyWith({
    String? mois,
    double? montant,
    String? description,
    CategorieTransaction? categorie,
    DateTime? date,
    TransactionType? type,
  }) {
    return Transaction(
      id: id,
      mois: mois ?? this.mois,
      montant: montant ?? this.montant,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'mois': mois,
        'montant': montant,
        'description': description,
        'categorie': categorie.name,
        'date': date.toIso8601String(),
        'type': type.name,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        mois: map['mois'] as String,
        montant: (map['montant'] as num).toDouble(),
        description: map['description'] as String,
        categorie: CategorieTransaction.values.firstWhere((e) => e.name == map['categorie']),
        date: DateTime.parse(map['date'] as String),
        type: TransactionType.values.firstWhere((e) => e.name == map['type']),
      );
}
