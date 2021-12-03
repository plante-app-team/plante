import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/country_code.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';

class FakeOffShopsManager implements OffShopsManager {
  final _suggestedBarcodes = <OffShop, List<String>>{};
  OffShop _offShop = OffShop((shop) => shop
    ..id = 'storeId'
    ..country = CountryCode.BELGIUM);

  void setSuggestedBarcodes(Map<OffShop, List<String>> suggestedBarcodes) {
    _suggestedBarcodes.clear();
    _suggestedBarcodes.addAll(suggestedBarcodes);
  }

  void setOffShop(String country, String? name) {
    _offShop = OffShop((shop) => shop
      ..id = 'storeId'
      ..name = name
      ..country = country);
  }

  @override
  Future<Result<List<OffShop>, OffShopsManagerError>> fetchOffShops() async {
    return Ok(_suggestedBarcodes.keys.toList());
  }

  @override
  Future<Result<ShopNamesAndBarcodesMap, OffShopsManagerError>>
      fetchVeganBarcodesMap(Set<String> shopsNames) async {
    final ShopNamesAndBarcodesMap result = {};
    for (final name in shopsNames) {
      for (final shop in _suggestedBarcodes.keys) {
        if (shop.id == OffShop.shopNameToPossibleOffShopID(name)) {
          result[name] = _suggestedBarcodes[shop]!;
        }
      }
    }
    return Ok(result);
  }

  @override
  void dispose() {
    // Nothing to do
  }

  @override
  Future<Result<OffShop, OffShopsManagerError>> findOffShopByName(
      String name) async {
    if (_offShop.name == name) {
      return Ok(_offShop);
    }
    return Err(OffShopsManagerError.OTHER);
  }

  @override
  Stream<Result<ShopNameBarcodesPair, OffShopsManagerError>> fetchVeganBarcodes(
      Set<String> shopsNames) async* {
    final mapRes = await fetchVeganBarcodesMap(shopsNames);
    if (mapRes.isErr) {
      yield Err(mapRes.unwrapErr());
      return;
    }
    final map = mapRes.unwrap();
    for (final entry in map.entries) {
      yield Ok(Pair(entry.key, entry.value));
    }
  }
}
