class CaisseModel {
  final int id;
  final String reference;
  final Map<String, dynamic>? caissier;
  final String dateOuverture;
  final String? dateFermeture;
  final double soldeOuverture;
  final double? soldeTheorique;
  final double? soldeReel;
  final double? ecart;
  final String statut;
  final int? nbTransactions;
  final double? totalEntrees;
  final double? totalSorties;
  final String? commentaire;

  CaisseModel({
    required this.id,
    required this.reference,
    this.caissier,
    required this.dateOuverture,
    this.dateFermeture,
    required this.soldeOuverture,
    this.soldeTheorique,
    this.soldeReel,
    this.ecart,
    required this.statut,
    this.nbTransactions,
    this.totalEntrees,
    this.totalSorties,
    this.commentaire,
  });

  String get caissierNom {
    if (caissier == null) return '-';
    return '${caissier!['prenom'] ?? ''} ${caissier!['nom'] ?? ''}'.trim();
  }

  bool get isOuverte => statut == 'OUVERTE';

  factory CaisseModel.fromJson(Map<String, dynamic> json) {
    return CaisseModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      caissier: json['caissier'],
      dateOuverture: json['date_ouverture'] ?? '',
      dateFermeture: json['date_fermeture'],
      soldeOuverture: (json['solde_ouverture'] ?? 0).toDouble(),
      soldeTheorique: json['solde_theorique']?.toDouble(),
      soldeReel: json['solde_reel']?.toDouble(),
      ecart: json['ecart']?.toDouble(),
      statut: json['statut'] ?? 'OUVERTE',
      nbTransactions: json['nb_transactions'],
      totalEntrees: json['total_entrees']?.toDouble(),
      totalSorties: json['total_sorties']?.toDouble(),
      commentaire: json['commentaire'],
    );
  }
}
