import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../checkin/checkin_screen.dart';
import '../insight/insight_screen.dart';
import '../goal/goal_screen.dart';
import '../notification/notification_screen.dart';
import '../profile/profile_screen.dart';
import 'shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final onboarded = prefs.getBool('onboarding_done') ?? false;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isOnboarding = state.matchedLocation == '/onboarding';

    if (token == null && !isAuthRoute) return '/login';
    if (token != null && !onboarded && !isOnboarding && !isAuthRoute) return '/onboarding';
    if (token != null && isAuthRoute) return '/app/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/app/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/app/checkin', builder: (_, __) => const CheckinScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/app/insights', builder: (_, __) => const InsightScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/app/goals', builder: (_, __) => const GoalScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/app/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
