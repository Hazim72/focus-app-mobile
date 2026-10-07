import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/active_session/screens/active_session_screen.dart';
import '../../features/app_selection/screens/app_selection_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/session_setup/screens/session_confirm_screen.dart';
import '../../features/session_setup/screens/session_setup_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const ActiveSessionScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: '/app-selection',
      name: 'app-selection',
      builder: (BuildContext context, GoRouterState state) =>
          const AppSelectionScreen(),
    ),
    GoRoute(
      path: '/session-setup',
      name: 'session-setup',
      builder: (BuildContext context, GoRouterState state) =>
          const SessionSetupScreen(),
    ),
    GoRoute(
      path: '/session-confirm',
      name: 'session-confirm',
      builder: (BuildContext context, GoRouterState state) {
        final duration = state.extra as int? ?? 25;
        return SessionConfirmScreen(durationMinutes: duration);
      },
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (BuildContext context, GoRouterState state) =>
          const StatsScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
  ],
);
