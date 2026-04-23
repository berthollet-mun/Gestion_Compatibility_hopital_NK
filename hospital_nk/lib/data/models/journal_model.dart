class JournalModel {
  final int id;
  final String code;
  final String nom;
  final String type;
  final bool isActif;
  final int? nbEcritures;
  final String? description;
  final String? createdAt;

  JournalModel({
    required this.id,
    required this.code,
    required this.nom,
    required this.type,
    this.isActif = true,
    this.nbEcritures,
    this.description,
    this.createdAt,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    return JournalModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      nom: json['nom'] ?? '',
      type: json['type'] ?? '',
      isActif: json['is_actif'] ?? true,
      nbEcritures: json['nb_ecritures'],
      description: json['description'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'nom': nom,
        'type': type,
        'description': description,
      };
}
