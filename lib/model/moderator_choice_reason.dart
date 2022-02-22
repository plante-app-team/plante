import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/veg_status.dart';

enum ModeratorChoiceReason {
  // Common
  INFO_FOUND_IN_EXTERNAL_SOURCE,

  // Why positive:
  ALL_INGREDIENTS_ARE_VEGAN,
  AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY,
  MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE,
  INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL,
  CERTIFIED_VEGAN,

  // Why negative
  SOME_INGREDIENT_IS_NON_VEGAN,
  HONEY_IN_INGREDIENTS,
  MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE,
  TESTED_ON_ANIMALS,
  MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS,

  // Why ambiguous
  SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN,
  SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY,
  SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS,
  CANE_SUGAR_IN_INGREDIENTS,
  POSSIBLY_CANE_SUGAR_IN_INGREDIENTS,
  NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM,
  MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS,

  // Why unknown
  SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN,
}

extension ModeratorChoiceReasonExt on ModeratorChoiceReason {
  // WARNING: DO NOT MODIFY CODES OF EXISTING ITEMS
  // WARNING: DO NOT REUSE CODES
  int get persistentId {
    switch (this) {
      case ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
        return 1;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN:
        return 3;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY:
        return 4;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE:
        return 7;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN:
        return 9;
      case ModeratorChoiceReason.HONEY_IN_INGREDIENTS:
        return 10;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE:
        return 12;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return 13;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN:
        return 15;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
        return 17;
      case ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN:
        return 18;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY:
        return 19;
      case ModeratorChoiceReason
          .INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL:
        return 20;
      case ModeratorChoiceReason.CANE_SUGAR_IN_INGREDIENTS:
        return 21;
      case ModeratorChoiceReason.POSSIBLY_CANE_SUGAR_IN_INGREDIENTS:
        return 22;
      case ModeratorChoiceReason.CERTIFIED_VEGAN:
        return 23;
      case ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM:
        return 24;
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS:
        return 25;
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS:
        return 26;
    }
  }

  Set<VegStatus> get targetStatuses {
    switch (this) {
      case ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
        return VegStatus.values.toSet(); // All of them
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN:
        return {VegStatus.positive};
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY:
        return {VegStatus.positive};
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE:
        return {VegStatus.positive};
      case ModeratorChoiceReason
          .INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL:
        return {VegStatus.positive};
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN:
        return {VegStatus.negative};
      case ModeratorChoiceReason.HONEY_IN_INGREDIENTS:
        return {VegStatus.negative};
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE:
        return {VegStatus.negative};
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return {VegStatus.negative};
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN:
        return {VegStatus.possible};
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
        return {VegStatus.possible};
      case ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN:
        return {VegStatus.unknown};
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY:
        return {VegStatus.possible};
      case ModeratorChoiceReason.CANE_SUGAR_IN_INGREDIENTS:
        return {VegStatus.possible};
      case ModeratorChoiceReason.POSSIBLY_CANE_SUGAR_IN_INGREDIENTS:
        return {VegStatus.possible};
      case ModeratorChoiceReason.CERTIFIED_VEGAN:
        return {VegStatus.positive};
      case ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM:
        return {VegStatus.possible};
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS:
        return {VegStatus.negative};
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS:
        return {VegStatus.possible, VegStatus.unknown};
    }
  }

  String localize(BuildContext context) {
    switch (this) {
      case ModeratorChoiceReason.INFO_FOUND_IN_EXTERNAL_SOURCE:
        return context.strings.mod_reason_info_found_in_external_source;
      case ModeratorChoiceReason.ALL_INGREDIENTS_ARE_VEGAN:
        return context.strings.mod_reason_all_ingredients_are_vegan;
      case ModeratorChoiceReason
          .AMBIGUOUS_INGREDIENTS_ARE_ALMOST_ALWAYS_VEGAN_IN_MODERN_FOOD_INDUSTRY:
        return context.strings
            .mod_reason_ambiguous_ingredients_are_almost_always_vegan_in_modern_food_industry;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_ABSENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegan_ingredients_absence;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_NON_VEGAN:
        return context.strings.mod_reason_some_ingredient_is_non_vegan;
      case ModeratorChoiceReason.HONEY_IN_INGREDIENTS:
        return context.strings.mod_reason_honey_in_ingredients;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_NON_VEGAN_INGREDIENTS_PRESENCE:
        return context.strings
            .mod_reason_manufacturer_confirmed_non_vegan_ingredients_presence;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return context.strings.mod_reason_tested_on_animals;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_POSSIBLY_NON_VEGAN:
        return context.strings.mod_reason_some_ingredient_is_possibly_non_vegan;
      case ModeratorChoiceReason
          .SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS:
        return context.strings
            .mod_reason_some_of_product_series_have_non_vegan_ingredients;
      case ModeratorChoiceReason.SOME_INGREDIENT_HAS_UNKNOWN_ORIGIN:
        return context.strings.mod_reason_some_ingredient_has_unknown_origin;
      case ModeratorChoiceReason.SOME_INGREDIENT_IS_IN_FACT_A_CATEGORY:
        return context
            .strings.mod_reason_some_ingredient_is_in_fact_a_category2;
      case ModeratorChoiceReason
          .INGREDIENTS_LIST_HAS_AMBIGUOUS_ENTRIES_BUT_PRODUCT_HAS_VEGAN_LABEL:
        return context.strings
            .mod_reason_ingredients_list_has_ambiguous_entries_but_product_has_vegan_label;
      case ModeratorChoiceReason.CANE_SUGAR_IN_INGREDIENTS:
        return context.strings.mod_reason_cane_sugar_in_ingredients;
      case ModeratorChoiceReason.POSSIBLY_CANE_SUGAR_IN_INGREDIENTS:
        return context.strings.mod_reason_possibly_cane_sugar_in_ingredients;
      case ModeratorChoiceReason.CERTIFIED_VEGAN:
        return context.strings.mod_reason_certified_vegan;
      case ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM:
        return context
            .strings.mod_reason_non_vegan_practices_but_helps_veganism;
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_VERY_SUSPICIOUS_INGREDIENTS:
        return context.strings
            .mod_reason_manufacturer_did_not_help_with_very_suspicious_ingredients;
      case ModeratorChoiceReason
          .MANUFACTURER_DID_NOT_HELP_WITH_AMBIGUOUS_INGREDIENTS:
        return context.strings
            .mod_reason_manufacturer_did_not_help_with_ambiguous_ingredients;
    }
  }

  bool get printWarningOnProduct {
    return [
      ModeratorChoiceReason.NON_VEGAN_PRACTICES_BUT_HELPS_VEGANISM,
      ModeratorChoiceReason.SOME_OF_PRODUCT_SERIES_HAVE_NON_VEGAN_INGREDIENTS,
    ].contains(this);
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

List<ModeratorChoiceReason> moderatorChoiceReasonFromPersistentIdsStr(
    String? moderatorVeganChoiceReasonsIdsStr) {
  if (moderatorVeganChoiceReasonsIdsStr == null) {
    return const [];
  }
  final strs = moderatorVeganChoiceReasonsIdsStr.split(',');
  final result = <ModeratorChoiceReason>[];
  for (final str in strs) {
    final reason =
        moderatorChoiceReasonFromPersistentId(int.tryParse(str) ?? -1);
    if (reason == null) {
      Log.w('Could not parse ModeratorChoiceReason: $str');
      continue;
    }
    result.add(reason);
  }
  return result;
}
