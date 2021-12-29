import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/outside/off/off_geo_helper.dart';

class FakeOffGeoHelper implements OffGeoHelper {
  final _addedGeodata = <String, Set<OsmUID>>{};

  // ignore: non_constant_identifier_names
  Map<String, Set<OsmUID>> addedGeodata_testing() => _addedGeodata;

  @override
  Future<Result<None, GeneralError>> addGeodataToProduct(
      String barcode, Iterable<Shop> shops) {
    return addGeodataToProducts([barcode], shops);
  }

  @override
  Future<Result<None, GeneralError>> addGeodataToProducts(
      List<String> barcodes, Iterable<Shop> shops) async {
    for (final barcode in barcodes) {
      _addedGeodata[barcode] ??= {};
      _addedGeodata[barcode]!.addAll(shops.map((e) => e.osmUID));
    }
    return Ok(None());
  }
}
