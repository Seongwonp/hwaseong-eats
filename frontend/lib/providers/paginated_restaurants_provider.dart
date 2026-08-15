import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/restaurant.dart';
import '../services/api_service.dart';

const restaurantPageSize = 20;

class RestaurantPage {
  const RestaurantPage({required this.items, required this.total});

  final List<Restaurant> items;
  final int total;
}

typedef RestaurantPageLoader = Future<RestaurantPage> Function({
  required int limit,
  required int offset,
});

class PaginatedRestaurantsState {
  const PaginatedRestaurantsState({
    this.items = const [],
    this.total = 0,
    this.nextOffset = 0,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.initialError,
    this.loadMoreError,
  });

  final List<Restaurant> items;
  final int total;
  final int nextOffset;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? initialError;
  final Object? loadMoreError;

  PaginatedRestaurantsState copyWith({
    List<Restaurant>? items,
    int? total,
    int? nextOffset,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? initialError,
    Object? loadMoreError,
    bool clearInitialError = false,
    bool clearLoadMoreError = false,
  }) {
    return PaginatedRestaurantsState(
      items: items ?? this.items,
      total: total ?? this.total,
      nextOffset: nextOffset ?? this.nextOffset,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      initialError:
          clearInitialError ? null : (initialError ?? this.initialError),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

class PaginatedRestaurantsNotifier
    extends StateNotifier<PaginatedRestaurantsState> {
  PaginatedRestaurantsNotifier(this._loadPage)
      : super(const PaginatedRestaurantsState()) {
    _fetchInitial();
  }

  final RestaurantPageLoader _loadPage;
  bool _disposed = false;

  Future<void> retryInitial() async {
    if (state.isInitialLoading) return;
    state = const PaginatedRestaurantsState();
    await _fetchInitial();
  }

  Future<void> loadMore() async {
    if (_disposed ||
        state.isInitialLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(
      isLoadingMore: true,
      clearLoadMoreError: true,
    );
    await _fetch(offset: state.nextOffset, initial: false);
  }

  Future<void> retryLoadMore() => loadMore();

  Future<void> _fetchInitial() => _fetch(offset: 0, initial: true);

  Future<void> _fetch({required int offset, required bool initial}) async {
    try {
      final page = await _loadPage(limit: restaurantPageSize, offset: offset);
      if (_disposed) return;

      final byId = <int, Restaurant>{
        if (!initial)
          for (final item in state.items) item.id: item,
        for (final item in page.items) item.id: item,
      };
      final nextOffset = offset + page.items.length;
      state = state.copyWith(
        items: byId.values.toList(),
        total: page.total,
        nextOffset: nextOffset,
        isInitialLoading: false,
        isLoadingMore: false,
        hasMore: page.items.isNotEmpty && nextOffset < page.total,
        clearInitialError: true,
        clearLoadMoreError: true,
      );
    } catch (error) {
      if (_disposed) return;
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        initialError: initial ? error : null,
        loadMoreError: initial ? null : error,
        clearInitialError: !initial,
        clearLoadMoreError: initial,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final paginatedRestaurantsProvider = StateNotifierProvider.autoDispose
    .family<PaginatedRestaurantsNotifier, PaginatedRestaurantsState, String>(
        (ref, query) {
  return PaginatedRestaurantsNotifier((
      {required limit, required offset}) async {
    final response = await ApiService().getRestaurants(
      q: query,
      limit: limit,
      offset: offset,
    );
    final data = response.data as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    return RestaurantPage(
      items: rawItems
          .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: data['total'] as int? ?? 0,
    );
  });
});
