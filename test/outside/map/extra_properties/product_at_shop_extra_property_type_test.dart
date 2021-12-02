import 'package:plante/outside/map/extra_properties/product_at_shop_extra_property_type.dart';
import 'package:test/test.dart';

void main() {
  test('persistent codes are same as they were', () async {
    final expected = {
      ProductAtShopExtraPropertyType.FOR_TESTS: -2,
      ProductAtShopExtraPropertyType.INVALID: -1,
      ProductAtShopExtraPropertyType.VOTE_RECEIVED_POSITIVE: 1,
      ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE: 2,
      ProductAtShopExtraPropertyType.BAD_SUGGESTION: 3,
    };

    final factual = {
      for (final type in ProductAtShopExtraPropertyType.values)
        type: type.persistentCode
    };
    expect(factual, equals(expected));
  });
}
