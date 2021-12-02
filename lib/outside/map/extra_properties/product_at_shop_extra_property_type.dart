enum ProductAtShopExtraPropertyType {
  FOR_TESTS,
  INVALID,
  VOTE_RECEIVED_POSITIVE,
  VOTE_RECEIVED_NEGATIVE,
  BAD_SUGGESTION,
}

ProductAtShopExtraPropertyType createProductAtShopExtraPropertyTypeFromCode(
    int code) {
  final codes = ProductAtShopExtraPropertyType.values
      .where((e) => e.persistentCode == code);
  if (codes.isNotEmpty) {
    return codes.first;
  }
  return ProductAtShopExtraPropertyType.INVALID;
}

extension ProductAtShopExtraPropertyTypeExt on ProductAtShopExtraPropertyType {
  int get persistentCode {
    // Please ENSURE old codes are not reused
    switch (this) {
      case ProductAtShopExtraPropertyType.FOR_TESTS:
        return -2;
      case ProductAtShopExtraPropertyType.INVALID:
        return -1;
      case ProductAtShopExtraPropertyType.VOTE_RECEIVED_POSITIVE:
        return 1;
      case ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE:
        return 2;
      case ProductAtShopExtraPropertyType.BAD_SUGGESTION:
        return 3;
    }
  }

  /// Duration after which the property should get deleted
  Duration get lifetime {
    switch (this) {
      case ProductAtShopExtraPropertyType.FOR_TESTS:
        return const Duration(seconds: 4);
      case ProductAtShopExtraPropertyType.INVALID:
        return Duration.zero;
      case ProductAtShopExtraPropertyType.VOTE_RECEIVED_POSITIVE:
        return const Duration(days: 7);
      case ProductAtShopExtraPropertyType.VOTE_RECEIVED_NEGATIVE:
        return const Duration(days: 7);
      case ProductAtShopExtraPropertyType.BAD_SUGGESTION:
        return const Duration(days: 365);
    }
  }
}
