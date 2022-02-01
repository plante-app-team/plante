import 'package:flutter/foundation.dart';
import 'package:plante/base/cached_lazy_op.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_api.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/off/off_vegan_barcodes_storage.dart';

typedef ShopsAndBarcodesMap = Map<OffShop, List<String>>;
typedef ShopBarcodesPair = Pair<OffShop, List<String>>;
typedef _BarcodesRequest = CachedLazyOp<List<String>, OffShopsManagerError>;

class OffVeganBarcodesObtainer {
  final OffApi _offApi;
  final OffVeganBarcodesStorage _storage;

  final Map<OffShop, _BarcodesRequest> _barcodesRequests = {};

  // OFF categories considered acceptable for products which are vegan
  // accidentally. The field is needed to avoid returning grains and canned
  // vegetables.
  static const _ACCIDENTALLY_VEGAN_ACCEPTABLE_CATEGORIES = [
    'en:desserts',
    'en:snacks',
    'en:meat-analogues',
    'en:milk-substitute',
    'en:non-dairy-yogurts',
    'en:frozen-desserts',
    'en:chips-and-fries',
    'en:biscuits-and-cakes',
    'en:veggie-patties',
    'en:biscuits',
  ];

  OffVeganBarcodesObtainer(this._offApi, this._storage);

  Future<Result<ShopsAndBarcodesMap, OffShopsManagerError>>
      obtainVeganBarcodesMap(Iterable<OffShop> shops) async {
    final ShopsAndBarcodesMap result = {};
    await for (final res in obtainVeganBarcodes(shops)) {
      if (res.isErr) {
        return Err(res.unwrapErr());
      }
      final pair = res.unwrap();
      result[pair.first] = pair.second;
    }
    return Ok(result);
  }

  /// NOTE: function stops data retrieval on first error
  Stream<Result<ShopBarcodesPair, OffShopsManagerError>> obtainVeganBarcodes(
      Iterable<OffShop> shops) async* {
    _validateCountryCodes(shops);

    for (final shop in shops) {
      final existingCache = await _storage.getBarcodesAtShops([shop]);
      if (existingCache[shop] != null) {
        yield Ok(Pair(shop, existingCache[shop]!));
      } else {
        final barcodesRes = await _queryBarcodesFor(shop);
        if (barcodesRes.isErr) {
          yield Err(barcodesRes.unwrapErr());
          return;
        }
        final barcodes = barcodesRes.unwrap();
        await _storage.setBarcodesOfShop(shop, barcodes);
        yield Ok(Pair(shop, barcodes));
      }
    }
  }

  void _validateCountryCodes(Iterable<OffShop> shops) {
    if (kDebugMode && shops.isNotEmpty) {
      final countryCode = shops.first.country;
      for (final shop in shops) {
        if (shop.country != countryCode) {
          throw Exception(
              'countryCode $countryCode does not match country code in $shop');
        }
      }
    }
  }

  Future<Result<List<String>, OffShopsManagerError>> _queryBarcodesFor(
      OffShop shop) async {
    // Magic happens below.
    //
    // Network operations are expensive, and barcodes can be
    // queried quite often, sometimes barcodes for a shop can be
    // queried while the previous request for same shop is not finished yet.
    // We don't want a new request to start in such a scenario - we want to
    // reuse the currently active request.
    //
    // To achieve this, the [_barcodesRequests] map is used.
    // Its key is [OffShop], its value is [CachedOperation].
    // [CachedOperation] was created precisely for our purpose - to reuse
    // the result of an active operation without restarting it.

    // Let's get an existing request ...
    var existingRequest = _barcodesRequests[shop];
    // ... or create a new one if no request is active at the moment.
    existingRequest ??= CachedLazyOp(() async => _queryBarcodesImpl(shop));
    // Memorize the request.
    _barcodesRequests[shop] = existingRequest;
    // Let's start the request OR reuse the result of an already
    // started request - [CachedOperation.result] does either of those 2,
    // depending on whether it's started already or not.
    final result = await existingRequest.result;
    // The request is finished at this point, so let's remove it.
    _barcodesRequests.remove(shop);
    return result;
  }

  Future<Result<List<String>, OffShopsManagerError>> _queryBarcodesImpl(
      OffShop shop) async {
    final barcodesRes1 = await _offApi.getBarcodesVeganByLabel(shop);
    final barcodesRes2 = await _offApi.getBarcodesVeganByIngredients(
        shop, _ACCIDENTALLY_VEGAN_ACCEPTABLE_CATEGORIES);

    if (barcodesRes1.isOk && barcodesRes2.isOk) {
      final barcodes1 = barcodesRes1.unwrap().toList();
      final barcodes1Set = barcodes1.toSet();
      final barcodes2Filtered =
          barcodesRes2.unwrap().where((e) => !barcodes1Set.contains(e));
      return Ok(barcodes1.toList() + barcodes2Filtered.toList());
    } else if (barcodesRes1.isOk) {
      return Ok(barcodesRes1.unwrap());
    } else if (barcodesRes2.isOk) {
      return Ok(barcodesRes2.unwrap());
    } else {
      return Err(barcodesRes1.unwrapErr().convert());
    }
  }
}

extension _OffRestApiErrorExt on OffRestApiError {
  OffShopsManagerError convert() {
    switch (this) {
      case OffRestApiError.NETWORK:
        return OffShopsManagerError.NETWORK;
      case OffRestApiError.OTHER:
        return OffShopsManagerError.OTHER;
    }
  }
}
