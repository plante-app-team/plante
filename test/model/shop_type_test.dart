import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/shop_type.dart';

void main() {
  setUp(() async {});

  test('valuesOrderedForUI has all the values', () {
    expect(
        ShopType.valuesOrderedForUI.toSet(), equals(ShopType.values.toSet()));
  });
}
