class Signalement {
  final int? idSignalement;
  final String? codeTrackingUnique;
  final String? typeUrgence;
  final String? statut;
  final String? description;
  final double? latitudeGPS;
  final double? longitudeGPS;
  final String? repereVisuel;
  final String? photoAvantUrl;
  final String? audioUrl;
  final DateTime? dateHeureAlerte;
  final int? citoyenId;
  final String? citoyenNomComplet;
  final int? categorieId;
  final String? categorieNom;
  final int? structureAssigneeId;
  final String? structureAssigneeNom;
  final int? agentAssigneId;

  const Signalement({
    this.idSignalement,
    this.codeTrackingUnique,
    this.typeUrgence,
    this.statut,
    this.description,
    this.latitudeGPS,
    this.longitudeGPS,
    this.repereVisuel,
    this.photoAvantUrl,
    this.audioUrl,
    this.dateHeureAlerte,
    this.citoyenId,
    this.citoyenNomComplet,
    this.categorieId,
    this.categorieNom,
    this.structureAssigneeId,
    this.structureAssigneeNom,
    this.agentAssigneId,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      idSignalement: (json['idSignalement'] as num?)?.toInt(),
      codeTrackingUnique: json['codeTrackingUnique'] as String?,
      typeUrgence: json['typeUrgence'] as String?,
      statut: json['statut'] as String?,
      description: json['description'] as String?,
      latitudeGPS: (json['latitudeGPS'] as num?)?.toDouble(),
      longitudeGPS: (json['longitudeGPS'] as num?)?.toDouble(),
      repereVisuel: json['repereVisuel'] as String?,
      photoAvantUrl: json['photoAvantUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      dateHeureAlerte: json['dateHeureAlerte'] == null
          ? null
          : DateTime.tryParse(json['dateHeureAlerte'] as String),
      citoyenId: (json['citoyenId'] as num?)?.toInt(),
      citoyenNomComplet: json['citoyenNomComplet'] as String?,
      categorieId: (json['categorieId'] as num?)?.toInt(),
      categorieNom: json['categorieNom'] as String?,
      structureAssigneeId: (json['structureAssigneeId'] as num?)?.toInt(),
      structureAssigneeNom: json['structureAssigneeNom'] as String?,
      agentAssigneId: (json['agentAssigneId'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSignalement': idSignalement,
      'codeTrackingUnique': codeTrackingUnique,
      'typeUrgence': typeUrgence,
      'statut': statut,
      'description': description,
      'latitudeGPS': latitudeGPS,
      'longitudeGPS': longitudeGPS,
      'repereVisuel': repereVisuel,
      'photoAvantUrl': photoAvantUrl,
      'audioUrl': audioUrl,
      'dateHeureAlerte': dateHeureAlerte?.toIso8601String(),
      'citoyenId': citoyenId,
      'citoyenNomComplet': citoyenNomComplet,
      'categorieId': categorieId,
      'categorieNom': categorieNom,
      'structureAssigneeId': structureAssigneeId,
      'structureAssigneeNom': structureAssigneeNom,
      'agentAssigneId': agentAssigneId,
    };
  }
}
