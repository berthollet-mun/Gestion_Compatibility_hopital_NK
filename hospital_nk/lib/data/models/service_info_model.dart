class ServiceInfoModel {
  final int id;
  final String nom;
  final String? code;

  ServiceInfoModel({required this.id, required this.nom, this.code});

  factory ServiceInfoModel.fromJson(Map<String, dynamic> json) {
    return ServiceInfoModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      code: json['code'],
    );
  }
}
