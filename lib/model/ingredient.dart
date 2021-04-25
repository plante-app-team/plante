import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';
import 'package:plante/model/veg_status.dart';

part 'ingredient.g.dart';

abstract class Ingredient implements Built<Ingredient, IngredientBuilder> {
  String get name;

  /// If null then status isn't applicable to the ingredient and should be ignored
  VegStatus? get vegetarianStatus;

  /// If null then status isn't applicable to the ingredient and should be ignored
  VegStatus? get veganStatus;

  static Ingredient? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers.deserializeWith(serializer, json);
  }

  Map<String, dynamic> toJson() {
    return BuildValueHelper.jsonSerializers.serializeWith(serializer, this)
        as Map<String, dynamic>;
  }

  factory Ingredient([void Function(IngredientBuilder) updates]) = _$Ingredient;
  Ingredient._();
  static Serializer<Ingredient> get serializer => _$ingredientSerializer;
}
