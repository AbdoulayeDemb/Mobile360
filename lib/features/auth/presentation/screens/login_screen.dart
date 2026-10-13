import 'package:alert360_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onNavigateToRegister,
    this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Éviter plusieurs requêtes simultanées.
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final telephone = _phoneController.text.trim();
    final motDePasse = _passwordController.text;

    if (telephone.isEmpty || motDePasse.isEmpty) {
      _showMessage(
        'Veuillez renseigner votre numéro de téléphone et votre mot de passe.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(telephone: telephone, motDePasse: motDePasse);

      if (!mounted) return;

      final authState = ref.read(authControllerProvider);

      if (authState.hasError) {
        _showMessage(_formatError(authState.error));
        return;
      }

      final auth = authState.value;

      if (auth == null) {
        _showMessage(
          'Connexion impossible. Vérifiez vos identifiants '
          'ou assurez-vous que votre profil est autorisé.',
        );
        return;
      }

      // Vérification supplémentaire côté interface.
      // Le backend doit également contrôler les profils autorisés.
      final role = auth.role?.toUpperCase();

      final estAutorise =
          auth.estActif == true &&
          (role == 'CITOYEN' ||
              (role == 'STRUCTURE' && auth.estResponsable == false));

      if (!estAutorise) {
        await ref.read(authControllerProvider.notifier).logout();

        if (!mounted) return;

        _showMessage(
          "Accès refusé : ce profil n'est pas autorisé "
          "à utiliser l'application mobile Alert'360.",
        );
        return;
      }

      // Notifier le routeur ou le widget parent.
      widget.onLoginSuccess?.call();
    } catch (e) {
      if (!mounted) return;

      _showMessage(_formatError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatError(Object? error) {
    if (error == null) {
      return 'Connexion impossible. Veuillez réessayer.';
    }

    var message = error.toString();

    message = message.replaceFirst('Exception: ', '').trim();

    if (message.isEmpty || message == 'null') {
      return 'Connexion impossible. Vérifiez vos identifiants.';
    }

    return message;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo Alert360
              Center(
                child: Image.asset(
                  'assets/images/logo/logo_alert360.png',
                  height: 75,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 24),

              // Titre principal
              const Text(
                'Connectez-vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.darkBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Sous-titre
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Veuillez vous connecter pour pouvoir accéder à votre compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Champ numéro de téléphone
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Text('🇲🇱', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    const Text(
                      '+223',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 24,
                      width: 1,
                      color: const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: AppColors.darkBlue,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Votre numéro de téléphone',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Champ mot de passe
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.darkBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_isLoading) {
                            _login();
                          }
                        },
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          color: AppColors.darkBlue,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Entrez votre mot de passe',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _obscurePassword
                          ? 'Afficher le mot de passe'
                          : 'Masquer le mot de passe',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton de connexion
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.65,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Lien vers l'inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pas de compte ? ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : widget.onNavigateToRegister,
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
