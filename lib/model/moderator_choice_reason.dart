import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';

enum ModeratorChoiceReason {
  // Common
  INFO_FOUND_IN_EXTERNAL_SOURCE,

  // Why positive:
  ALL_INGREDIENTS_ARE_VEGETARIAN,
  ALL_INGREDIENTS_ARE_VEGAN,
  AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY,
  AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGETARIAN_IN_MODERN_FOOD_INDUSTRY,
  MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_ABSENCE,
  MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE,

  // Why negative
  SOME_INGREDIENT_IS_NON_VEGETARIAN,
  SOME_INGREDIENT_IS_NON_VEGAN,
  HONEY_IN_INGREDIENTS,
  MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_PRESENCE,
  MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE,
  TESTED_ON_ANIMALS,

  // Why possible
  SOME_INGREDIENT_IS_POSSIBLY_NON_VEGETARIAN,
  SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN,
  SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGETARIAN_INGREDIENTS,
  SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS,

  // Why unknown
  SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN,
}

extension ModeratorChoiceReasonExt on ModeratorChoiceReason {
  // WARNING: DO NOT MODIFY CODES OF EXISTING ITEMS
  int get persistentId {
    switch (this) {
      case ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
        return 1;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGETARIAN:
        return 2;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN:
        return 3;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY:
        return 4;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGETARIAN_IN_MODERN_FOOD_INDUSTRY:
        return 5;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_ABSENCE:
        return 6;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE:
        return 7;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN:
        return 8;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN:
        return 9;
      case ModeratorChoiceReason.HONEY_IN_INGREDIENTS:
        return 10;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_PRESENCE:
        return 11;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE:
        return 12;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return 13;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGETARIAN:
        return 14;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN:
        return 15;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGETARIAN_INGREDIENTS:
        return 16;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
        return 17;
      case ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN:
        return 18;
    }
  }

  String localize(BuildContext context) {
    switch (this) {
      case ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
        return context.strings.mod_reason_info_found_in_external_source;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGETARIAN:
        return context.strings.mod_reason_all_ingredients_are_vegetarian;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN:
        return context.strings.mod_reason_all_ingredients_are_vegan;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY:
        return context.strings
            .mod_reason_ambiguous_ingredients_are_almost_always_vegan_in_modern_food_industry;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGETARIAN_IN_MODERN_FOOD_INDUSTRY:
        return context.strings
            .mod_reason_ambiguous_ingredients_are_almost_always_vegetarian_in_modern_food_industry;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_ABSENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegetarian_ingredients_absence;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegan_ingredients_absence;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGETARIAN:
        return context.strings.mod_reason_some_ingredient_is_non_vegetarian;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN:
        return context.strings.mod_reason_some_ingredient_is_non_vegan;
      case ModeratorChoiceReason.HONEY_IN_INGREDIENTS:
        return context.strings.mod_reason_honey_in_ingredients;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGETARIAN_INGREDIENTS_PRESENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegetarian_ingredients_presence;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegan_ingredients_presence;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return context.strings.mod_reason_tested_on_animals;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGETARIAN:
        return context
            .strings.mod_reason_some_ingredient_is_possibly_non_vegetarian;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN:
        return context.strings.mod_reason_some_ingredient_is_possibly_non_vegan;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGETARIAN_INGREDIENTS:
        return context.strings
            .mod_reason_some_of_product_series_have_non_vegetarian_ingredients;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
        return context.strings
            .mod_reason_some_of_product_series_have_non_vegan_ingredients;
      case ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN:
        return context.strings.mod_reason_some_ingredient_has_unknown_origin;
    }
  }
}

ModeratorChoiceReason? moderatorChoiceReasonFromPersistentId(int id) {
  for (final value in ModeratorChoiceReason.values) {
    if (value.persistentId == id) {
      return value;
    }
  }
  return null;
}
