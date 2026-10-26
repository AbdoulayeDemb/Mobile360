import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../about/presentation/screens/about_screen.dart';
import '../../../auth/data/models/utilisateur.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_bottom_nav.dart';
import '../widgets/agent_page_header.dart';
import '../widgets/mission_ui.dart';

class AgentProfilScreen extends ConsumerStatefulWidget {
  const AgentProfilScreen({super.key});

  @override
  ConsumerState<AgentProfilScreen> createState() => _AgentProfilScreenState();
}

class _AgentProfilScreenState extends ConsumerState<AgentProfilScreen> {
  bool _deconnexionEnCours = false;

  Future<void> _afficherInformation({
    required String titre,
    required String message,
    required IconData icone,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Icon(icone, size: 40, color: AppColors.primaryBlue),
        title: Text(
          titre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Compris'),
            ),
          ),
        ],
      ),
    );
  }

  /// Le compte d'un agent est géré par son responsable de structure.
  Future<void> _compteGereParResponsable() {
    return _afficherInformation(
      titre: 'Compte géré par votre structure',
      message:
          'Les informations de votre compte agent sont gérées par le '
          'responsable de votre structure. Contactez-le pour toute '
          'modification ou suppression.',
      icone: Icons.admin_panel_settings_outlined,
    );
  }

  void _afficherInformationsPersonnelles(Utilisateur? profil) {
    final lignes = <(IconData, String, String?)>[
      (Icons.person_outline, 'Nom', profil?.nom),
      (Icons.badge_outlined, 'Prénom', profil?.prenom),
      (Icons.phone_outlined, 'Téléphone', profil?.telephone),
      (Icons.email_outlined, 'Email', profil?.email),
      (Icons.qr_code_2_rounded, 'Matricule', profil?.matriculeAgent),
      (Icons.apartment_rounded, 'Structure', profil?.nomStructure),
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final (icone, titre, valeur) in lignes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icone, color: AppColors.primaryBlue),
                  title: Text(
                    titre,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    valeur == null || valeur.trim().isEmpty
                        ? 'Non renseigné'
                        : valeur,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmerDeconnexion() async {
    if (_deconnexionEnCours) return;

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFFFE8E8),
          child: Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 32),
        ),
        title: const Text(
          'Se déconnecter ?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte agent ?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.6),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Me déconnecter'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmation != true || !mounted) return;

    setState(() => _deconnexionEnCours = true);

    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) context.go('/login');
    } finally {
      if (mounted) setState(() => _deconnexionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).asData?.value;
    final profil = ref.watch(profilAgentProvider).asData?.value;

    final prenom = profil?.prenom ?? auth?.prenom;
    final nom = profil?.nom ?? auth?.nom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AgentPageHeader(
              titre: 'Mon profil',
              sousTitre: 'Consultez vos informations personnelles',
              onBack: () => context.go('/agent/home'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                children: [
                  // Avatar avec initiales.
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            MissionUi.initiales(prenom, nom),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: 16,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.darkBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    [prenom, nom].whereType<String>().join(' ').trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  if (profil?.nomStructure != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Agent de terrain - ${profil!.nomStructure}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: MissionUi.texteGris,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Center(
                    child: FilledButton(
                      onPressed: _compteGereParResponsable,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE8EBF2),
                        foregroundColor: const Color(0xFF1D4E89),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Modifier le profil',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _titreSection('COMPTE'),
                  _groupe([
                    _ligne(
                      icone: Icons.person_outline_rounded,
                      titre: 'Informations personnelles',
                      onTap: () => _afficherInformationsPersonnelles(profil),
                    ),
                    _ligne(
                      icone: Icons.info_outline_rounded,
                      titre: 'À propos de nous',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  _titreSection('CONNEXION'),
                  _groupe([
                    _ligne(
                      icone: Icons.delete_outline_rounded,
                      titre: 'Supprimer mon compte',
                      onTap: _compteGereParResponsable,
                    ),
                    _ligne(
                      icone: Icons.logout_rounded,
                      titre: _deconnexionEnCours
                          ? 'Déconnexion en cours...'
                          : 'Déconnexion',
                      couleur: const Color(0xFFB91C1C),
                      onTap: _confirmerDeconnexion,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 2),
    );
  }

  Widget _titreSection(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titre,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _groupe(List<Widget> lignes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(children: lignes),
    );
  }

  Widget _ligne({
    required IconData icone,
    required String titre,
    required VoidCallback onTap,
    Color couleur = AppColors.textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icone,
              size: 26,
              color: couleur == AppColors.textSecondary
                  ? AppColors.darkBlue
                  : couleur,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: couleur,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
