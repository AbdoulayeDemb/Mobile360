class SignalementRequest {
  final String typeUrgence;
  final String description;
  final double latitudeGPS;
  final double longitudeGPS;
  final int citoyenId;
  final int categorieId;

  final String? photoAvantUrl;
  final String? audioUrl;
  final String? repereVisuel;

  const SignalementRequest({
    required this.typeUrgence,
    required this.description,
    required this.latitudeGPS,
    required this.longitudeGPS,
    required this.citoyenId,
    required this.categorieId,
    this.photoAvantUrl,
    this.audioUrl,
    this.repereVisuel,
  });

  Map<String, dynamic> toJson() {
    return {
      'typeUrgence': typeUrgence,
      'description': description,
      'latitudeGPS': latitudeGPS,
      'longitudeGPS': longitudeGPS,
      'citoyenId': citoyenId,
      'categorieId': categorieId,
      'photoAvantUrl': photoAvantUrl,
      'audioUrl': audioUrl,
      'repereVisuel': repereVisuel,
    };
  }
}
