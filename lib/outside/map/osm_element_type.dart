enum OsmElementType {
  NODE,
  RELATION,
  WAY,
}

extension OsmElementTypeExt on OsmElementType {
  int get persistentCode {
    switch (this) {
      case OsmElementType.NODE:
        return 1;
      case OsmElementType.RELATION:
        return 2;
      case OsmElementType.WAY:
        return 3;
    }
  }
}

OsmElementType osmElementTypeFromCode(int persistentCode) {
  switch (persistentCode) {
    case 1:
      return OsmElementType.NODE;
    case 2:
      return OsmElementType.RELATION;
    case 3:
      return OsmElementType.WAY;
    default:
      throw ArgumentError();
  }
}

OsmElementType osmElementTypeFromStr(String str) {
  switch (str) {
    case 'node':
      return OsmElementType.NODE;
    case 'relation':
      return OsmElementType.RELATION;
    case 'way':
      return OsmElementType.WAY;
    default:
      throw ArgumentError();
  }
}

OsmElementType? osmElementTypeFromOsmUID(String osmUID,
    {bool throwOnError = false}) {
  if (osmUID[1] != ':') {
    if (throwOnError) {
      throw ArgumentError('OSM UID must include OSM element type: $osmUID');
    }
    return null;
  }
  final persistentCode = int.tryParse(osmUID[0]);
  if (persistentCode == null) {
    if (throwOnError) {
      throw ArgumentError('Invalid persistent code in  $osmUID');
    }
    return null;
  }
  return osmElementTypeFromCode(persistentCode);
}
