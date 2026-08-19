import 'package:flutter_test/flutter_test.dart';
import 'package:hwaseong_eats/providers/favorite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('저장한 가게 ID를 복원하고 변경 내용을 유지한다', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_restaurant_ids': ['10', 'invalid', '20'],
    });
    final notifier = FavoriteNotifier();

    await notifier.initialize();
    expect(notifier.state, {10, 20});

    await notifier.toggle(10);
    await notifier.toggle(30);

    expect(notifier.state, {20, 30});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_restaurant_ids'), ['20', '30']);

    notifier.dispose();
  });
}
