class CitoyenRequest {
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final String motDePasse;
  final String quartier;

  const CitoyenRequest({
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    required this.motDePasse,
    required this.quartier,
  });

  Map<String, dynamic> toJson() {
    final emailNettoye = email?.trim();

    return {
      'nom': nom.trim(),
      'prenom': prenom.trim(),
      'telephone': telephone.trim(),
      'email': emailNettoye == null || emailNettoye.isEmpty
          ? null
          : emailNettoye,
      'motDePasse': motDePasse,
      'quartier': quartier.trim(),
    };
  }
}
