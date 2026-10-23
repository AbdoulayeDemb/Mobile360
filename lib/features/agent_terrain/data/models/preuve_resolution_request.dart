class PreuveResolutionRequest {
  final int idSignalement;
  final String typePreuve;
  final String? photoApresUrl;
  final String? rapportTexte;

  const PreuveResolutionRequest({
    required this.idSignalement,
    required this.typePreuve,
    this.photoApresUrl,
    this.rapportTexte,
  });

  Map<String, dynamic> toJson() {
    return {
      'idSignalement': idSignalement,
      'typePreuve': typePreuve,
      'photoApresUrl': photoApresUrl,
      'rapportTexte': rapportTexte,
    };
  }
}
