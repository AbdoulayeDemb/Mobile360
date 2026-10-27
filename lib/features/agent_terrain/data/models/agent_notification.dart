class AgentNotification {
  final int idNotification;
  final String type;
  final String titre;
  final String message;
  final bool estLue;
  final DateTime? dateCreation;
  final String? referenceType;
  final int? referenceId;

  const AgentNotification({
    required this.idNotification,
    required this.type,
    required this.titre,
    required this.message,
    required this.estLue,
    this.dateCreation,
    this.referenceType,
    this.referenceId,
  });

  factory AgentNotification.fromJson(Map<String, dynamic> json) {
    return AgentNotification(
      idNotification: (json['idNotification'] as num).toInt(),
      type: json['type'] as String,
      titre: json['titre'] as String,
      message: json['message'] as String,
      estLue: json['estLue'] as bool? ?? false,
      dateCreation: json['dateCreation'] == null
          ? null
          : DateTime.tryParse(json['dateCreation'] as String),
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
    );
  }
}
