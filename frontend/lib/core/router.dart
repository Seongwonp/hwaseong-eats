import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/main_shell.dart';
import '../screens/search_screen.dart';
import '../screens/review_screen.dart';
import '../screens/reward_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/resident_verify_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainShell()),
    GoRoute(path: '/map', builder: (_, __) => const MainShell(initialIndex: 0)),
    GoRoute(path: '/calendar', builder: (_, __) => const MainShell(initialIndex: 1)),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(
      path: '/review/:id',
      builder: (_, state) => ReviewScreen(
        restaurantId: int.parse(state.pathParameters['id']!),
        restaurantName: state.extra as String? ?? '',
      ),
    ),
    GoRoute(path: '/reward', builder: (_, __) => const RewardScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/verify', builder: (_, __) => const ResidentVerifyScreen()),
  ],
);
