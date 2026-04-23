import 'package:hospital_comptabilite/data/models/exercice_info_model.dart';
import 'package:hospital_comptabilite/data/models/historique_model.dart';
import 'package:hospital_comptabilite/data/models/journal_info_model.dart';
import 'package:hospital_comptabilite/data/models/linge_ecriture.dart';

class EcritureModel {
  final int id;
  final String numero;
  final String dateEcriture;
  final String libelle;
  final String? referenceExterne;
  final JournalInfoModel? journal;
  final ExerciceInfoModel? exercice;
  final String statut;
  final double totalDebit;
  final double totalCredit;
  final bool estEquilibree;
  final List<LigneEcritureModel> lignes;
  final List<HistoriqueModel> historique;
  final Map<String, dynamic>? saisieePar;
  final Map<String, dynamic>? validePar;
  final String? datesoumission;
  final String? dateValidation;
  final int? nbLignes;
  final String? createdAt;

  EcritureModel({
    required this.id,
    required this.numero,
    required this.dateEcriture,
    required this.libelle,
    this.referenceExterne,
    this.journal,
    this.exercice,
    required this.statut,
    required this.totalDebit,
    required this.totalCredit,
    required this.estEquilibree,
    this.lignes = const [],
    this.historique = const [],
    this.saisieePar,
    this.validePar,
    this.datesoumission,
    this.dateValidation,
    this.nbLignes,
    this.createdAt,
  });

  /// Alias used by views
  String get reference => numero;
  double get montantTotal => totalDebit;

  factory EcritureModel.fromJson(Map<String, dynamic> json) {
    return EcritureModel(
      id: json['id'] ?? 0,
      numero: json['numero'] ?? '',
      dateEcriture: json['date_ecriture'] ?? '',
      libelle: json['libelle'] ?? '',
      referenceExterne: json['reference'],
      journal: json['journal'] != null ? JournalInfoModel.fromJson(json['journal']) : null,
      exercice: json['exercice'] != null ? ExerciceInfoModel.fromJson(json['exercice']) : null,
      statut: json['statut'] ?? 'BROUILLON',
      totalDebit: (json['total_debit'] ?? 0).toDouble(),
      totalCredit: (json['total_credit'] ?? 0).toDouble(),
      estEquilibree: json['est_equilibree'] ?? false,
      lignes: json['lignes'] != null
          ? (json['lignes'] as List).map((l) => LigneEcritureModel.fromJson(l)).toList()
          : [],
      historique: json['historique'] != null
          ? (json['historique'] as List).map((h) => HistoriqueModel.fromJson(h)).toList()
          : [],
      saisieePar: json['saisie_par'],
      validePar: json['valide_par'],
      datesoumission: json['date_soumission'],
      dateValidation: json['date_validation'],
      nbLignes: json['nb_lignes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'date_ecriture': dateEcriture,
        'libelle': libelle,
        'reference': referenceExterne,
        'journal_id': journal?.id,
        'exercice_id': exercice?.id,
        'lignes': lignes.map((l) => l.toJson()).toList(),
      };
}
