/// Statut proposé par l'agent à son responsable dans le rapport.
/// Le backend ne permet pas à un agent de changer le statut :
/// la proposition est donc enregistrée en tête du rapport texte.
enum StatutPropose { enCours, resolu, rejete }

extension StatutProposeLibelle on StatutPropose {
  String get libelle {
    switch (this) {
      case StatutPropose.enCours:
        return 'En cours';
      case StatutPropose.resolu:
        return 'Résolu';
      case StatutPropose.rejete:
        return 'Rejeté/Abus';
    }
  }
}

class PreuveResolution {
  static const String _prefixeStatut = 'Statut proposé : ';

  final int idPreuve;
  final String typePreuve;
  final String? photoApresUrl;
  final String? rapportTexte;
  final DateTime? dateResolution;
  final int? idSignalement;
  final String? nomAgent;
  final String? prenomAgent;
  final String? telephoneAgent;
  final String? matriculeAgent;

  const PreuveResolution({
    required this.idPreuve,
    required this.typePreuve,
    this.photoApresUrl,
    this.rapportTexte,
    this.dateResolution,
    this.idSignalement,
    this.nomAgent,
    this.prenomAgent,
    this.telephoneAgent,
    this.matriculeAgent,
  });

  factory PreuveResolution.fromJson(Map<String, dynamic> json) {
    return PreuveResolution(
      idPreuve: (json['idPreuve'] as num).toInt(),
      typePreuve: json['typePreuve'] as String? ?? 'RAPPORT_AGENT',
      photoApresUrl: json['photoApresUrl'] as String?,
      rapportTexte: json['rapportTexte'] as String?,
      dateResolution: json['dateResolution'] == null
          ? null
          : DateTime.tryParse(json['dateResolution'] as String),
      idSignalement: (json['idSignalement'] as num?)?.toInt(),
      nomAgent: json['nomAgent'] as String?,
      prenomAgent: json['prenomAgent'] as String?,
      telephoneAgent: json['telephoneAgent'] as String?,
      matriculeAgent: json['matriculeAgent'] as String?,
    );
  }

  /// Statut proposé lu depuis la première ligne du rapport.
  StatutPropose get statutPropose {
    final premiereLigne = (rapportTexte ?? '').split('\n').first.trim();

    if (!premiereLigne.startsWith(_prefixeStatut)) {
      return StatutPropose.resolu;
    }

    final valeur = premiereLigne.substring(_prefixeStatut.length).trim();

    return StatutPropose.values.firstWhere(
      (statut) => statut.libelle == valeur,
      orElse: () => StatutPropose.resolu,
    );
  }

  /// Rapport de l'agent sans la ligne du statut proposé.
  String get rapportSansStatut {
    final texte = rapportTexte ?? '';
    final lignes = texte.split('\n');

    if (lignes.isNotEmpty && lignes.first.trim().startsWith(_prefixeStatut)) {
      return lignes.skip(1).join('\n').trim();
    }

    return texte.trim();
  }

  /// Construit le rapport envoyé au backend.
  static String composerRapport(StatutPropose statut, String rapport) {
    return '$_prefixeStatut${statut.libelle}\n${rapport.trim()}';
  }
}
