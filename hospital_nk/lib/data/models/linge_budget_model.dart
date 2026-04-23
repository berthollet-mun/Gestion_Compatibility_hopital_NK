class LigneBudgetModel {
  final int? id;
  final int? compteId;
  final Map<String, dynamic>? compte;
  final String libelle;
  final double montantPrevu;
  final double? montantRealise;
  final double? ecart;
  final double? taux;
  final String? statutEcart;

  LigneBudgetModel({
    this.id,
    this.compteId,
    this.compte,
    required this.libelle,
    required this.montantPrevu,
    this.montantRealise,
    this.ecart,
    this.taux,
    this.statutEcart,
  });

  factory LigneBudgetModel.fromJson(Map<String, dynamic> json) {
    return LigneBudgetModel(
      id: json['id'],
      compteId: json['compte_id'],
      compte: json['compte'],
      libelle: json['libelle'] ?? '',
      montantPrevu: (json['montant_prevu'] ?? 0).toDouble(),
      montantRealise: json['montant_realise']?.toDouble(),
      ecart: json['ecart']?.toDouble(),
      taux: json['taux']?.toDouble(),
      statutEcart: json['statut_ecart'],
    );
  }

  Map<String, dynamic> toJson() => {
        'compte_id': compteId,
        'libelle': libelle,
        'montant_prevu': montantPrevu,
      };
}
