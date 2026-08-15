import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoriteRestaurantIdsKey = 'favorite_restaurant_ids';

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, Set<int>>(
    (ref) => FavoriteNotifier());

class FavoriteNotifier extends StateNotifier<Set<int>> {
  FavoriteNotifier() : super({});

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds =
        prefs.getStringList(_favoriteRestaurantIdsKey) ?? const [];
    state = storedIds.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> toggle(int restaurantId) async {
    if (state.contains(restaurantId)) {
      state = {...state}..remove(restaurantId);
    } else {
      state = {...state, restaurantId};
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoriteRestaurantIdsKey,
      state.map((id) => id.toString()).toList(),
    );
  }

  bool isFavorite(int restaurantId) => state.contains(restaurantId);
}
