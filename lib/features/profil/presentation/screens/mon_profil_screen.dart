 import 'package:alert360_mobile/features/auth/data/services/citoyen_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Récupérer l'identifiant du compte connecté.
  int? _obtenirIdUtilisateur() {
    return ref.read(authControllerProvider).asData?.value?.idUtilisateur;
  }

  // Charger les informations depuis le backend.
  Future<void> _chargerProfil() async {
    final userId = _obtenirIdUtilisateur();

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _chargement = false;
        _erreur = 'Impossible de retrouver votre compte connecté.';
      });
      return;
    }

    try {
      final citoyen = await ref
          .read(citoyenServiceProvider)
          .getCitoyenById(userId);

      if (!mounted) return;

      setState(() {
        _citoyen = citoyen;
        _remplirFormulaire(citoyen);
        _erreur = null;
      });
    } catch (e) {
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

  // Enregistrer les modifications du profil.
  Future<void> _enregistrerProfil() async {
    if (_enregistrement) return;

    if (!_formKey.currentState!.validate()) return;

    final userId = _obtenirIdUtilisateur();

    if (userId == null) {
      _afficherMessage('Identifiant utilisateur introuvable.', erreur: true);
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

      _afficherMessage('Votre profil a été modifié avec succès.');
    } catch (e) {
      if (!mounted) return;

      _afficherMessage(
        'Échec de la modification du profil. Vérifiez les informations '
        'saisies et réessayez.',
        erreur: true,
      );
    } finally {
      if (mounted) {
        setState(() => _enregistrement = false);
      }
    }
  }

  void _afficherMessage(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: erreur ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // Annuler la modification et restaurer les valeurs initiales.
  void _annulerModification() {
    if (_enregistrement) return;

    setState(() {
      if (_citoyen != null) {
        _remplirFormulaire(_citoyen!);
      }
      _modification = false;
    });
  }

  // Confirmer la déconnexion.
  Future<void> _confirmerDeconnexion() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Me déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmation != true || !mounted) return;

    try {
      await ref.read(authControllerProvider.notifier).logout();

      if (!mounted) return;

      // Le routeur doit rediriger vers la connexion lorsque la session
      // devient null. Sinon, ajoute ici la navigation vers ta route login.
    } catch (e) {
      if (!mounted) return;

      _afficherMessage('La déconnexion a rencontré un problème.', erreur: true);
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

            _elementAction(
              icone: Icons.lock_outline,
              titre: 'Sécurité du compte',
              sousTitre: 'Gérer votre mot de passe',
              onTap: () {
                _afficherMessage(
                  'La modification du mot de passe nécessite '
                  'un endpoint sécurisé côté backend.',
                );
              },
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _confirmerDeconnexion,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3FB),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icone, color: AppColors.primaryBlue),
        ),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sousTitre),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _formulaireModification() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titreSection('Modifier mes informations'),
            const SizedBox(height: 18),

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

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _enregistrement ? null : _annulerModification,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _enregistrement ? null : _enregistrerProfil,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: _enregistrement
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: telephone
            ? TextInputType.phone
            : email
            ? TextInputType.emailAddress
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 1.5,
            ),
          ),
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
