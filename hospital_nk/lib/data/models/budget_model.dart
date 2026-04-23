import 'package:hospital_comptabilite/data/models/linge_budget_model.dart';

class BudgetModel {
  final int id;
  final String titre;
  final Map<String, dynamic>? exercice;
  final Map<String, dynamic>? service;
  final double montantTotal;
  final double? montantConsomme;
  final double? tauxExecution;
  final String statut;
  final String? approuvePar;
  final String? dateApprobation;
  final List<LigneBudgetModel> lignes;

  BudgetModel({
    required this.id,
    required this.titre,
    this.exercice,
    this.service,
    required this.montantTotal,
    this.montantConsomme,
    this.tauxExecution,
    required this.statut,
    this.approuvePar,
    this.dateApprobation,
    this.lignes = const [],
  });

  /// Aliases used by views
  String get libelle => titre;
  double? get montantRealise => montantConsomme;

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'exercice_id': exercice?['id'],
        'service_id': service?['id'],
        'lignes': lignes.map((l) => l.toJson()).toList(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      exercice: json['exercice'],
      service: json['service'],
      montantTotal: (json['montant_total'] ?? 0).toDouble(),
      montantConsomme: json['montant_consomme']?.toDouble(),
      tauxExecution: json['taux_execution']?.toDouble(),
      statut: json['statut'] ?? 'BROUILLON',
      approuvePar: json['approuve_par'],
      dateApprobation: json['date_approbation'],
      lignes: json['lignes'] != null
          ? (json['lignes'] as List).map((l) => LigneBudgetModel.fromJson(l)).toList()
          : [],
    );
  }
}

