class Utilisateur {
  final int idUtilisateur;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? role;
  final bool? estActif;
  final String? dateCreation;
  final String? matriculeAgent;
  final int? idStructure;
  final String? nomStructure;
  final bool? estResponsable;
  final String? quartier;

  const Utilisateur({
    required this.idUtilisateur,
    this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.role,
    this.estActif,
    this.dateCreation,
    this.matriculeAgent,
    this.idStructure,
    this.nomStructure,
    this.estResponsable,
    this.quartier,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      idUtilisateur: (json['idUtilisateur'] as num).toInt(),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      estActif: json['estActif'] as bool?,
      dateCreation: json['dateCreation'] as String?,
      matriculeAgent: json['matriculeAgent'] as String?,
      idStructure: (json['idStructure'] as num?)?.toInt(),
      nomStructure: json['nomStructure'] as String?,
      estResponsable: json['estResponsable'] as bool?,
      quartier: json['quartier'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idUtilisateur': idUtilisateur,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'role': role,
      'estActif': estActif,
      'dateCreation': dateCreation,
      'matriculeAgent': matriculeAgent,
      'idStructure': idStructure,
      'nomStructure': nomStructure,
      'estResponsable': estResponsable,
      'quartier': quartier,
    };
  }
}
