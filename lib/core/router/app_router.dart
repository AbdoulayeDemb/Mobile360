import 'package:alert360_mobile/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/register_flow.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String onboardingCompletedKey = 'onboarding_completed';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  redirect: (BuildContext context, GoRouterState state) async {
    final preferences = await SharedPreferences.getInstance();

    final onboardingCompleted =
        preferences.getBool(onboardingCompletedKey) ?? false;

    final currentLocation = state.matchedLocation;

    final isOnboarding = currentLocation == '/';
    final isLogin = currentLocation == '/login';
    final isRegister = currentLocation == '/register';

    // L'utilisateur doit terminer l'onboarding avant d'accéder
    // aux autres écrans.
    if (!onboardingCompleted && !isOnboarding) {
      return '/';
    }

    // Une fois l'onboarding terminé, afficher la connexion.
    if (onboardingCompleted && isOnboarding) {
      return '/login';
    }

    // Autoriser l'accès à la connexion et à l'inscription.
    if (isLogin || isRegister) {
      return null;
    }

    return null;
  },

  routes: [
    // ONBOARDING
    GoRoute(
      path: '/',
      name: 'onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingFlow();
      },
    ),

    // CONNEXION
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return LoginScreen(
          onLoginSuccess: () {
            context.go('/home');
          },
          onNavigateToRegister: () {
            context.push('/register');
          },
        );
      },
    ),

    // INSCRIPTION CITOYEN
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) {
        return RegisterFlow(
          onCancel: () {
            context.go('/login');
          },
          onFinish: () {
            context.go('/login');
          },
        );
      },
    ),

    // ACCUEIL TEMPORAIRE
    // À remplacer par le véritable écran d'accueil.
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const _PlaceholderScreen(
          title: 'Accueil Alert360',
          message: 'Connecté avec succès.',
        );
      },
    ),
  ],
);

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
