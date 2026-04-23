import 'package:hospital_comptabilite/data/models/linge_facture_model.dart';

class FactureModel {
  final int id;
  final String numero;
  final String type;
  final String? clientNom;
  final String? clientTelephone;
  final int? fournisseurId;
  final double montantHt;
  final double montantTva;
  final double montantTtc;
  final String statut;
  final String dateFacture;
  final String? dateEcheance;
  final List<LigneFactureModel> lignes;

  FactureModel({
    required this.id,
    required this.numero,
    required this.type,
    this.clientNom,
    this.clientTelephone,
    this.fournisseurId,
    required this.montantHt,
    required this.montantTva,
    required this.montantTtc,
    required this.statut,
    required this.dateFacture,
    this.dateEcheance,
    this.lignes = const [],
  });

  /// Aliases used by views
  String? get tiersNom => clientNom;
  double get montantTotal => montantTtc;

  factory FactureModel.fromJson(Map<String, dynamic> json) {
    return FactureModel(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      type: json['type'] ?? 'CLIENT',
      clientNom: json['client_nom'],
      clientTelephone: json['client_telephone'],
      fournisseurId: json['fournisseur_id'],
      montantHt: (json['montant_ht'] ?? 0).toDouble(),
      montantTva: (json['montant_tva'] ?? 0).toDouble(),
      montantTtc: (json['montant_ttc'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'EMISE',
      dateFacture: json['date_facture'] ?? '',
      dateEcheance: json['date_echeance'],
      lignes: json['lignes'] != null
          ? (json['lignes'] as List).map((l) => LigneFactureModel.fromJson(l)).toList()
          : [],
    );
  }
}
