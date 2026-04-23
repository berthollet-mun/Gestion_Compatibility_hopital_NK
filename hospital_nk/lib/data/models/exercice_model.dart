class ExerciceModel {
  final int id;
  final int annee;
  final String dateDebut;
  final String dateFin;
  final String statut;
  final bool isCurrent;
  final int? nbEcritures;
  final double? totalDebit;
  final double? totalCredit;
  final int? joursRestants;

  ExerciceModel({
    required this.id,
    required this.annee,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    required this.isCurrent,
    this.nbEcritures,
    this.totalDebit,
    this.totalCredit,
    this.joursRestants,
  });

  factory ExerciceModel.fromJson(Map<String, dynamic> json) {
    return ExerciceModel(
      id: json['id'] ?? 0,
      annee: json['annee'] ?? 0,
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      statut: json['statut'] ?? 'OUVERT',
      isCurrent: json['is_current'] ?? false,
      nbEcritures: json['nb_ecritures'],
      totalDebit: json['total_debit']?.toDouble(),
      totalCredit: json['total_credit']?.toDouble(),
      joursRestants: json['jours_restants'],
    );
  }
}