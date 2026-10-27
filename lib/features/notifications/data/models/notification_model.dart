class NotificationModel {
  final int idNotification;
  final String type;
  final String titre;
  final String message;
  final bool estLue;
  final DateTime? dateCreation;
  final String? referenceType;
  final int? referenceId;

  const NotificationModel({
    required this.idNotification,
    required this.type,
    required this.titre,
    required this.message,
    required this.estLue,
    this.dateCreation,
    this.referenceType,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotification: (json['idNotification'] as num).toInt(),
      type: json['type']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      estLue: json['estLue'] == true,
      dateCreation: json['dateCreation'] != null
          ? DateTime.tryParse(json['dateCreation'].toString())
          : null,
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId'] == null
          ? null
          : (json['referenceId'] as num).toInt(),
    );
  }

  bool get estUrgente => type == 'ALERTE_URGENTE';
}
