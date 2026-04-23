class ExerciceInfoModel {
  final int id;
  final int annee;

  ExerciceInfoModel({required this.id, required this.annee});

  factory ExerciceInfoModel.fromJson(Map<String, dynamic> json) {
    return ExerciceInfoModel(
      id: json['id'] ?? 0,
      annee: json['annee'] ?? 0,
    );
  }
}
