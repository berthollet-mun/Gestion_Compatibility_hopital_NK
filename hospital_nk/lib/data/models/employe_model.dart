class EmployeModel {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String? email;
  final String? telephone;
  final String? dateNaissance;
  final String? dateEmbauche;
  final Map<String, dynamic>? service;
  final String? poste;
  final String? typeContrat;
  final double salaireBase;
  final String? deviseSalaire;
  final String? numeroCnss;
  final String statut;
  final String? createdAt;

  EmployeModel({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.email,
    this.telephone,
    this.dateNaissance,
    this.dateEmbauche,
    this.service,
    this.poste,
    this.typeContrat,
    required this.salaireBase,
    this.deviseSalaire,
    this.numeroCnss,
    required this.statut,
    this.createdAt,
  });

  String get fullName => '$prenom $nom';
  String get serviceNom => service?['nom'] ?? '-';

  factory EmployeModel.fromJson(Map<String, dynamic> json) {
    return EmployeModel(
      id: json['id'] ?? 0,
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'],
      telephone: json['telephone'],
      dateNaissance: json['date_naissance'],
      dateEmbauche: json['date_embauche'],
      service: json['service'],
      poste: json['poste'],
      typeContrat: json['type_contrat'],
      salaireBase: (json['salaire_base'] ?? 0).toDouble(),
      deviseSalaire: json['devise_salaire'] ?? 'CDF',
      numeroCnss: json['numero_cnss'],
      statut: json['statut'] ?? 'ACTIF',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'date_naissance': dateNaissance,
        'date_embauche': dateEmbauche,
        'service_id': service?['id'],
        'poste': poste,
        'type_contrat': typeContrat,
        'salaire_base': salaireBase,
        'devise_salaire': deviseSalaire ?? 'CDF',
        'numero_cnss': numeroCnss,
        'statut': statut,
      };
}
