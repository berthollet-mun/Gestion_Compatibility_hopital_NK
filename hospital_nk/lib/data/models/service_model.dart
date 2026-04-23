class ServiceModel {
  final int id;
  final String nom;
  final String code;
  final String? type;
  final Map<String, dynamic>? responsable;
  final double? budgetAnnuel;
  final int? nbEmployes;
  final String statut;
  final String? description;

  ServiceModel({
    required this.id,
    required this.nom,
    required this.code,
    this.type,
    this.responsable,
    this.budgetAnnuel,
    this.nbEmployes,
    required this.statut,
    this.description,
  });

  String? get responsableNom {
    if (responsable == null) return null;
    return '${responsable!['prenom'] ?? ''} ${responsable!['nom'] ?? ''}'.trim();
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      code: json['code'] ?? '',
      type: json['type'],
      responsable: json['responsable'],
      budgetAnnuel: json['budget_annuel']?.toDouble(),
      nbEmployes: json['nb_employes'],
      statut: json['statut'] ?? 'ACTIF',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'code': code,
        'type': type,
        'responsable_id': responsable?['id'],
        'budget_annuel': budgetAnnuel,
        'description': description,
      };
}
