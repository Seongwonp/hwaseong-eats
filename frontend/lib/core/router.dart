import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/map_screen.dart';
import '../screens/review_screen.dart';
import '../screens/reward_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/review/:id',
      builder: (context, state) => ReviewScreen(
        restaurantId: int.parse(state.pathParameters['id']!),
        restaurantName: state.extra as String? ?? '',
      ),
    ),
    GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
  ],
);
