import 'package:go_router/go_router.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../checkin/checkin_screen.dart';
import '../insight/insight_screen.dart';
import '../goal/goal_screen.dart';
import '../profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen()),
    GoRoute(path: '/insights', builder: (_, __) => const InsightScreen()),
    GoRoute(path: '/goals', builder: (_, __) => const GoalScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
);
