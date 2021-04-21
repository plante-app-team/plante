import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/log.dart';

part 'veg_status.g.dart';

class VegStatus extends EnumClass {
  // !!! WARNING !!!
  static const VegStatus positive = _$positive; // DO
  static const VegStatus negative = _$negative; // NOT
  static const VegStatus possible = _$possible; // RENAME
  static const VegStatus unknown = _$unknown; // FIELDS
  // !!! THEY ARE USED FOR SERVER RESPONSES (DE)SERIALIZATION !!!

  const VegStatus._(String name) : super(name);

  static BuiltSet<VegStatus> get values => _$values;
  static VegStatus valueOf(String name) => _$valueOf(name);
  static Serializer<VegStatus> get serializer => _$vegStatusSerializer;

  static VegStatus? safeValueOf(String name) {
    try {
      return valueOf(name);
    } on ArgumentError catch(e) {
      Log.w("VegStatus unknown name: $name", ex: e);
      return null;
    }
  }
}
