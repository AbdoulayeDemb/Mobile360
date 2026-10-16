import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/citoyen_request.dart';
import '../providers/auth_provider.dart';

class RegisterFlow extends ConsumerStatefulWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onFinish;

  const RegisterFlow({super.key, this.onCancel, this.onFinish});

  @override
  ConsumerState<RegisterFlow> createState() => _RegisterFlowState();
}

class _RegisterFlowState extends ConsumerState<RegisterFlow> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _quartierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // PopUp / Modal centré pour les messages
  void _showSuccessPopUp({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès dans un cercle bleu clair
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryBlue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Titre du PopUp
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 12),

                // Message centré
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Ferme le dialogue
                      onConfirm(); // Redirige vers la connexion
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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

  // PopUp d'erreur centré
  void _showErrorPopUp(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade600,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erreur',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
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

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'Le numéro de téléphone est obligatoire.';
    }
    if (!RegExp(r'^[0-9]{8,15}$').hasMatch(phone)) {
      return 'Veuillez entrer un numéro de téléphone valide.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Veuillez entrer une adresse email valide.';
    }
    return null;
  }

  void _goToNextStep() {
    if (_isLoading) return;

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _submitRegistration() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CitoyenRequest(
        nom: _nameController.text.trim(),
        prenom: _surnameController.text.trim(),
        telephone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        quartier: _quartierController.text.trim(),
        motDePasse: _passwordController.text,
      );

      final repository = ref.read(authRepositoryProvider);
      final response = await repository.register(request: request);

      if (!mounted) return;

      // Succès standard via la réponse
      _showSuccessPopUp(
        title: 'Compte créé avec succès !',
        message: 'Votre compte a été créé avec succès, veuillez vous connecter pour pouvoir accéder à votre compte.',
        onConfirm: () {
          widget.onFinish?.call();
        },
      );
    } catch (error) {
      if (!mounted) return;

      var message = error.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      // VÉRIFICATION : Si le message du backend indique que la création est réussie
      final lowerMsg = message.toLowerCase();
      if (lowerMsg.contains('succès') ||
          lowerMsg.contains('créé avec succès') ||
          lowerMsg.contains('citoyen créé')) {
        _showSuccessPopUp(
          title: 'Compte créé avec succès !',
          message: 'Votre compte a été créé avec succès, veuillez vous connecter pour pouvoir accéder à votre compte.',
          onConfirm: () {
            widget.onFinish?.call();
          },
        );
      } else {
        // Vraie erreur backend
        _showErrorPopUp(
          message.isEmpty
              ? 'Une erreur est survenue pendant l’inscription.'
              : message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                Center(
                  child: Image.asset(
                    'assets/images/logo/logo_alert360.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Inscrivez-vous',
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Veuillez vous inscrire pour pouvoir accéder à votre compte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                _buildStepIndicator(),

                const SizedBox(height: 24),

                if (_currentStep == 1) ...[
                  _buildFieldLabel('Nom *'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _nameController,
                    hintText: 'Entrez votre nom',
                    icon: Icons.person_outline,
                    validator: (value) => _requiredValidator(value, 'Le nom'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  _buildFieldLabel('Prénom *'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _surnameController,
                    hintText: 'Entrez votre prénom',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        _requiredValidator(value, 'Le prénom'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  _buildFieldLabel('Téléphone *'),
                  const SizedBox(height: 8),
                  _buildPhoneInputField(),
                ] else ...[
                  _buildFieldLabel('Email (facultatif)'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _emailController,
                    hintText: 'Entrez votre email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),

                  const SizedBox(height: 16),

                  _buildFieldLabel('Quartier *'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _quartierController,
                    hintText: 'Entrez votre quartier',
                    icon: Icons.location_on_outlined,
                    validator: (value) =>
                        _requiredValidator(value, 'Le quartier'),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  _buildFieldLabel('Mot de passe *'),
                  const SizedBox(height: 8),
                  _buildPasswordInputField(),
                ],

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : _currentStep == 1
                              ? widget.onCancel
                              : () {
                                  setState(() => _currentStep = 1);
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentStep == 1 ? 'Annuler' : 'Retour',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.primaryBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _currentStep == 1
                              ? _goToNextStep
                              : _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primaryBlue
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _currentStep == 1 ? 'Suivant' : 'Terminer',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Informations'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep == 2
                ? AppColors.primaryBlue
                : const Color(0xFFE2E8F0),
          ),
        ),
        _buildStepCircle(2, 'Compte'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final active = _currentStep >= step;

    return Column(
      children: [
        Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlue : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: active ? AppColors.darkBlue : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return FormField<String>(
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(icon, color: AppColors.darkBlue, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      textCapitalization: textCapitalization,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.darkBlue,
                      ),
                      onChanged: (val) => state.didChange(val),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(
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
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFE53E3E),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneInputField() {
    return FormField<String>(
      validator: _phoneValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.darkBlue,
                      ),
                      onChanged: (val) => state.didChange(val),
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
                  const SizedBox(width: 12),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFE53E3E),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordInputField() {
    return FormField<String>(
      validator: (val) => _requiredValidator(val, 'Le mot de passe'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (FormFieldState<String> state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.darkBlue,
                      ),
                      onChanged: (val) => state.didChange(val),
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
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFE53E3E),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
