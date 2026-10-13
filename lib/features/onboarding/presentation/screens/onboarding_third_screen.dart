import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingThirdScreen extends StatelessWidget {
  final VoidCallback? onFinish;

  const OnboardingThirdScreen({super.key, this.onFinish});

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

              // 1. Logo Alert'360
              Center(
                child: Image.asset(
                  'assets/images/logo/logo_alert360.png',
                  height: 85,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // 2. Illustration principale (Troisième écran : Caniveau / Salubrité)
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.0),
                    child: Image.asset(
                      'assets/images/onboarding/onboarding_civism.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 3. Grand titre : Citoyenneté et Cadre de Vie
              const Text(
                'Citoyenneté et Cadre de Vie',
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

              // 4. Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Un caniveau bouché aujourd'hui, c'est une inondation demain. Signalez les insalubrités en un clic avec Alert'360.",
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

              // 5. Indicateur de progression : 3ème point actif (sur 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInactiveDot(), // 1er point inactif
                  const SizedBox(width: 6),
                  _buildInactiveDot(), // 2ème point inactif
                  const SizedBox(width: 6),
                  Container(
                    width: 24, // 3ème point actif (allongé)
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 6. Bouton "Commencer" (Fin de l'onboarding)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Commencer',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
