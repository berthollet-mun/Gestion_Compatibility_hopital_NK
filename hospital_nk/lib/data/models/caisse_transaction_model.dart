class CaisseTransactionModel {
  final int id;
  final String reference;
  final String type;
  final double montant;
  final String devise;
  final String motif;
  final String? beneficiaire;
  final String? referenceExterne;
  final double? soldeApres;
  final String? dateTransaction;
  final int? compteId;

  CaisseTransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.montant,
    this.devise = 'CDF',
    required this.motif,
    this.beneficiaire,
    this.referenceExterne,
    this.soldeApres,
    this.dateTransaction,
    this.compteId,
  });

  bool get isEntree => type == 'ENTREE';
  bool get isSortie => type == 'SORTIE';

  factory CaisseTransactionModel.fromJson(Map<String, dynamic> json) {
    return CaisseTransactionModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      type: json['type'] ?? 'ENTREE',
      montant: (json['montant'] ?? 0).toDouble(),
      devise: json['devise'] ?? 'CDF',
      motif: json['motif'] ?? '',
      beneficiaire: json['beneficiaire'],
      referenceExterne: json['reference_externe'],
      soldeApres: json['solde_apres']?.toDouble(),
      dateTransaction: json['date_transaction'],
      compteId: json['compte_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'montant': montant,
        'devise': devise,
        'motif': motif,
        'beneficiaire': beneficiaire,
        'reference_externe': referenceExterne,
        'compte_id': compteId,
      };
}
