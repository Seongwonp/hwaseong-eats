import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hwaseong_eats/models/restaurant.dart';
import 'package:hwaseong_eats/providers/paginated_restaurants_provider.dart';

Restaurant _restaurant(int id) => Restaurant(
      id: id,
      name: '가게 $id',
      address: '화성시',
      isKonapay: true,
      isMobeom: false,
      tags: const [],
    );

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 50 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

void main() {
  test('원본 offset을 유지하며 중복 없는 다음 페이지를 합친다', () async {
    final requestedOffsets = <int>[];
    final notifier = PaginatedRestaurantsNotifier(
      ({required limit, required offset}) async {
        requestedOffsets.add(offset);
        if (offset == 0) {
          return RestaurantPage(
            items: List.generate(20, _restaurant),
            total: 41,
          );
        }
        if (offset == 20) {
          return RestaurantPage(
            items: [
              _restaurant(19),
              ...List.generate(19, (index) => _restaurant(index + 20)),
            ],
            total: 41,
          );
        }
        return RestaurantPage(items: [_restaurant(40)], total: 41);
      },
    );

    await _waitUntil(() => !notifier.state.isInitialLoading);
    expect(notifier.state.items, hasLength(20));
    expect(notifier.state.nextOffset, 20);

    await notifier.loadMore();
    expect(notifier.state.items, hasLength(39));
    expect(notifier.state.nextOffset, 40);

    await notifier.loadMore();
    expect(notifier.state.items, hasLength(40));
    expect(notifier.state.hasMore, isFalse);
    expect(requestedOffsets, [0, 20, 40]);

    notifier.dispose();
  });

  test('다음 페이지 중복 요청을 막고 실패한 페이지를 재시도한다', () async {
    final secondPage = Completer<RestaurantPage>();
    var calls = 0;
    final notifier = PaginatedRestaurantsNotifier(
      ({required limit, required offset}) async {
        calls++;
        if (offset == 0) {
          return RestaurantPage(
            items: List.generate(20, _restaurant),
            total: 40,
          );
        }
        if (calls == 2) return secondPage.future;
        return RestaurantPage(
          items: List.generate(20, (index) => _restaurant(index + 20)),
          total: 40,
        );
      },
    );

    await _waitUntil(() => !notifier.state.isInitialLoading);
    final firstRequest = notifier.loadMore();
    final duplicateRequest = notifier.loadMore();
    expect(calls, 2);
    await duplicateRequest;

    secondPage.completeError(Exception('network'));
    await firstRequest;
    expect(notifier.state.items, hasLength(20));
    expect(notifier.state.loadMoreError, isNotNull);

    await notifier.retryLoadMore();
    expect(notifier.state.items, hasLength(40));
    expect(notifier.state.loadMoreError, isNull);
    expect(notifier.state.hasMore, isFalse);

    notifier.dispose();
  });
}
