enum UserAddressPiece {
  COUNTRY_CODE,
  CITY,
}

extension UserAddressPieceExt on UserAddressPiece {
  int get maxToleratedDistanceChangeKms {
    switch (this) {
      case UserAddressPiece.COUNTRY_CODE:
        return 50;
      case UserAddressPiece.CITY:
        return 5;
    }
  }

  String get persistentCode {
    switch (this) {
      case UserAddressPiece.COUNTRY_CODE:
        return 'COUNTRY_CODE';
      case UserAddressPiece.CITY:
        return 'CITY';
    }
  }
}
