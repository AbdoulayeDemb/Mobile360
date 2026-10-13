import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingSecondScreen extends StatelessWidget {
  final VoidCallback? onNext;

  const OnboardingSecondScreen({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Logo Alert'360
              SizedBox(
                width: 130, // 👈 Définissez la largeur souhaitée ici
                height: 130, // 👈 Définissez la hauteur souhaitée ici
                child: Image.asset(
                  'assets/images/logo/logo_alert360.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // Illustration principale : accident et solidarité
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Image.asset(
                      'assets/images/onboarding/onboarding_accident.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Titre
              const Text(
                'Urgence et Solidarité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.darkBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Face à un accident grave, chaque geste compte. "
                  "Soyez le lien vital entre la victime et les secours "
                  "avec Alert'360.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Indicateur de progression : deuxième écran sur trois
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInactiveDot(),
                  const SizedBox(width: 6),

                  Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(width: 6),
                  _buildInactiveDot(),
                ],
              ),

              const SizedBox(height: 32),

              // Bouton Suivant
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Suivant',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Point inactif de l'indicateur
  Widget _buildInactiveDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.inactiveDot,
        shape: BoxShape.circle,
      ),
    );
  }
}
