import 'package:flutter_test/flutter_test.dart';
import 'package:plante/contributions/user_contribution_type.dart';

void main() {
  setUp(() async {});

  test('concrete persistent codes values', () {
    // If new elements added, test must be changed
    expect(UserContributionType.values.length, equals(6));

    // Same persistent values are also used in the backend -
    // it's prohibited to change the values.
    expect(UserContributionType.UNKNOWN.persistentCode, equals(-1));
    expect(UserContributionType.PRODUCT_EDITED.persistentCode, equals(1));
    expect(
        UserContributionType.PRODUCT_ADDED_TO_SHOP.persistentCode, equals(2));
    expect(UserContributionType.PRODUCT_REPORTED.persistentCode, equals(3));
    expect(UserContributionType.SHOP_CREATED.persistentCode, equals(4));
    expect(
        UserContributionType.LEGACY_PRODUCT_EDITED.persistentCode, equals(5));
  });

  test('values can be obtained from their persistent codes', () {
    for (final type in UserContributionType.values) {
      expect(type, equals(userContributionTypeFromCode(type.persistentCode)));
    }
  });
}
