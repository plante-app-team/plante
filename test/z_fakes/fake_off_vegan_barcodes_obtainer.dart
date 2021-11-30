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
      obtainVeganBarcodesForShops(
          String countryCode, Iterable<OffShop> shops) async {
    final ShopsAndBarcodesMap result = {};
    for (final shop in shops) {
      final barcodes = _barcodes[shop];
      if (barcodes != null) {
        result[shop] = barcodes;
      }
    }
    return Ok(result);
  }
}
