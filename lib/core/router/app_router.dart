import 'package:alert360_mobile/features/contenus_educatifs/presentation/screens/contenus_educatifs_test_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const ContenusEducatifsTestPage();
      },
    ),
  ],
);
