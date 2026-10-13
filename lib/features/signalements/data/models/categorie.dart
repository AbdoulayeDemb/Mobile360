class Categorie {
  final int idCategorie;
  final String nom;
  final String? typeStructureCible;

  const Categorie({
    required this.idCategorie,
    required this.nom,
    this.typeStructureCible,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      idCategorie: (json['idCategorie'] as num).toInt(),
      nom: json['nom'] as String,
      typeStructureCible: json['typeStructureCible'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCategorie': idCategorie,
      'nom': nom,
      'typeStructureCible': typeStructureCible,
    };
  }
}
