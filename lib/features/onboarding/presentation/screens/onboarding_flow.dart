import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';
import 'onboarding_second_screen.dart';
import 'onboarding_third_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentPage = 0;
  bool _isFinishing = false;

  void _goToNextPage() {
    if (_currentPage < 2) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() {
      _isFinishing = true;
    });

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool('onboarding_completed', true);

      if (!mounted) return;

      context.go('/login');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isFinishing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de terminer la présentation. Réessayez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 0:
        return OnboardingScreen(onNext: _goToNextPage);

      case 1:
        return OnboardingSecondScreen(onNext: _goToNextPage);

      case 2:
        return OnboardingThirdScreen(onFinish: _finishOnboarding);

      default:
        return const SizedBox.shrink();
    }
  }
}
