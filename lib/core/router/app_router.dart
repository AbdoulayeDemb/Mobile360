import 'package:alert360_mobile/features/actualites/presentation/screens/actualites_screen.dart';
import 'package:alert360_mobile/features/contenus_educatifs/presentation/screens/contenus_educatifs_screen.dart';
import 'package:alert360_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:alert360_mobile/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:alert360_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/register_flow.dart';
import 'package:alert360_mobile/features/accueil/presentation/screens/home_screen.dart';
import 'package:alert360_mobile/features/profil/presentation/screens/mon_profil_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/categories_selection_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/mes_signalements_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/problem_details_screen.dart';
import 'package:alert360_mobile/features/signalements/data/models/categorie.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String onboardingCompletedKey = 'onboarding_completed';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // Ne pas afficher directement l'onboarding au démarrage.
    initialLocation: '/startup',

    redirect: (BuildContext context, GoRouterState state) async {
      final preferences = await SharedPreferences.getInstance();

      final onboardingCompleted =
          preferences.getBool(onboardingCompletedKey) ?? false;

      final location = state.matchedLocation;

      final isStartup = location == '/startup';
      final isOnboarding = location == '/';
      final isLogin = location == '/login';
      final isRegister = location == '/register';

      // Première utilisation : afficher l'onboarding.
      if (!onboardingCompleted) {
        return isOnboarding ? null : '/';
      }

      // Une fois l'onboarding terminé, ne plus l'afficher.
      if (isOnboarding) {
        return '/startup';
      }

      // L'état de session est restauré par AuthController.
      final authState = ref.read(authControllerProvider);

      // Rester sur l'écran de démarrage pendant la restauration.
      if (authState.isLoading) {
        return isStartup ? null : '/startup';
      }

      final auth = authState.asData?.value;

      final role = auth?.role?.toUpperCase();

      final roleAutorise =
          role == 'CITOYEN' ||
          (role == 'STRUCTURE' && auth?.estResponsable == false);

      final sessionValide =
          auth != null && auth.estActif == true && roleAutorise;

      // Session valide : accès direct à l'accueil.
      if (sessionValide) {
        if (isStartup || isLogin || isRegister) {
          return '/home';
        }

        return null;
      }

      // Pas de session valide : afficher la connexion.
      if (isStartup) {
        return '/login';
      }

      // Les pages de connexion et d'inscription restent publiques.
      if (isLogin || isRegister) {
        return null;
      }

      // Toutes les autres pages nécessitent une session valide.
      return '/login';
    },

    routes: [
      // DÉMARRAGE / RESTAURATION DE SESSION
      GoRoute(
        path: '/startup',
        name: 'startup',
        builder: (context, state) => const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF3B5998)),
          ),
        ),
      ),

      // ONBOARDING : première utilisation uniquement
      GoRoute(
        path: '/',
        name: 'onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),

      // CONNEXION
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          onLoginSuccess: () {
            context.go('/home');
          },
          onNavigateToRegister: () {
            context.push('/register');
          },
        ),
      ),

      // INSCRIPTION CITOYEN
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterFlow(
          onCancel: () {
            context.go('/login');
          },
          onFinish: () {
            context.go('/home');
          },
        ),
      ),

      // ACCUEIL ALERT360
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => HomeScreen(
          onSignalProblem: () {
            context.push('/categories');
          },
        ),
      ),

      // SÉLECTION DES CATÉGORIES
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => CategoriesSelectionScreen(
          onBack: () {
            context.pop();
          },
          onCategorySelected: (Categorie categorie) {
            context.push('/problem-details', extra: categorie);
          },
        ),
      ),

      // DÉTAILS DU PROBLÈME
      GoRoute(
        path: '/problem-details',
        name: 'problem-details',
        builder: (context, state) {
          final categorie = state.extra as Categorie;

          return ProblemDetailsScreen(
            categoryId: categorie.idCategorie,
            categoryTitle: categorie.nom,
            onBack: () {
              context.pop();
            },
            onSubmitSignalement: () {
              context.go('/home');
            },
          );
        },
      ),

      // MES SIGNALEMENTS
      GoRoute(
        path: '/mes-signalements',
        name: 'mes-signalements',
        builder: (context, state) => MesSignalementsScreen(
          onBack: () {
            context.go('/home');
          },
        ),
      ),

      // MON PROFIL
      GoRoute(
        path: '/profil',
        name: 'profil',
        builder: (context, state) => const MonProfilScreen(),
      ),

      // ACTUALITÉS ALERT360
      GoRoute(
        path: '/actualites',
        name: 'actualites',
        builder: (context, state) => ActualitesScreen(
          onBack: () {
            context.go('/home');
          },
        ),
      ),

      // CONTENUS ÉDUCATIFS
      GoRoute(
        path: '/contenus-educatifs',
        name: 'contenus-educatifs',
        builder: (context, state) => const GuideEducationScreen(),
      ),

      // NOTIFICATIONS
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => NotificationsScreen(
          onBack: () {
            context.go('/home');
          },
        ),
      ),
    ],
  );

  // Actualiser le routeur lorsque l'état d'authentification change.
  ref.listen(authControllerProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});
