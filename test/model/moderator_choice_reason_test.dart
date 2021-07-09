import 'package:plante/model/moderator_choice_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {});

  test('persistent IDs are unique', () {
    expect(ModeratorChoiceReason.values.length,
        equals(ModeratorChoiceReason.values.toSet().length));
  });

  test('persistent ID have not changed', () {
    final idsMap = {
      ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE: 1,
      ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGETARIAN: 2,
      ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN: 3,
      ModeratorChoiceReason.AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY: 4,
      ModeratorChoiceReason.AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGETARIAN_IN_MODERN_FOOD_INDUSTRY: 5,
      ModeratorChoiceReason.MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_ABSENCE: 6,
      ModeratorChoiceReason.MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE: 7,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN: 8,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN: 9,
      ModeratorChoiceReason.HONEY_IN_INGREDIENTS: 10,
      ModeratorChoiceReason.MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_PRESENCE: 11,
      ModeratorChoiceReason.MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE: 12,
      ModeratorChoiceReason.TESTED_ON_ANIMALS: 13,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGETARIAN: 14,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN: 15,
      ModeratorChoiceReason.SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGETARIAN_INGREDIENTS: 16,
      ModeratorChoiceReason.SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS: 17,
      ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN: 18
    };

    expect(idsMap.keys.toSet(), equals(ModeratorChoiceReason.values.toSet()),
      reason: 'Content of ModeratorChoiceReason has change. '
          'NEVER remove items from the enum, unless you 100% sure it '
          'will not break anything. '
          'If a new item is added, add it to the failed test');

    for (final item in ModeratorChoiceReason.values) {
      expect(item.persistentId, equals(idsMap[item]));
    }
  });

  test('all reasons are either vegan or vegetarian', () {
    final veganAndVegetarianStatuses = (veganModeratorChoiceReasons()
        + vegetarianModeratorChoiceReasons()).toSet();
    expect(veganAndVegetarianStatuses,
        equals(ModeratorChoiceReason.values.toSet()));
  });
}
