class ContenuEducatif {
  final int idContenu;
  final String titre;
  final String theme;
  final String format;
  final String mediaUrl;
  final DateTime? datePublication;
  final int? auteurId;
  final String? nomAuteur;

  const ContenuEducatif({
    required this.idContenu,
    required this.titre,
    required this.theme,
    required this.format,
    required this.mediaUrl,
    this.datePublication,
    this.auteurId,
    this.nomAuteur,
  });

  factory ContenuEducatif.fromJson(Map<String, dynamic> json) {
    return ContenuEducatif(
      idContenu: (json['idContenu'] as num).toInt(),
      titre: json['titre'] as String,
      theme: json['theme'] as String,
      format: json['format'] as String,
      mediaUrl: json['mediaUrl'] as String,
      datePublication: json['datePublication'] == null
          ? null
          : DateTime.tryParse(json['datePublication'] as String),
      auteurId: (json['auteurId'] as num?)?.toInt(),
      nomAuteur: json['nomAuteur'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idContenu': idContenu,
      'titre': titre,
      'theme': theme,
      'format': format,
      'mediaUrl': mediaUrl,
      'datePublication': datePublication?.toIso8601String(),
      'auteurId': auteurId,
      'nomAuteur': nomAuteur,
    };
  }
}
