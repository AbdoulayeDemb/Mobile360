import 'package:flutter/material.dart';

// Import de ton fichier de couleurs thématiques
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback? onNext;

  const OnboardingScreen({super.key, this.onNext});

  @override
  Widget build(BuildContext context) {
    // Scaffold et fond d'écran
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          // Marges horizontales standard de la maquette (24.0)
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16), // Marge du haut (SafeArea)
              // 1. Logo Alert'360 (Agrandissement pour fidélité)

              SizedBox(
                width: 130, // 👈 Définissez la largeur souhaitée ici
                height: 130, // 👈 Définissez la hauteur souhaitée ici
                child: Image.asset(
                  'assets/images/logo/logo_alert360.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(
                height: 32,
              ), // Augmentation de l'espace sous le logo (fidélité)
              // 2. Illustration principale avec coins arrondis
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      24.0,
                    ), // Rayon des coins de la maquette
                    child: Image.asset(
                      // Chemin d'asset que tu as défini
                      'assets/images/onboarding/onboarding_fire.png',
                      width: double.infinity, // L'image occupe toute la largeur
                      fit: BoxFit.cover, // L'image remplit le conteneur en respectant le ratio
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 32,
              ), // Augmentation de l'espace sous l'illustration (fidélité)
              // 3. Grand titre : Alerte Incendie
              const Text(
                'Alerte Incendie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins', // Police de titre demandée
                  color: AppColors.darkBlue, // Couleur thématique (bleu foncé)
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5, // Espacement légèrement négatif (comme sur la maquette)
                ),
              ),

              const SizedBox(height: 12),

              // 4. Description : Inter (avec marges pour alignement maquette)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                ), // Ajustement des marges horizontales (fidélité)
                child: Text(
                  "Chaque seconde compte. Face aux flammes, donnez l'alerte en un clic avec Alert'360.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', // Police de corps demandée
                    color: AppColors
                        .textSecondary, // Couleur thématique (gris foncé)
                    fontSize: 14,
                    height: 1.4, // Hauteur de ligne pour lisibilité
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

              const SizedBox(
                height: 32,
              ), // Augmentation de l'espace avant les points (fidélité)
              // 5. Indicateur de progression (Dots) : 1 sur 3
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24, // Point actif ovale
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue, // Point actif (bleu)
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildInactiveDot(), // Point inactif
                  const SizedBox(width: 6),
                  _buildInactiveDot(), // Point inactif
                ],
              ),

              const SizedBox(
                height: 32,
              ), // Augmentation de l'espace avant le bouton (fidélité)
              // 6. Bouton Suivant avec icône flèche
              SizedBox(
                width: double.infinity,
                height: 56, // Hauteur standard des gros boutons
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors
                        .primaryBlue, // Couleur thématique (bleu foncé bouton)
                    foregroundColor: Colors.white, // Texte en blanc
                    disabledBackgroundColor: AppColors.primaryBlue,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16.0,
                      ), // Rayon des coins du bouton
                    ),
                    elevation: 0, // Pas d'ombre portée
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Suivant',
                        style: TextStyle(
                          fontFamily: 'Inter', // Police du bouton
                          fontSize: 16,
                          fontWeight: FontWeight.w600, // Mi-gras
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 20), // Icône flèche
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24), // Marge du bas (fidélité)
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper pour les points inactifs de l'indicateur
  Widget _buildInactiveDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.inactiveDot, // Couleur thématique (gris clair)
        shape: BoxShape.circle,
      ),
    );
  }
}
