class CompteInfoModel {
  final int id;
  final String code;
  final String libelle;

  CompteInfoModel({required this.id, required this.code, required this.libelle});

  factory CompteInfoModel.fromJson(Map<String, dynamic> json) {
    return CompteInfoModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      libelle: json['libelle'] ?? '',
    );
  }
}
