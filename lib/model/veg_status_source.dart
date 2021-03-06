import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/logging/log.dart';

part 'veg_status_source.g.dart';

class VegStatusSource extends EnumClass {
  // !!! WARNING !!!
  static const VegStatusSource open_food_facts = _$open_food_facts; // DO
  static const VegStatusSource community = _$community; // NOT
  static const VegStatusSource moderator = _$moderator; // RENAME
  static const VegStatusSource unknown = _$unknown; // FIELDS
  // !!! THEY ARE USED FOR SERVER RESPONSES (DE)SERIALIZATION !!!

  const VegStatusSource._(String name) : super(name);

  static BuiltSet<VegStatusSource> get values => _$values;
  static VegStatusSource valueOf(String name) => _$valueOf(name);
  static Serializer<VegStatusSource> get serializer =>
      _$vegStatusSourceSerializer;

  static VegStatusSource? safeValueOf(String name) {
    if (name.trim().isEmpty) {
      return null;
    }
    try {
      return valueOf(name);
    } on ArgumentError catch (e) {
      Log.w('Unknown VegStatusSource name: $name', ex: e);
      return null;
    }
  }
}

extension VegStatusSourcePriority on VegStatusSource? {
  /// The higher the better
  int get priority {
    switch (this) {
      case null:
        return 0;
      case VegStatusSource.unknown:
        return 0;
      case VegStatusSource.open_food_facts:
        return 1;
      case VegStatusSource.community:
        return 2;
      case VegStatusSource.moderator:
        return 3;
      default:
        throw Exception('Unknown value: $this');
    }
  }
}
