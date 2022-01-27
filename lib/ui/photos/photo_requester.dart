enum PhotoRequester {
  AVATAR_INIT,
  PRODUCT_INIT,
}

extension PhotoRequesterExt on PhotoRequester {
  int get persistentCode {
    switch (this) {
      case PhotoRequester.AVATAR_INIT:
        return 1;
      case PhotoRequester.PRODUCT_INIT:
        return 2;
    }
  }
}
