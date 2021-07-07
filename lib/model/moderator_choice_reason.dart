import 'package:flutter/material.dart';
import 'package:plante/l10n/strings.dart';

enum ModeratorChoiceReason {
  MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_PRESENCE,
  MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_ABSENCE,
  MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_PRESENCE,
  MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_ABSENCE,
  SOME_INGREDIENTS_ARE_ANIMAL_PRODUCTS,
  SOME_INGREDIENTS_ARE_FROM_DEAD_ANIMALS,
  TESTED_ON_ANIMALS,
}

extension ModeratorChoiceReasonExt on ModeratorChoiceReason {
  // WARNING: DO NOT MODIFY CODES OF EXISTING ITEMS
  int get persistentId {
    switch (this) {
      case ModeratorChoiceReason.MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_PRESENCE:
        return 1;
      case ModeratorChoiceReason.MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_ABSENCE:
        return 2;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_PRESENCE:
        return 3;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_ABSENCE:
        return 4;
      case ModeratorChoiceReason.SOME_INGREDIENTS_ARE_ANIMAL_PRODUCTS:
        return 5;
      case ModeratorChoiceReason.SOME_INGREDIENTS_ARE_FROM_DEAD_ANIMALS:
        return 6;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return 7;
    }
  }

  String localize(BuildContext context) {
    switch (this) {
      case ModeratorChoiceReason.MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_PRESENCE:
        return context.strings
            .moderator_choice_reason_manufacturer_confirmed_animal_product_presence;
      case ModeratorChoiceReason.MANUFACTURER_CONFIRMED_ANIMAL_PRODUCT_ABSENCE:
        return context.strings
            .moderator_choice_reason_manufacturer_confirmed_animal_product_absence;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_PRESENCE:
        return context.strings
            .moderator_choice_reason_manufacturer_confirmed_dead_animal_product_presence;
      case ModeratorChoiceReason
          .MANUFACTURER_CONFIRMED_DEAD_ANIMAL_PRODUCT_ABSENCE:
        return context.strings
            .moderator_choice_reason_manufacturer_confirmed_dead_animal_product_absence;
      case ModeratorChoiceReason.SOME_INGREDIENTS_ARE_ANIMAL_PRODUCTS:
        return context.strings
            .moderator_choice_reason_some_ingredients_are_animal_products;
      case ModeratorChoiceReason.SOME_INGREDIENTS_ARE_FROM_DEAD_ANIMALS:
        return context.strings
            .moderator_choice_reason_some_ingredients_are_from_dead_animals;
      case ModeratorChoiceReason.TESTED_ON_ANIMALS:
        return context.strings.moderator_choice_reason_tested_on_animals;
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
