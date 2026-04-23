import 'package:hospital_comptabilite/data/models/compte_info_model.dart';

class LigneEcritureModel {
  final int? id;
  final int? compteId;
  final CompteInfoModel? compte;
  final String libelle;
  final double debit;
  final double credit;
  final String? devise;

  LigneEcritureModel({
    this.id,
    this.compteId,
    this.compte,
    required this.libelle,
    required this.debit,
    required this.credit,
    this.devise,
  });

  factory LigneEcritureModel.fromJson(Map<String, dynamic> json) {
    return LigneEcritureModel(
      id: json['id'],
      compteId: json['compte_id'],
      compte: json['compte'] != null ? CompteInfoModel.fromJson(json['compte']) : null,
      libelle: json['libelle'] ?? '',
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      devise: json['devise'] ?? 'CDF',
    );
  }

  Map<String, dynamic> toJson() => {
    'compte_id': compteId,
    'libelle': libelle,
    'debit': debit,
    'credit': credit,
    'devise': devise ?? 'CDF',
  };
}
