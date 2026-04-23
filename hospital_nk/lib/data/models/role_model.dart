class RoleModel {
  final int id;
  final String nom;
  final String slug;
  final String? description;
  final int? nbUtilisateurs;
  final int? permissionsCount;
  final List<String>? permissions;

  RoleModel({
    required this.id,
    required this.nom,
    required this.slug,
    this.description,
    this.nbUtilisateurs,
    this.permissionsCount,
    this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      nbUtilisateurs: json['nb_utilisateurs'],
      permissionsCount: json['permissions_count'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'slug': slug,
        'description': description,
        'permissions': permissions,
      };
}
