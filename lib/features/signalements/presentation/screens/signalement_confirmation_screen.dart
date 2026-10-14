import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SignalementConfirmationScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onTrackSignalement;

  final String reference;
  final String categoryName;
  final String locationName;
  final String? structureName;
  final String? communeName;
  final String status;

  const SignalementConfirmationScreen({
    super.key,
    this.onBack,
    this.onTrackSignalement,
    required this.reference,
    required this.categoryName,
    required this.locationName,
    required this.structureName,
    this.communeName,
    this.status = 'DECLARE',
  });

  bool get _structureAssignee =>
      structureName != null && structureName!.trim().isNotEmpty;

  String get _statusLabel {
    switch (status.trim().toUpperCase()) {
      case 'EN_COURS':
        return 'En cours';
      case 'RESOLU':
        return 'Résolu';
      case 'REJETE':
        return 'Rejeté';
      case 'DECLARE':
        return 'Déclaré';
      default:
        return status.trim().isEmpty ? 'Non renseigné' : status;
    }
  }

  Color get _statusColor {
    switch (status.trim().toUpperCase()) {
      case 'RESOLU':
        return const Color(0xFF15803D);
      case 'REJETE':
        return const Color(0xFFB91C1C);
      case 'EN_COURS':
        return const Color(0xFFB45309);
      case 'DECLARE':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color get _statusBackgroundColor {
    switch (status.trim().toUpperCase()) {
      case 'RESOLU':
        return const Color(0xFFDCFCE7);
      case 'REJETE':
        return const Color(0xFFFEE2E2);
      case 'EN_COURS':
        return const Color(0xFFFEF3C7);
      case 'DECLARE':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final structureAssignee = _structureAssignee;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.darkBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirmation',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Confirmation de votre signalement',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    // Icône de confirmation
                    Container(
                      height: 88,
                      width: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          height: 64,
                          width: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Signalement enregistré !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Votre déclaration a bien été enregistrée.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Carte récapitulative
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // État de l'affectation
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: structureAssignee
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  structureAssignee
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  color: structureAssignee
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFB45309),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    structureAssignee
                                        ? 'Une structure compétente a été assignée à votre signalement.'
                                        : 'Aucune structure compétente n’est renseignée pour le moment.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: structureAssignee
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Structure renvoyée par le backend
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.home_work_rounded,
                                        color: Color(0xFF2563EB),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            structureAssignee
                                                ? structureName!.trim()
                                                : 'Structure non renseignée',
                                            softWrap: true,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkBlue,
                                            ),
                                          ),
                                          if (communeName != null &&
                                              communeName!
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              communeName!.trim(),
                                              softWrap: true,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),

                                const SizedBox(height: 16),

                                _buildDetailRow(
                                  'N° RÉFÉRENCE :',
                                  reference.trim().isNotEmpty
                                      ? reference.trim()
                                      : 'Non disponible',
                                  isBoldValue: true,
                                ),

                                const SizedBox(height: 12),

                                _buildDetailRow(
                                  'CATÉGORIE :',
                                  categoryName.trim().isNotEmpty
                                      ? categoryName.trim()
                                      : 'Non renseignée',
                                  valueColor: const Color(0xFF2563EB),
                                ),

                                const SizedBox(height: 12),

                                _buildDetailRow(
                                  'LOCALISATION :',
                                  locationName.trim().isNotEmpty
                                      ? locationName.trim()
                                      : 'Non renseignée',
                                ),

                                const SizedBox(height: 16),

                                // Statut réel du signalement
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'STATUT :',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: _statusColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!structureAssignee)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Votre signalement a été enregistré. '
                          'L’affectation à une structure pourra être confirmée '
                          'lorsque cette information sera disponible.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bouton fixe en bas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onTrackSignalement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5998),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SUIVRE MON SIGNALEMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.darkBlue,
            ),
          ),
        ),
      ],
    );
  }
}
