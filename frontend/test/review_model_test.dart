import 'package:flutter_test/flutter_test.dart';
import 'package:hwaseong_eats/models/review.dart';

void main() {
  test('review response fields are parsed', () {
    final review = Review.fromJson({
      'id': 1,
      'restaurant_id': 2,
      'nickname': '화성테스터',
      'tags': ['가성비', '혼밥'],
      'rating': 5,
      'comment': '맛있어요',
      'is_hwaseong_certified': true,
      'created_at': '2026-08-15T09:00:00+09:00',
    });

    expect(review.restaurantId, 2);
    expect(review.tags, ['가성비', '혼밥']);
    expect(review.rating, 5);
    expect(review.isHwaseongCertified, isTrue);
    expect(review.createdAt.year, 2026);
  });

  test('nullable review fields and missing tags use safe defaults', () {
    final review = Review.fromJson({
      'id': 1,
      'restaurant_id': 2,
      'nickname': '작성자',
      'tags': null,
      'rating': null,
      'comment': null,
      'is_hwaseong_certified': false,
      'created_at': '2026-08-15T00:00:00Z',
    });

    expect(review.tags, isEmpty);
    expect(review.rating, isNull);
    expect(review.comment, isNull);
    expect(review.isHwaseongCertified, isFalse);
  });
}
