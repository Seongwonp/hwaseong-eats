import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hwaseong_eats/models/restaurant.dart';
import 'package:hwaseong_eats/widgets/restaurant_bottom_sheet.dart';

void main() {
  testWidgets('식사평 작성 화면에 실제 음식점 객체를 전달한다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const restaurant = Restaurant(
      id: 3380,
      name: 'espresso',
      address: '경기 화성시 동탄대로시범길',
      isKonapay: true,
      isMobeom: false,
      tags: [],
    );
    Object? receivedExtra;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) =>
                      const RestaurantBottomSheet(restaurant: restaurant),
                ),
                child: const Text('음식점 열기'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/review/:id',
          builder: (context, state) {
            receivedExtra = state.extra;
            return const Scaffold(body: Text('리뷰 화면'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('음식점 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('식사평 남기기'));
    await tester.pumpAndSettle();

    expect(find.text('리뷰 화면'), findsOneWidget);
    expect(receivedExtra, same(restaurant));

    router.dispose();
  });
}
