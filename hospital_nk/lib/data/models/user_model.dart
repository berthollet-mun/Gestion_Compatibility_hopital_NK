import 'package:hospital_comptabilite/data/models/role_model.dart';
import 'package:hospital_comptabilite/data/models/service_info_model.dart';

class UserModel {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photo;
  final String statut;
  final RoleModel role;
  final ServiceInfoModel? service;
  final String? derniereConnexion;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photo,
    required this.statut,
    required this.role,
    this.service,
    this.derniereConnexion,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$prenom $nom';
  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      photo: json['photo'],
      statut: json['statut'] ?? 'ACTIF',
      role: json['role'] != null
          ? RoleModel.fromJson(json['role'])
          : RoleModel(id: 0, nom: '', slug: ''),
      service: json['service'] != null
          ? ServiceInfoModel.fromJson(json['service'])
          : null,
      derniereConnexion: json['derniere_connexion'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'statut': statut,
        'role_id': role.id,
        'service_id': service?.id,
      };
}
