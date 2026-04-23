class HistoriqueModel {
  final String action;
  final String? par;
  final String? date;
  final String? commentaire;

  HistoriqueModel({
    required this.action,
    this.par,
    this.date,
    this.commentaire,
  });

  factory HistoriqueModel.fromJson(Map<String, dynamic> json) {
    return HistoriqueModel(
      action: json['action'] ?? '',
      par: json['par'],
      date: json['date'],
      commentaire: json['commentaire'],
    );
  }
}
