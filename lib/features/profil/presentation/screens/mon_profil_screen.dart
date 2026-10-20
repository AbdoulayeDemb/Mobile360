import 'package:alert360_mobile/features/auth/data/services/citoyen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final citoyenServiceProvider = Provider<CitoyenService>((ref) {
  return CitoyenService();
});

class MonProfilScreen extends ConsumerStatefulWidget {
  const MonProfilScreen({super.key});

  @override
  ConsumerState<MonProfilScreen> createState() => _MonProfilScreenState();
}

class _MonProfilScreenState extends ConsumerState<MonProfilScreen> {
  Map<String, dynamic>? _citoyen;

  bool _chargement = true;
  bool _modification = false;
  bool _enregistrement = false;
  bool _deconnexionEnCours = false;

  String? _erreur;

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _quartierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_chargerProfil);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  int? _obtenirIdUtilisateur() {
    return ref.read(authControllerProvider).asData?.value?.idUtilisateur;
  }

  Future<void> _afficherPopup({
    required String titre,
    required String message,
    required IconData icone,
    Color couleur = AppColors.primaryBlue,
    String texteBouton = 'Compris',
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icone, size: 38, color: couleur),
                ),
                const SizedBox(height: 20),
                Text(
                  titre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: couleur,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      texteBouton,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _afficherMessage(String message, {bool erreur = false}) {
    _afficherPopup(
      titre: erreur ? 'Une erreur est survenue' : 'Information',
      message: message,
      icone: erreur ? Icons.error_outline_rounded : Icons.info_outline_rounded,
      couleur: erreur ? const Color(0xFFDC2626) : AppColors.primaryBlue,
    );
  }

  Future<void> _chargerProfil() async {
    final authState = ref.read(authControllerProvider);

    // Attendre que le contrôleur ait terminé la restauration de session.
    if (authState.isLoading) {
      try {
        await ref.read(authControllerProvider.future);
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _chargement = false;
          _erreur = 'Impossible de vérifier votre session.';
        });
        return;
      }
    }

    final auth = ref.read(authControllerProvider).asData?.value;

    if (auth == null) {
      if (!mounted) return;

      setState(() {
        _chargement = false;
        _erreur = 'Votre session a expiré. Veuillez vous reconnecter.';
      });

      if (mounted) context.go('/login');
      return;
    }

    if (auth.role?.toUpperCase() != 'CITOYEN') {
      if (!mounted) return;

      setState(() {
        _chargement = false;
        _erreur = 'Cet écran est réservé aux comptes citoyens.';
      });
      return;
    }

    final userId = auth.idUtilisateur;

    try {
      final citoyen = await ref
          .read(citoyenServiceProvider)
          .getCitoyenById(userId!);

      if (!mounted) return;

      setState(() {
        _citoyen = citoyen;
        _remplirFormulaire(citoyen);
        _erreur = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erreur = 'Impossible de charger votre profil.';
      });
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  void _remplirFormulaire(Map<String, dynamic> citoyen) {
    _nomController.text = citoyen['nom']?.toString() ?? '';
    _prenomController.text = citoyen['prenom']?.toString() ?? '';
    _telephoneController.text = citoyen['telephone']?.toString() ?? '';
    _emailController.text = citoyen['email']?.toString() ?? '';
    _quartierController.text = citoyen['quartier']?.toString() ?? '';
  }

  Future<void> _enregistrerProfil() async {
    if (_enregistrement || _deconnexionEnCours) return;

    if (!_formKey.currentState!.validate()) return;

    final userId = _obtenirIdUtilisateur();

    if (userId == null) {
      await _afficherPopup(
        titre: 'Session introuvable',
        message: 'Veuillez vous reconnecter pour modifier votre profil.',
        icone: Icons.error_outline_rounded,
        couleur: const Color(0xFFDC2626),
      );

      if (mounted) context.go('/login');
      return;
    }

    setState(() => _enregistrement = true);

    try {
      final resultat = await ref
          .read(citoyenServiceProvider)
          .modifierProfilCitoyen(
            idUtilisateur: userId,
            donnees: {
              'nom': _nomController.text.trim(),
              'prenom': _prenomController.text.trim(),
              'telephone': _telephoneController.text.trim(),
              'email': _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              'quartier': _quartierController.text.trim(),
            },
          );

      if (!mounted) return;

      setState(() {
        _citoyen = resultat;
        _remplirFormulaire(resultat);
        _modification = false;
      });

      await _afficherPopup(
        titre: 'Profil mis à jour !',
        message:
            'Vos informations personnelles ont été modifiées avec succès. '
            'Votre profil Alert360 est maintenant à jour.',
        icone: Icons.check_circle_outline_rounded,
        couleur: AppColors.primaryBlue,
        texteBouton: 'Continuer',
      );
    } catch (_) {
      if (!mounted) return;

      await _afficherPopup(
        titre: 'Modification impossible',
        message:
            'Nous n’avons pas pu mettre à jour votre profil. '
            'Vérifiez votre connexion et les informations saisies, '
            'puis réessayez.',
        icone: Icons.error_outline_rounded,
        couleur: const Color(0xFFDC2626),
        texteBouton: 'Réessayer',
      );
    } finally {
      if (mounted) {
        setState(() => _enregistrement = false);
      }
    }
  }

  void _annulerModification() {
    if (_enregistrement) return;

    setState(() {
      if (_citoyen != null) {
        _remplirFormulaire(_citoyen!);
      }
      _modification = false;
    });
  }

  Future<void> _confirmerDeconnexion() async {
    if (_deconnexionEnCours || _enregistrement) return;

    final confirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          title: const Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFFFE8E8),
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Se déconnecter ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte Alert360 ? '
            'Vous devrez vous reconnecter pour accéder à votre espace personnel.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
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
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) return;

    setState(() => _deconnexionEnCours = true);

    try {
      await ref.read(authControllerProvider.notifier).logout();

      if (!mounted) return;

      context.go('/login');
    } catch (_) {
      if (!mounted) return;

      await _afficherPopup(
        titre: 'Déconnexion impossible',
        message:
            'Une erreur est survenue lors de la fermeture de votre session. '
            'Veuillez réessayer.',
        icone: Icons.error_outline_rounded,
        couleur: const Color(0xFFDC2626),
        texteBouton: 'Réessayer',
      );
    } finally {
      if (mounted) {
        setState(() => _deconnexionEnCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (_chargement || authState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_erreur != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Mon profil'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(_erreur!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _chargement = true;
                      _erreur = null;
                    });
                    _chargerProfil();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final citoyen = _citoyen ?? <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Mon profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _carteIdentite(citoyen),
            const SizedBox(height: 24),
            if (_modification)
              _formulaireModification()
            else ...[
              _titreSection('Informations personnelles'),
              const SizedBox(height: 12),
              _carteInformations(citoyen),
            ],
            const SizedBox(height: 24),
            _titreSection('Compte et sécurité'),
            const SizedBox(height: 12),
            _elementAction(
              icone: Icons.person_outline,
              titre: 'Modifier mon profil',
              sousTitre: 'Nom, prénom, téléphone, email et quartier',
              onTap: () {
                setState(() {
                  _remplirFormulaire(citoyen);
                  _modification = true;
                });
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _enregistrement || _deconnexionEnCours
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
                side: BorderSide(color: Colors.red.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteIdentite(Map<String, dynamic> citoyen) {
    final nomComplet = [
      citoyen['prenom']?.toString() ?? '',
      citoyen['nom']?.toString() ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ');

    final estActif = citoyen['estActif'] == true;

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
            child: const Icon(Icons.person, color: Colors.white, size: 34),
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
                  citoyen['role']?.toString() ?? 'CITOYEN',
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

  Widget _carteInformations(Map<String, dynamic> citoyen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          _ligneInformation(
            Icons.person_outline,
            'Nom',
            citoyen['nom']?.toString(),
          ),
          _ligneInformation(
            Icons.badge_outlined,
            'Prénom',
            citoyen['prenom']?.toString(),
          ),
          _ligneInformation(
            Icons.phone_outlined,
            'Téléphone',
            citoyen['telephone']?.toString(),
          ),
          _ligneInformation(
            Icons.email_outlined,
            'Email',
            citoyen['email']?.toString(),
          ),
          _ligneInformation(
            Icons.location_on_outlined,
            'Quartier',
            citoyen['quartier']?.toString(),
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
    final valeurAffichee = valeur == null || valeur.trim().isEmpty
        ? 'Non renseigné'
        : valeur;

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
                  valeurAffichee,
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
        onTap: _enregistrement || _deconnexionEnCours ? null : onTap,
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

  Widget _formulaireModification() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titreSection('Modifier mes informations'),
            const SizedBox(height: 6),
            const Text(
              'Mettez à jour les informations de votre compte.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 22),
            _champ('Nom', _nomController, obligatoire: true),
            _champ('Prénom', _prenomController, obligatoire: true),
            _champ(
              'Téléphone',
              _telephoneController,
              obligatoire: true,
              telephone: true,
            ),
            _champ('Email', _emailController, email: true),
            _champ('Quartier', _quartierController, obligatoire: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enregistrement ? null : _annulerModification,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _enregistrement ? null : _enregistrerProfil,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _enregistrement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _champ(
    String label,
    TextEditingController controller, {
    bool obligatoire = false,
    bool email = false,
    bool telephone = false,
  }) {
    const borderColor = Color(0xFFD6DFEA);
    const textColor = Color(0xFF1E293B);
    const labelColor = Color(0xFF64748B);

    OutlineInputBorder buildBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_enregistrement,
        style: const TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.primaryBlue,
        keyboardType: telephone
            ? TextInputType.phone
            : email
            ? TextInputType.emailAddress
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: labelColor),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: _enregistrement ? const Color(0xFFF1F5F9) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 17,
          ),
          border: buildBorder(borderColor),
          enabledBorder: buildBorder(borderColor),
          focusedBorder: buildBorder(AppColors.primaryBlue, width: 1.7),
          disabledBorder: buildBorder(const Color(0xFFE2E8F0)),
          errorBorder: buildBorder(Colors.red.shade600),
          focusedErrorBorder: buildBorder(Colors.red.shade600, width: 1.5),
        ),
        validator: (value) {
          final texte = value?.trim() ?? '';

          if (obligatoire && texte.isEmpty) {
            return '$label est obligatoire.';
          }

          if (telephone &&
              texte.isNotEmpty &&
              !RegExp(r'^[0-9]{8,15}$').hasMatch(texte)) {
            return 'Saisissez entre 8 et 15 chiffres.';
          }

          if (email &&
              texte.isNotEmpty &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texte)) {
            return 'Adresse email invalide.';
          }

          return null;
        },
      ),
    );
  }
}
