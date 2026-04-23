class PlanComptableModel {
  final int id;
  final String code;
  final String libelle;
  final int classe;
  final String type;
  final String sensNormal;
  final int? compteParentId;
  final Map<String, dynamic>? compteParent;
  final bool isDetail;
  final bool isActif;
  final double? soldeDebit;
  final double? soldeCredit;
  final String? description;
  final List<PlanComptableModel>? enfants;

  PlanComptableModel({
    required this.id,
    required this.code,
    required this.libelle,
    required this.classe,
    required this.type,
    required this.sensNormal,
    this.compteParentId,
    this.compteParent,
    this.isDetail = true,
    this.isActif = true,
    this.soldeDebit,
    this.soldeCredit,
    this.description,
    this.enfants,
  });

  double get solde => (soldeDebit ?? 0) - (soldeCredit ?? 0);

  factory PlanComptableModel.fromJson(Map<String, dynamic> json) {
    return PlanComptableModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      libelle: json['libelle'] ?? '',
      classe: json['classe'] ?? 0,
      type: json['type'] ?? '',
      sensNormal: json['sens_normal'] ?? 'DEBIT',
      compteParentId: json['compte_parent_id'],
      compteParent: json['compte_parent'],
      isDetail: json['is_detail'] ?? true,
      isActif: json['is_actif'] ?? true,
      soldeDebit: json['solde_debit']?.toDouble(),
      soldeCredit: json['solde_credit']?.toDouble(),
      description: json['description'],
      enfants: json['enfants'] != null
          ? (json['enfants'] as List).map((e) => PlanComptableModel.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'libelle': libelle,
        'classe': classe,
        'type': type,
        'sens_normal': sensNormal,
        'compte_parent_id': compteParentId,
        'is_detail': isDetail,
        'description': description,
      };
}
