class JournalInfoModel {
  final int id;
  final String? code;
  final String nom;

  JournalInfoModel({required this.id, this.code, required this.nom});

  factory JournalInfoModel.fromJson(Map<String, dynamic> json) {
    return JournalInfoModel(
      id: json['id'] ?? 0,
      code: json['code'],
      nom: json['nom'] ?? '',
    );
  }
}
