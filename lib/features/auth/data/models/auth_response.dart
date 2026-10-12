class AuthResponse {
  final String token;
  final String type;
  final int? idUtilisateur;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? role;
  final String? quartier;
  final bool? estActif;
  final int? idStructure;
  final bool? estResponsable;

  const AuthResponse({
    required this.token,
    this.type = 'Bearer',
    this.idUtilisateur,
    this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.role,
    this.quartier,
    this.estActif,
    this.idStructure,
    this.estResponsable,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      type: json['type'] as String? ?? 'Bearer',
      idUtilisateur: (json['idUtilisateur'] as num?)?.toInt(),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      quartier: json['quartier'] as String?,
      estActif: json['estActif'] as bool?,
      idStructure: (json['idStructure'] as num?)?.toInt(),
      estResponsable: json['estResponsable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'idUtilisateur': idUtilisateur,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'role': role,
      'quartier': quartier,
      'estActif': estActif,
      'idStructure': idStructure,
      'estResponsable': estResponsable,
    };
  }
}
