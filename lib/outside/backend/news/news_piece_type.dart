enum NewsPieceType {
  UNKNOWN,
  PRODUCT_AT_SHOP,
}

extension NewsPieceTypeExt on NewsPieceType {
  int get persistentCode {
    switch (this) {
      case NewsPieceType.UNKNOWN:
        return -1;
      case NewsPieceType.PRODUCT_AT_SHOP:
        return 1;
    }
  }
}

NewsPieceType newsPieceTypeFromCode(int code) {
  switch (code) {
    case 1:
      return NewsPieceType.PRODUCT_AT_SHOP;
    default:
      return NewsPieceType.UNKNOWN;
  }
}
