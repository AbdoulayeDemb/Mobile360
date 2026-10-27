import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
    final estActif = profil?.estActif ?? auth?.estActif ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _carteIdentite(prenom, nom, estActif),
                  const SizedBox(height: 24),
                  _titreSection('Informations personnelles'),
                  const SizedBox(height: 12),
                  _carteInformations(profil),
                  const SizedBox(height: 24),
                  _titreSection('Compte et sécurité'),
                  const SizedBox(height: 12),
                  _elementAction(
                    icone: Icons.person_outline,
                    titre: 'Modifier mon profil',
                    sousTitre:
                        'Les informations de votre compte sont gérées par '
                        'votre structure.',
                    onTap: _compteGereParResponsable,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _deconnexionEnCours
                        ? null
                        : _confirmerDeconnexion,
                    icon: _deconnexionEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout, color: Colors.red),
                    label: Text(
                      _deconnexionEnCours
                          ? 'Déconnexion en cours...'
                          : 'Se déconnecter',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AgentBottomNav(currentIndex: 2),
    );
  }

  Widget _carteIdentite(String? prenom, String? nom, bool estActif) {
    final nomComplet = [
      prenom,
      nom,
    ].whereType<String>().where((valeur) => valeur.trim().isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              MissionUi.initiales(prenom, nom),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomComplet.isEmpty ? 'Mon compte' : nomComplet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AGENT DE TERRAIN',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estActif ? 'Compte actif' : 'Compte inactif',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titreSection(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _carteInformations(Utilisateur? profil) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          _ligneInformation(Icons.person_outline, 'Nom', profil?.nom),
          _ligneInformation(Icons.badge_outlined, 'Prénom', profil?.prenom),
          _ligneInformation(
            Icons.phone_outlined,
            'Téléphone',
            profil?.telephone,
          ),
          _ligneInformation(Icons.email_outlined, 'Email', profil?.email),
          _ligneInformation(
            Icons.qr_code_2_rounded,
            'Matricule',
            profil?.matriculeAgent,
          ),
          _ligneInformation(
            Icons.apartment_rounded,
            'Structure',
            profil?.nomStructure,
            derniere: true,
          ),
        ],
      ),
    );
  }

  Widget _ligneInformation(
    IconData icone,
    String titre,
    String? valeur, {
    bool derniere = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: derniere
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F2F6))),
      ),
      child: Row(
        children: [
          Icon(icone, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valeur == null || valeur.trim().isEmpty
                      ? 'Non renseigné'
                      : valeur,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _elementAction({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: _deconnexionEnCours ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icone, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sousTitre,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
