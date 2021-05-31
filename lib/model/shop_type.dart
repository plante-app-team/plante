import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/l10n/strings.dart';

part 'shop_type.g.dart';

class ShopType extends EnumClass {
  static const ShopType bakery = _$bakery;
  static const ShopType beverages = _$beverages;
  static const ShopType cheese = _$cheese;
  static const ShopType chocolate = _$chocolate;
  static const ShopType coffee = _$coffee;
  static const ShopType confectionery = _$confectionery;
  static const ShopType convenience = _$convenience;
  static const ShopType deli = _$deli;
  static const ShopType dairy = _$dairy;
  static const ShopType farm = _$farm;
  static const ShopType frozen_food = _$frozen_food;
  static const ShopType greengrocer = _$greengrocer;
  static const ShopType health_food = _$health_food;
  static const ShopType ice_cream = _$ice_cream;
  static const ShopType organic = _$organic;
  static const ShopType pasta = _$pasta;
  static const ShopType pastry = _$pastry;
  static const ShopType spices = _$spices;
  static const ShopType general = _$general;
  static const ShopType supermarket = _$supermarket;
  static const ShopType grocery = _$grocery;

  const ShopType._(String name) : super(name);

  static BuiltSet<ShopType> get values => _$values;
  static ShopType valueOf(String name) => _$valueOf(name);

  static ShopType? safeValueOf(String name) {
    if (name.trim().isEmpty) {
      return null;
    }
    try {
      return valueOf(name);
    } on ArgumentError catch (e) {
      Log.w('Unknown ShopType name: $name', ex: e);
      return null;
    }
  }

  String get osmName {
    switch (this) {
      case bakery:
        return 'bakery';
      case beverages:
        return 'beverages';
      case cheese:
        return 'cheese';
      case chocolate:
        return 'chocolate';
      case coffee:
        return 'coffee';
      case confectionery:
        return 'confectionery';
      case convenience:
        return 'convenience';
      case deli:
        return 'deli';
      case dairy:
        return 'dairy';
      case farm:
        return 'farm';
      case frozen_food:
        return 'frozen_food';
      case greengrocer:
        return 'greengrocer';
      case health_food:
        return 'health_food';
      case ice_cream:
        return 'ice_cream';
      case organic:
        return 'organic';
      case pasta:
        return 'pasta';
      case pastry:
        return 'pastry';
      case spices:
        return 'spices';
      case general:
        return 'general';
      case supermarket:
        return 'supermarket';
      case grocery:
        return 'grocery';
      default:
        throw Exception('Unknown shop type: $this');
    }
  }

  String localize(BuildContext context) {
    switch (this) {
      case bakery:
        return context.strings.shop_type_bakery;
      case beverages:
        return context.strings.shop_type_beverages;
      case cheese:
        return context.strings.shop_type_cheese;
      case chocolate:
        return context.strings.shop_type_chocolate;
      case coffee:
        return context.strings.shop_type_coffee;
      case confectionery:
        return context.strings.shop_type_confectionery;
      case convenience:
        return context.strings.shop_type_convenience;
      case deli:
        return context.strings.shop_type_deli;
      case dairy:
        return context.strings.shop_type_dairy;
      case farm:
        return context.strings.shop_type_farm;
      case frozen_food:
        return context.strings.shop_type_frozen_food;
      case greengrocer:
        return context.strings.shop_type_greengrocer;
      case health_food:
        return context.strings.shop_type_health_food;
      case ice_cream:
        return context.strings.shop_type_ice_cream;
      case organic:
        return context.strings.shop_type_organic;
      case pasta:
        return context.strings.shop_type_pasta;
      case pastry:
        return context.strings.shop_type_pastry;
      case spices:
        return context.strings.shop_type_spices;
      case general:
        return context.strings.shop_type_general;
      case supermarket:
        return context.strings.shop_type_supermarket;
      case grocery:
        return context.strings.shop_type_grocery;
      default:
        throw Exception('Unknown shop type: $this');
    }
  }
}
