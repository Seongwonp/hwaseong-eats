import 'package:flutter_riverpod/flutter_riverpod.dart';

// 저장한 가게 ID 집합 (로컬 상태)
final favoriteProvider = StateNotifierProvider<FavoriteNotifier, Set<int>>((ref) => FavoriteNotifier());

class FavoriteNotifier extends StateNotifier<Set<int>> {
  FavoriteNotifier() : super({});

  void toggle(int restaurantId) {
    if (state.contains(restaurantId)) {
      state = {...state}..remove(restaurantId);
    } else {
      state = {...state, restaurantId};
    }
  }

  bool isFavorite(int restaurantId) => state.contains(restaurantId);
}
