class PrimeSalaireModel {
  final String libelle;
  final double montant;

  PrimeSalaireModel({required this.libelle, required this.montant});

  factory PrimeSalaireModel.fromJson(Map<String, dynamic> json) {
    return PrimeSalaireModel(
      libelle: json['libelle'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'libelle': libelle, 'montant': montant};
}

