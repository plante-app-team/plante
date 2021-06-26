import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';

part 'osm_address.g.dart';

abstract class OsmAddress implements Built<OsmAddress, OsmAddressBuilder> {
  static final OsmAddress empty = OsmAddress();

  String? get houseNumber;
  String? get road;
  String? get neighbourhood;
  String? get cityDistrict;

  static OsmAddress? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OsmAddress.serializer, json);
  }

  factory OsmAddress([void Function(OsmAddressBuilder) updates]) = _$OsmAddress;
  OsmAddress._();
  static Serializer<OsmAddress> get serializer => _$osmAddressSerializer;
}
