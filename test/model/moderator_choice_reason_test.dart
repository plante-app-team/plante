import 'package:flutter_test/flutter_test.dart';
import 'package:plante/model/moderator_choice_reason.dart';
import 'package:plante/model/veg_status.dart';

void main() {
  setUp(() async {});

  void _ensureAllReasonsHandled(
      Iterable<ModeratorChoiceReason> handledReasons) {
    expect(handledReasons.toSet(), equals(ModeratorChoiceReason.values.toSet()),
        reason: 'Content of ModeratorChoiceReason has change. '
            'NEVER remove items from the enum, unless you 100% sure it '
            'will not break anything. '
            'If a new item is added, add it to the failed test');
  }

  test('persistent IDs are unique', () {
    expect(ModeratorChoiceReason.values.length,
        equals(ModeratorChoiceReason.values.toSet().length));
  });

  test('persistent ID have not changed', () {
    final idsMap = {
      ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE: 1,
      ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN: 3,
      ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY: 4,
      ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE: 7,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN: 9,
      ModeratorChoiceReason.HONEY_IN_INGREDIENTS: 10,
      ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE: 12,
      ModeratorChoiceReason.TESTED_ON_ANIMALS: 13,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN: 15,
      ModeratorChoiceReason.SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
          17,
      ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN: 18,
      ModeratorChoiceReason.SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY: 19,
    };

    _ensureAllReasonsHandled(idsMap.keys);

    for (final item in ModeratorChoiceReason.values) {
      expect(item.persistentId, equals(idsMap[item]));
    }
  });

  test('target veg statuses have not changed', () {
    final statusesMap = {
      ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
          VegStatus.values.toSet(),
      ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN: {VegStatus.positive},
      ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY: {
        VegStatus.positive
      },
      ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE: {
        VegStatus.positive
      },
      ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN: {VegStatus.negative},
      ModeratorChoiceReason.HONEY_IN_INGREDIENTS: {VegStatus.negative},
      ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE: {
        VegStatus.negative
      },
      ModeratorChoiceReason.TESTED_ON_ANIMALS: {VegStatus.negative},
      ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN: {
        VegStatus.possible
      },
      ModeratorChoiceReason.SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS: {
        VegStatus.possible
      },
      ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN: {
        VegStatus.unknown
      },
      ModeratorChoiceReason.SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY: {
        VegStatus.possible
      },
    };

    _ensureAllReasonsHandled(statusesMap.keys);

    for (final item in ModeratorChoiceReason.values) {
      expect(item.targetStatuses, equals(statusesMap[item]));
    }
  });
}
