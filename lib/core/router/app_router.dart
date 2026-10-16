import 'package:alert360_mobile/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:alert360_mobile/features/auth/presentation/screens/register_flow.dart';
import 'package:alert360_mobile/features/accueil/presentation/screens/home_screen.dart';
import 'package:alert360_mobile/features/profil/presentation/screens/mon_profil_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/categories_selection_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/mes_signalements_screen.dart';
import 'package:alert360_mobile/features/signalements/presentation/screens/problem_details_screen.dart';
import 'package:alert360_mobile/features/signalements/data/models/categorie.dart';

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

    // L'utilisateur doit terminer l'onboarding avant les autres écrans.
    if (!onboardingCompleted && !isOnboarding) {
      return '/';
    }

    // Une fois l'onboarding terminé, afficher la connexion.
    if (onboardingCompleted && isOnboarding) {
      return '/login';
    }

    // Connexion et inscription restent accessibles.
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
            // L'inscription ne connecte pas automatiquement le citoyen.
            context.go('/login');
          },
        );
      },
    ),

    // ACCUEIL ALERT360
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return HomeScreen(
          // Seule cette action lance le parcours de signalement.
          onSignalProblem: () {
            context.push('/categories');
          },

          // Ne pas définir onAllCategories ici :
          // la section « Toutes les catégories » reste non cliquable.
        );
      },
    ),

    // SÉLECTION DES CATÉGORIES
    GoRoute(
      path: '/categories',
      name: 'categories',
      builder: (BuildContext context, GoRouterState state) {
        return CategoriesSelectionScreen(
          onBack: () {
            context.pop();
          },

          // La catégorie sélectionnée est transmise à l'écran suivant.
          onCategorySelected: (Categorie categorie) {
            context.push('/problem-details', extra: categorie);
          },
        );
      },
    ),

    // DÉTAILS DU PROBLÈME
    GoRoute(
      path: '/problem-details',
      name: 'problem-details',
      builder: (BuildContext context, GoRouterState state) {
        final categorie = state.extra as Categorie;

        return ProblemDetailsScreen(
          categoryId: categorie.idCategorie,
          categoryTitle: categorie.nom,

          onBack: () {
            context.pop();
          },

          onSubmitSignalement: () {
            // Après l'envoi, revenir à l'accueil.
            context.go('/home');
          },
        );
      },
    ),

    // MES SIGNALEMENTS
    GoRoute(
      path: '/mes-signalements',
      name: 'mes-signalements',
      builder: (BuildContext context, GoRouterState state) {
        return MesSignalementsScreen(
          onBack: () {
            context.go('/home');
          },
        );
      },
    ),

    // MON PROFIL
    GoRoute(
      path: '/profil',
      name: 'profil',
      builder: (BuildContext context, GoRouterState state) {
        return const MonProfilScreen();
      },
    ),
  ],
);
