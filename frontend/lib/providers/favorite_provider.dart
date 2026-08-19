import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoriteRestaurantIdsKey = 'favorite_restaurant_ids';

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, Set<int>>(
    (ref) => FavoriteNotifier());

class FavoriteNotifier extends StateNotifier<Set<int>> {
  FavoriteNotifier() : super({});

  final _toggling = <int>{};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds =
        prefs.getStringList(_favoriteRestaurantIdsKey) ?? const [];
    state = storedIds.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> toggle(int restaurantId) async {
    if (_toggling.contains(restaurantId)) return;
    _toggling.add(restaurantId);

    final previous = state;
    if (state.contains(restaurantId)) {
      state = {...state}..remove(restaurantId);
    } else {
      state = {...state, restaurantId};
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoriteRestaurantIdsKey,
        state.map((id) => id.toString()).toList(),
      );
    } catch (_) {
      state = previous;
    } finally {
      _toggling.remove(restaurantId);
    }
  }

  bool isFavorite(int restaurantId) => state.contains(restaurantId);
}
