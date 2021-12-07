import 'dart:async';

import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_obtainer.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_storage.dart';
import 'package:plante/outside/map/user_address/user_address_piece.dart';
import 'package:plante/outside/map/user_address/user_address_type.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

/// Allows to obtain address piece (like country code or city) of certain type
/// of user location (user location itself or camera location).
///
/// Although this also can be done directly by [AddressObtainer], it's
/// discouraged - [AddressObtainer] won't try to cache the result and reuse it
/// if location hasn't changed too much.
class CachingUserAddressPiecesObtainer {
  final SharedPreferencesHolder _prefs;
  final UserLocationManager _userLocationManager;
  final LatestCameraPosStorage _latestCameraPosStorage;
  final AddressObtainer _addressObtainer;

  final Map<UserAddressType, DistinctAddressTypeStorage> _storages = {};
  final Map<UserAddressType, ResCallback<Future<Coord?>>> _requesters = {};
  final Map<_AddressTypePiecePair, DistinctAddressTypeObtainer> _obtainers = {};

  CachingUserAddressPiecesObtainer(this._prefs, this._userLocationManager,
      this._latestCameraPosStorage, this._addressObtainer) {
    for (final addressType in UserAddressType.values) {
      _storages[addressType] =
          DistinctAddressTypeStorage(_prefs, addressType.persistentCode);
      switch (addressType) {
        case UserAddressType.USER_LOCATION:
          _requesters[addressType] = _requestUserPos;
          break;
        case UserAddressType.CAMERA_LOCATION:
          _requesters[addressType] = _requestCameraPos;
          break;
      }
    }

    for (final addressType in UserAddressType.values) {
      for (final addressPiece in UserAddressPiece.values) {
        final storage = _storages[addressType]!;
        final requester = _requesters[addressType]!;
        final typeAndPiece = Pair(addressType, addressPiece);
        _obtainers[typeAndPiece] = DistinctAddressTypeObtainer(
            '${addressType.persistentCode}_${addressPiece.persistentCode}',
            storage,
            _addressObtainer,
            requester,
            addressPiece.maxToleratedDistanceChangeKms);
      }
    }
  }

  Future<Coord?> _requestUserPos() async {
    // We deliberately don't request current position because it
    // requires the location permission and we want to be able to work
    // without it.
    return await _userLocationManager.lastKnownPosition();
  }

  Future<Coord?> _requestCameraPos() async {
    return await _latestCameraPosStorage.get();
  }

  Future<String?> getAddressPiece(UserAddressType userAddressType,
      UserAddressPiece userAddressPiece) async {
    final pair = Pair(userAddressType, userAddressPiece);
    final address = await _obtainers[pair]!.obtainAddress();
    return address?.extractPiece(userAddressPiece);
  }
}

extension CachingUserAddressPiecesObtainerExt
    on CachingUserAddressPiecesObtainer {
  Future<String?> getUserLocationCountryCode() async {
    return await getAddressPiece(
        UserAddressType.USER_LOCATION, UserAddressPiece.COUNTRY_CODE);
  }

  Future<String?> getCameraCountryCode() async {
    return await getAddressPiece(
        UserAddressType.CAMERA_LOCATION, UserAddressPiece.COUNTRY_CODE);
  }
}

typedef _AddressTypePiecePair = Pair<UserAddressType, UserAddressPiece>;

extension _OsmAddressExt on OsmAddress {
  String? extractPiece(UserAddressPiece piece) {
    switch (piece) {
      case UserAddressPiece.COUNTRY_CODE:
        return countryCode;
      case UserAddressPiece.CITY:
        return city;
    }
  }
}
