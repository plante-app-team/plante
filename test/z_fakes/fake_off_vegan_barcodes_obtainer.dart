import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/outside/off/off_shop.dart';
import 'package:plante/outside/off/off_shops_manager.dart';
import 'package:plante/outside/off/off_vegan_barcodes_obtainer.dart';

class FakeOffVeganBarcodesObtainer implements OffVeganBarcodesObtainer {
  final Map<OffShop, List<String>> _barcodes = {};

  void setBarcodes(OffShop targetShop, List<String>? barcodes) {
    if (barcodes != null) {
      _barcodes[targetShop] = barcodes.toList();
    } else {
      _barcodes.remove(targetShop);
    }
  }

  @override
  Future<Result<ShopsAndBarcodesMap, OffShopsManagerError>>
      obtainVeganBarcodesMap(Iterable<OffShop> shops) async {
    final ShopsAndBarcodesMap result = {};
    for (final shop in shops) {
      final barcodes = _barcodes[shop];
      if (barcodes != null) {
        result[shop] = barcodes;
      }
    }
    return Ok(result);
  }

  @override
  Stream<Result<ShopBarcodesPair, OffShopsManagerError>> obtainVeganBarcodes(
      Iterable<OffShop> shops) async* {
    final mapRes = await obtainVeganBarcodesMap(shops);
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
