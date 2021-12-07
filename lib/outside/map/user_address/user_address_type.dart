enum UserAddressType {
  USER_LOCATION,
  CAMERA_LOCATION,
}

extension UserAddressTypeExt on UserAddressType {
  String get persistentCode {
    switch (this) {
      case UserAddressType.USER_LOCATION:
        return 'USER_LOCATION';
      case UserAddressType.CAMERA_LOCATION:
        return 'CAMERA_LOCATION';
    }
  }
}
