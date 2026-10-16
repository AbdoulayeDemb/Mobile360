class SosStructure {
  final int idStructure;
  final String nomStructure;
  final String? quartier;
  final String typeStructure;
  final String? telephoneUrgence;
  final double distanceEnMetres;

  const SosStructure({
    required this.idStructure,
    required this.nomStructure,
    this.quartier,
    required this.typeStructure,
    this.telephoneUrgence,
    required this.distanceEnMetres,
  });

  factory SosStructure.fromJson(Map<String, dynamic> json) {
    return SosStructure(
      idStructure: (json['idStructure'] as num).toInt(),
      nomStructure: json['nomStructure']?.toString() ?? '',
      quartier: json['quartier']?.toString(),
      typeStructure: json['typeStructure']?.toString() ?? '',
      telephoneUrgence: json['telephoneUrgence']?.toString(),
      distanceEnMetres: (json['distanceEnMetres'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idStructure': idStructure,
      'nomStructure': nomStructure,
      'quartier': quartier,
      'typeStructure': typeStructure,
      'telephoneUrgence': telephoneUrgence,
      'distanceEnMetres': distanceEnMetres,
    };
  }

  /// Indique si la structure est un poste de police.
  bool get estPolice => typeStructure.toUpperCase() == 'POLICE';

  /// Indique si la structure est une caserne de sapeurs-pompiers.
  bool get estPompier => typeStructure.toUpperCase() == 'SAPEURS_POMPIERS';

  /// Libellé lisible du type de structure.
  String get typeFormate {
    if (estPolice) return 'Police';
    if (estPompier) return 'Sapeurs-pompiers';
    return typeStructure;
  }

  /// Distance affichée dans la liste des structures proches.
  String get distanceFormatee {
    if (distanceEnMetres >= 1000) {
      final distanceKm = distanceEnMetres / 1000;
      return '${distanceKm.toStringAsFixed(1)} km';
    }

    return '${distanceEnMetres.round()} m';
  }

  /// Indique si un numéro d'urgence est disponible.
  bool get possedeTelephone =>
      telephoneUrgence != null && telephoneUrgence!.trim().isNotEmpty;
}
