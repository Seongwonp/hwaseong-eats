import 'package:go_router/go_router.dart';
import '../models/restaurant.dart';
import '../screens/splash_screen.dart';
import '../screens/main_shell.dart';
import '../screens/search_screen.dart';
import '../screens/review_screen.dart';
import '../screens/reward_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/login_screen.dart';
import '../screens/resident_verify_screen.dart';
import '../screens/restaurant_detail_screen.dart';
import '../screens/keyword_recommendations_screen.dart';
import '../screens/new_restaurants_screen.dart';
import '../screens/saved_restaurants_screen.dart';
import '../screens/my_reviews_screen.dart';
import '../screens/privacy_policy_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainShell()),
    GoRoute(path: '/map', builder: (_, __) => const MainShell(initialIndex: 0)),
    GoRoute(path: '/calendar', builder: (_, __) => const MainShell(initialIndex: 1)),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(
      path: '/restaurant/:id',
      builder: (_, state) => RestaurantDetailScreen(
        restaurant: state.extra as Restaurant,
      ),
    ),
    GoRoute(
      path: '/review/:id',
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Restaurant) {
          return ReviewScreen(restaurant: extra);
        }
        // fallback: 이름만 전달된 경우 (하위 호환)
        return ReviewScreen(
          restaurant: Restaurant(
            id: int.parse(state.pathParameters['id']!),
            name: extra as String? ?? '',
            address: '',
            lat: null, lng: null, category: null, phone: null,
            isKonapay: false, isMobeom: false, tags: [],
            rating: null, reviewCount: 0,
          ),
        );
      },
    ),
    GoRoute(path: '/reward', builder: (_, __) => const RewardScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/verify', builder: (_, __) => const ResidentVerifyScreen()),
    GoRoute(path: '/keyword-recommendations', builder: (_, __) => const KeywordRecommendationsScreen()),
    GoRoute(path: '/new-restaurants', builder: (_, __) => const NewRestaurantsScreen()),
    GoRoute(path: '/saved-restaurants', builder: (_, __) => const SavedRestaurantsScreen()),
    GoRoute(path: '/my-reviews', builder: (_, __) => const MyReviewsScreen()),
    GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
  ],
);
