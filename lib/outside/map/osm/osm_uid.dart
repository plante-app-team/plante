import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter/foundation.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';

@immutable
class OsmUID {
  final OsmElementType type;
  final String osmId;

  const OsmUID(this.type, this.osmId);

  /// Throws ArgumentError if arg is invalid
  factory OsmUID.parse(String str) {
    if (str[1] != ':') {
      throw ArgumentError('OSM UID must include OSM element type: $str');
    }
    final persistentCode = int.tryParse(str[0]);
    if (persistentCode == null) {
      throw ArgumentError('Invalid persistent code in  $str');
    }
    final osmType = osmElementTypeFromCode(persistentCode);
    final osmId = str.substring(2);
    return OsmUID(osmType, osmId);
  }

  static OsmUID? parseSafe(String str) {
    try {
      return OsmUID.parse(str);
    } on ArgumentError catch (e) {
      Log.w('Invalid osm UID: $str', ex: e);
      return null;
    }
  }

  @override
  String toString() {
    return '${type.persistentCode}:$osmId';
  }

  @override
  bool operator ==(Object other) {
    if (other is! OsmUID) {
      return false;
    }
    return type == other.type && osmId == other.osmId;
  }

  @override
  int get hashCode => _combine(type.hashCode, osmId.hashCode);

  // https://stackoverflow.com/a/26648915
  int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }
}

class OsmUIDBuildValueSerializer implements PrimitiveSerializer<OsmUID> {
  @override
  final Iterable<Type> types = BuiltList<Type>([OsmUID]);
  @override
  final String wireName = 'OsmUID';

  @override
  Object serialize(Serializers serializers, OsmUID osmUID,
      {FullType specifiedType = FullType.unspecified}) {
    return osmUID.toString();
  }

  @override
  OsmUID deserialize(Serializers serializers, Object? serialized,
      {FullType specifiedType = FullType.unspecified}) {
    try {
      return OsmUID.parse(serialized! as String);
    } catch (e) {
      Log.e('Invalid osm UID: $serialized');
      return const OsmUID(OsmElementType.NODE, '0');
    }
  }
}
