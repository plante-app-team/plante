import 'dart:async';

import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';
import 'package:plante/outside/off/off_shops_list_wrapper.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

enum OffShopsManagerError {
  NETWORK,
  OTHER,
}

typedef ShopNamesAndBarcodesMap = Map<String, List<String>>;
typedef ShopNameBarcodesPair = Pair<String, List<String>>;

class OffShopsManager {
  static const _ENABLED_IN_COUNTRIES = [
    CountryCode.GREAT_BRITAIN,
    CountryCode.SWEDEN,
    CountryCode.DENMARK,
    CountryCode.GREECE,
    CountryCode.ITALY,
    CountryCode.NORWAY,
    CountryCode.POLAND,
    CountryCode.PORTUGAL,
    CountryCode.SPAIN,
    CountryCode.LUXEMBOURG,
    CountryCode.GERMANY,
    CountryCode.FRANCE,
    CountryCode.NETHERLANDS,
    CountryCode.BELGIUM
  ];

  final OffVeganBarcodesObtainer _veganBarcodesObtainer;
  final OffShopsListObtainer _shopsObtainer;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;

  late final CachedOperation<OffShopsListWrapper, OffShopsManagerError>
      _offShopsOp;
  late final CachedOperation<String, None> _countryCodeOp;

  Future<Result<String?, None>> get _countryCode async {
    final result = await _countryCodeOp.result;
    if (result.isOk && !isEnabledCountry(result.unwrap())) {
      return Ok(null);
    }
    return result;
  }

  OffShopsManager(this._veganBarcodesObtainer, this._shopsObtainer,
      this._cameraPosStorage, this._addressObtainer) {
    _offShopsOp = CachedOperation(_fetchOffShopsImpl);
    _countryCodeOp = CachedOperation(_getCountryCodeImpl);
  }

  void dispose() {
    _offShopsOp.result.then((offShops) => offShops.maybeOk()?.dispose());
  }

  static bool isEnabledCountry(String isoCode) {
    return _ENABLED_IN_COUNTRIES.contains(isoCode);
  }

  Future<Result<OffShop?, OffShopsManagerError>> findOffShopByName(
      String name) async {
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    final offShops = await shopsRes.unwrap().findAppropriateShopsFor([name]);
    if (offShops.isEmpty) {
      return Ok(null);
    }
    return Ok(offShops[name]);
  }

  Future<Result<String, None>> _getCountryCodeImpl() async {
    final cameraPos = await _cameraPosStorage.get();
    if (cameraPos == null) {
      Log.w('offShopsManager._getCountryCodeImpl: no camera pos');
      return Err(None());
    }

    final addressRes =
        await _addressObtainer.addressOfCoords(cameraPos); // TODO: this
    if (addressRes.isErr) {
      Log.w('offShopsManager._getCountryCodeImpl: '
          'could not properly initialize because of $addressRes');
      return Err(None());
    }
    final address = addressRes.unwrap();
    final countryCode = address.countryCode;
    if (countryCode == null) {
      Log.w('offShopsManager._getCountryCodeImpl: '
          'User is out of all countries! Coord: $cameraPos, addr: $address');
      return Err(None());
    }
    return Ok(countryCode);
  }

  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    return Ok(shopsRes.unwrap().shops);
  }

  Future<Result<OffShopsListWrapper, OffShopsManagerError>>
      _fetchOffShopsImpl() async {
    final countryCode = await _countryCode;
    if (countryCode.isErr) {
      Log.w('offShopsManager.fetchOffShops - no country code, cannot fetch');
      return Err(OffShopsManagerError.OTHER);
    } else if (countryCode.unwrap() == null) {
      return Ok(await OffShopsListWrapper.create([]));
    }

    final shopsRes =
        await _shopsObtainer.getShopsForCountry(countryCode.unwrap()!);
    if (shopsRes.isErr) {
      Log.w('offShopManager.fetchOffShop error: $shopsRes');
      return Err(shopsRes.unwrapErr().convert());
    }
    final shops = shopsRes.unwrap();
    return Ok(await OffShopsListWrapper.create(shops));
  }

  Future<Result<ShopNamesAndBarcodesMap, OffShopsManagerError>>
      fetchVeganBarcodesMap(Set<String> shopsNames) async {
    final ShopNamesAndBarcodesMap result = {};
    final stream = fetchVeganBarcodes(shopsNames);
    await for (final pairRes in stream) {
      if (pairRes.isErr) {
        return Err(pairRes.unwrapErr());
      }
      final pair = pairRes.unwrap();
      result[pair.first] = pair.second;
    }
    return Ok(result);
  }

  /// NOTE: function stops data retrieval on first error
  Stream<Result<ShopNameBarcodesPair, OffShopsManagerError>> fetchVeganBarcodes(
      Set<String> shopsNames) async* {
    final countryCodeRes = await _countryCode;
    if (countryCodeRes.isErr) {
      Log.w(
          'offShopsManager.fetchVeganBarcodesForShops - no country code, cannot fetch');
      yield Err(OffShopsManagerError.OTHER);
      return;
    }
    final countryCode = countryCodeRes.unwrap();
    if (countryCode == null) {
      return;
    }
    final shopsRes = await _offShopsOp.result;
    if (shopsRes.isErr) {
      yield Err(shopsRes.unwrapErr());
      return;
    }
    final shopsWrapper = shopsRes.unwrap();
    final namesAndShops =
        await shopsWrapper.findAppropriateShopsFor(shopsNames);

    final shopsAndNames = <OffShop, List<String>>{};
    for (final nameShop in namesAndShops.entries) {
      shopsAndNames[nameShop.value] ??= [];
      shopsAndNames[nameShop.value]!.add(nameShop.key);
    }

    final shops = namesAndShops.values.toList();
    // Shops with greater number of products will have a priority
    shops.sort((lhs, rhs) => rhs.productsCount - lhs.productsCount);
    final barcodesStream = _veganBarcodesObtainer.obtainVeganBarcodes(shops);
    await for (final pairRes in barcodesStream) {
      if (pairRes.isErr) {
        yield Err(pairRes.unwrapErr());
        return;
      }
      final pair = pairRes.unwrap();
      final names = shopsAndNames[pair.first] ?? const [];
      for (final name in names) {
        yield Ok(Pair(name, pair.second));
      }
    }
  }
}

extension _OffShopsListObtainerErrorExt on OffShopsListObtainerError {
  OffShopsManagerError convert() {
    switch (this) {
      case OffShopsListObtainerError.NETWORK:
        return OffShopsManagerError.NETWORK;
      case OffShopsListObtainerError.OTHER:
        return OffShopsManagerError.OTHER;
    }
  }
}
