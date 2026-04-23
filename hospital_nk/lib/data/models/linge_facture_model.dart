class LigneFactureModel {
  final int? id;
  final String description;
  final int quantite;
  final double prixUnitaire;
  final double? montantTotal;
  final int? compteProduitId;
  final int? compteChargeId;

  LigneFactureModel({
    this.id,
    required this.description,
    required this.quantite,
    required this.prixUnitaire,
    this.montantTotal,
    this.compteProduitId,
    this.compteChargeId,
  });

  double get total => montantTotal ?? (quantite * prixUnitaire);

  factory LigneFactureModel.fromJson(Map<String, dynamic> json) {
    return LigneFactureModel(
      id: json['id'],
      description: json['description'] ?? '',
      quantite: json['quantite'] ?? 1,
      prixUnitaire: (json['prix_unitaire'] ?? 0).toDouble(),
      montantTotal: json['montant_total']?.toDouble(),
      compteProduitId: json['compte_produit_id'],
      compteChargeId: json['compte_charge_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantite': quantite,
        'prix_unitaire': prixUnitaire,
        'compte_produit_id': compteProduitId,
        'compte_charge_id': compteChargeId,
      };
}
