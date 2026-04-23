class DeductionSalaireModel {
  final String libelle;
  final double montant;

  DeductionSalaireModel({required this.libelle, required this.montant});

  factory DeductionSalaireModel.fromJson(Map<String, dynamic> json) {
    return DeductionSalaireModel(
      libelle: json['libelle'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'libelle': libelle, 'montant': montant};
}
