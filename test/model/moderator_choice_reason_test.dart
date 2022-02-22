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
      ModeratorChoiceReason
          .INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL: 20,
      ModeratorChoiceReason.CANE_SUGAR_IN_INGREDIENTS: 21,
      ModeratorChoiceReason.POSSIBLY_CANE_SUGAR_IN_INGREDIENTS: 22,
      ModeratorChoiceReason.CERTIFIED_VEGAN: 23,
      ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM: 24,
      ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS: 25,
      ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS: 26,
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
      ModeratorChoiceReason
          .INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL: {
        VegStatus.positive
      },
      ModeratorChoiceReason.CANE_SUGAR_IN_INGREDIENTS: {VegStatus.possible},
      ModeratorChoiceReason.POSSIBLY_CANE_SUGAR_IN_INGREDIENTS: {
        VegStatus.possible
      },
      ModeratorChoiceReason.CERTIFIED_VEGAN: {VegStatus.positive},
      ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM: {
        VegStatus.possible
      },
      ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS: {
        VegStatus.negative
      },
      ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS: {
        VegStatus.possible,
        VegStatus.unknown,
      },
    };

    _ensureAllReasonsHandled(statusesMap.keys);

    for (final item in ModeratorChoiceReason.values) {
      expect(item.targetStatuses, equals(statusesMap[item]));
    }
  });

  test('printWarningOnProduct has not changed', () {
    final expectations = {
      for (final reason in ModeratorChoiceReason.values) reason: false
    };
    expectations[ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM] =
        true;
    expectations[ModeratorChoiceReason
        .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS] = true;

    _ensureAllReasonsHandled(expectations.keys);

    for (final reason in ModeratorChoiceReason.values) {
      expect(reason.printWarningOnProduct, expectations[reason]);
    }
  });
}
