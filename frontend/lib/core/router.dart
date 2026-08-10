import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/map_screen.dart';
import '../screens/search_screen.dart';
import '../screens/review_screen.dart';
import '../screens/reward_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/resident_verify_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/festival_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/review/:id',
      builder: (context, state) => ReviewScreen(
        restaurantId: int.parse(state.pathParameters['id']!),
        restaurantName: state.extra as String? ?? '',
      ),
    ),
    GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/verify', builder: (context, state) => const ResidentVerifyScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/festival', builder: (context, state) => const FestivalScreen()),
  ],
);
