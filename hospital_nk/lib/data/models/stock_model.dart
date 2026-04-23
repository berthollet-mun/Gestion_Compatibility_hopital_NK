class StockModel {
  final int id;
  final String code;
  final String nom;
  final String? description;
  final int? categorieId;
  final String? unite;
  final double prixUnitaire;
  final int stockActuel;
  final int? stockMinimum;
  final int? stockMaximum;
  final double? valeurStock;
  final String? statutStock;
  final int? compteComptableId;
  final String? dateExpiration;
  final String? createdAt;

  StockModel({
    required this.id,
    required this.code,
    required this.nom,
    this.description,
    this.categorieId,
    this.unite,
    required this.prixUnitaire,
    required this.stockActuel,
    this.stockMinimum,
    this.stockMaximum,
    this.valeurStock,
    this.statutStock,
    this.compteComptableId,
    this.dateExpiration,
    this.createdAt,
  });

  bool get isEnRupture => stockActuel == 0;
  bool get isStockFaible => stockMinimum != null && stockActuel <= stockMinimum!;
  bool get isNormal => !isEnRupture && !isStockFaible;

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      categorieId: json['categorie_id'],
      unite: json['unite'],
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      stockActuel: json['stock_actuel'] ?? 0,
      stockMinimum: json['stock_minimum'],
      stockMaximum: json['stock_maximum'],
      valeurStock: json['valeur_stock']?.toDouble(),
      statutStock: json['statut_stock'],
      compteComptableId: json['compte_comptable_id'],
      dateExpiration: json['date_expiration'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'nom': nom,
        'description': description,
        'categorie_id': categorieId,
        'unite': unite,
        'prix_unitaire': prixUnitaire,
        'stock_actuel': stockActuel,
        'stock_minimum': stockMinimum,
        'stock_maximum': stockMaximum,
        'compte_comptable_id': compteComptableId,
      };
}
