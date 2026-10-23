import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'mission_ui.dart';

/// En-tête des écrans agent : retour, titre, sous-titre et action optionnelle.
class AgentPageHeader extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final Widget? action;
  final VoidCallback? onBack;

  const AgentPageHeader({
    super.key,
    required this.titre,
    required this.sousTitre,
    this.action,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEEF2F7),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sousTitre,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MissionUi.bleuLien,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 10), action!],
        ],
      ),
    );
  }
}
