enum ProductAtShopSource {
  MANUAL,
  OFF_SUGGESTION,
  RADIUS_SUGGESTION,
}

extension ProductAtShopSourceExt on ProductAtShopSource {
  String get persistentName {
    switch (this) {
      case ProductAtShopSource.MANUAL:
        return 'manual';
      case ProductAtShopSource.OFF_SUGGESTION:
        return 'off_suggestion';
      case ProductAtShopSource.RADIUS_SUGGESTION:
        return 'radius_suggestion';
    }
  }
}
