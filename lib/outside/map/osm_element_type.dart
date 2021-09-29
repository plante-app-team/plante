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
      throw Error();
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
      throw Error();
  }
}
