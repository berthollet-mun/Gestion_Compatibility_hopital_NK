class StockMouvementModel {
  final int id;
  final String type;
  final int quantite;
  final int? stockAvant;
  final int? stockApres;
  final String? produit;
  final String? motif;
  final String? reference;
  final String? date;

  StockMouvementModel({
    required this.id,
    required this.type,
    required this.quantite,
    this.stockAvant,
    this.stockApres,
    this.produit,
    this.motif,
    this.reference,
    this.date,
  });

  factory StockMouvementModel.fromJson(Map<String, dynamic> json) {
    return StockMouvementModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      quantite: json['quantite'] ?? 0,
      stockAvant: json['stock_avant'],
      stockApres: json['stock_apres'],
      produit: json['produit'],
      motif: json['motif'],
      reference: json['reference'],
      date: json['date'],
    );
  }
}