import 'dart:async';

import 'package:plante/base/cached_operation.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_list_obtainer.dart';
import 'package:plante/outside/off/off_shops_list_wrapper.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';

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
    CountryCode.BELGIUM,
    CountryCode.USA,
  ];

  final OffVeganBarcodesObtainer _veganBarcodesObtainer;
  final OffShopsListObtainer _shopsObtainer;

  late final Map<String,
          CachedOperation<OffShopsListWrapper, OffShopsManagerError>>
      _offShopsMap = {};

  OffShopsManager(this._veganBarcodesObtainer, this._shopsObtainer);

  void dispose() {
    for (final shops in _offShopsMap.values) {
      shops.result.then((offShops) => offShops.maybeOk()?.dispose());
    }
  }

  static bool isEnabledCountry(String isoCode) {
    return _ENABLED_IN_COUNTRIES.contains(isoCode);
  }

  Future<Result<OffShop?, OffShopsManagerError>> findOffShopByName(
      String name, String countryCode) async {
    if (!isEnabledCountry(countryCode)) {
      return Ok(null);
    }

    final shopsRes = await _offShopsFor(countryCode);
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    final offShops = await shopsRes.unwrap().findAppropriateShopsFor([name]);
    if (offShops.isEmpty) {
      return Ok(null);
    }
    return Ok(offShops[name]);
  }

  Future<Result<OffShopsListWrapper, OffShopsManagerError>> _offShopsFor(
      String countryCode) async {
    var shops = _offShopsMap[countryCode];
    shops ??= CachedOperation(() => _fetchOffShopsImpl(countryCode));
    _offShopsMap[countryCode] = shops;
    return shops.result;
  }

  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops(
      String countryCode) async {
    final shopsRes = await _offShopsFor(countryCode);
    if (shopsRes.isErr) {
      return Err(shopsRes.unwrapErr());
    }
    return Ok(shopsRes.unwrap().shops);
  }

  Future<Result<OffShopsListWrapper, OffShopsManagerError>> _fetchOffShopsImpl(
      String countryCode) async {
    if (!isEnabledCountry(countryCode)) {
      return Ok(await OffShopsListWrapper.create([]));
    }

    final shopsRes = await _shopsObtainer.getShopsForCountry(countryCode);
    if (shopsRes.isErr) {
      Log.w('offShopManager.fetchOffShop error: $shopsRes');
      return Err(shopsRes.unwrapErr().convert());
    }
    final shops = shopsRes.unwrap();
    return Ok(await OffShopsListWrapper.create(shops));
  }

  /// NOTE: function stops data retrieval on first error
  Stream<Result<ShopNameBarcodesPair, OffShopsManagerError>> fetchVeganBarcodes(
      Set<String> shopsNames, String countryCode) async* {
    if (!isEnabledCountry(countryCode)) {
      return;
    }

    final shopsRes = await _offShopsFor(countryCode);
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

extension OffShopsManagerExt on OffShopsManager {
  Future<Result<ShopNamesAndBarcodesMap, OffShopsManagerError>>
      fetchVeganBarcodesMap(Set<String> shopsNames, String countryCode) async {
    final ShopNamesAndBarcodesMap result = {};
    final stream = fetchVeganBarcodes(shopsNames, countryCode);
    await for (final pairRes in stream) {
      if (pairRes.isErr) {
        return Err(pairRes.unwrapErr());
      }
      final pair = pairRes.unwrap();
      result[pair.first] = pair.second;
    }
    return Ok(result);
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
