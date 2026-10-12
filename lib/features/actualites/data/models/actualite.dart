class Actualite {
  final int idActualite;
  final String titre;
  final String corpsTexte;
  final String? communeCible;
  final bool estUrgent;
  final DateTime? datePublication;
  final int? idAdminAuteur;
  final String? nomAdminAuteur;

  const Actualite({
    required this.idActualite,
    required this.titre,
    required this.corpsTexte,
    this.communeCible,
    required this.estUrgent,
    this.datePublication,
    this.idAdminAuteur,
    this.nomAdminAuteur,
  });

  factory Actualite.fromJson(Map<String, dynamic> json) {
    return Actualite(
      idActualite: (json['idActualite'] as num).toInt(),
      titre: json['titre'] as String,
      corpsTexte: json['corpsTexte'] as String,
      communeCible: json['communeCible'] as String?,
      estUrgent: json['estUrgent'] as bool? ?? false,
      datePublication: DateTime.tryParse(
        json['datePublication'] as String? ?? '',
      ),
      idAdminAuteur: (json['idAdminAuteur'] as num?)?.toInt(),
      nomAdminAuteur: json['nomAdminAuteur'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idActualite': idActualite,
      'titre': titre,
      'corpsTexte': corpsTexte,
      'communeCible': communeCible,
      'estUrgent': estUrgent,
      'datePublication': datePublication?.toIso8601String(),
      'idAdminAuteur': idAdminAuteur,
      'nomAdminAuteur': nomAdminAuteur,
    };
  }
}
