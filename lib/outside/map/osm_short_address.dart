import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:plante/base/build_value_helper.dart';

part 'osm_short_address.g.dart';

abstract class OsmShortAddress
    implements Built<OsmShortAddress, OsmShortAddressBuilder> {
  static final OsmShortAddress empty = OsmShortAddress();

  String? get houseNumber;
  String? get road;
  String? get city;

  static OsmShortAddress? fromJson(Map<String, dynamic> json) {
    return BuildValueHelper.jsonSerializers
        .deserializeWith(OsmShortAddress.serializer, json);
  }

  factory OsmShortAddress([void Function(OsmShortAddressBuilder) updates]) =
      _$OsmShortAddress;
  OsmShortAddress._();
  static Serializer<OsmShortAddress> get serializer =>
      _$osmShortAddressSerializer;
}
