import 'package:flutter_test/flutter_test.dart';
import 'package:plante/outside/backend/news/news_piece_type.dart';

void main() {
  setUp(() async {});

  test('concrete persistent codes values', () {
    // If new elements added, test must be changed
    expect(NewsPieceType.values.length, equals(2));

    // Same persistent values are also used in the backend -
    // it's prohibited to change the values.
    expect(NewsPieceType.UNKNOWN.persistentCode, equals(-1));
    expect(NewsPieceType.PRODUCT_AT_SHOP.persistentCode, equals(1));
  });

  test('values can be obtained from their persistent codes', () {
    for (final type in NewsPieceType.values) {
      expect(type, equals(newsPieceTypeFromCode(type.persistentCode)));
    }
  });
}
