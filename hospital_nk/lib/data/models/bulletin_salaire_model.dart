import 'permission_salaire.dart';

class DeductionSalaireModel {
  final String libelle;
  final double montant;

  DeductionSalaireModel({required this.libelle, required this.montant});

  factory DeductionSalaireModel.fromJson(Map<String, dynamic> json) {
    return DeductionSalaireModel(
      libelle: json['libelle'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'libelle': libelle, 'montant': montant};
}

class BulletinSalaireModel {
  final int id;
  final Map<String, dynamic>? employe;
  final int mois;
  final int annee;
  final double salaireBase;
  final List<PrimeSalaireModel> primes;
  final List<DeductionSalaireModel> deductions;
  final double salaireBrut;
  final double totalDeductions;
  final double salaireNet;
  final String statut;
  final String? createdAt;

  BulletinSalaireModel({
    required this.id,
    this.employe,
    required this.mois,
    required this.annee,
    required this.salaireBase,
    this.primes = const [],
    this.deductions = const [],
    required this.salaireBrut,
    required this.totalDeductions,
    required this.salaireNet,
    required this.statut,
    this.createdAt,
  });

  String get employeNom {
    if (employe == null) return '-';
    return '${employe!['nom'] ?? ''} ${employe!['prenom'] ?? ''}'.trim();
  }

  String get periode => '$mois/$annee';

  factory BulletinSalaireModel.fromJson(Map<String, dynamic> json) {
    return BulletinSalaireModel(
      id: json['id'] ?? 0,
      employe: json['employe'],
      mois: json['mois'] ?? 1,
      annee: json['annee'] ?? 2024,
      salaireBase: (json['salaire_base'] ?? 0).toDouble(),
      primes: json['primes'] != null
          ? (json['primes'] as List).map((p) => PrimeSalaireModel.fromJson(p)).toList()
          : [],
      deductions: json['deductions'] != null
          ? (json['deductions'] as List).map((d) => DeductionSalaireModel.fromJson(d)).toList()
          : [],
      salaireBrut: (json['salaire_brut'] ?? 0).toDouble(),
      totalDeductions: (json['total_deductions'] ?? 0).toDouble(),
      salaireNet: (json['salaire_net'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'BROUILLON',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'employe_id': employe?['id'],
        'mois': mois,
        'annee': annee,
        'salaire_base': salaireBase,
        'primes': primes.map((p) => p.toJson()).toList(),
        'deductions': deductions.map((d) => d.toJson()).toList(),
      };
}
