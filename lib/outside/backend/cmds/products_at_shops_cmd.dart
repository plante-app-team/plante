import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_products_at_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

const PRODUCTS_AT_SHOPS_CMD = 'products_at_shops_data';
const PRODUCTS_AT_SHOPS_CMD_RESULT_FIELD = 'results_v2';

extension BackendExt on Backend {
  Future<Result<List<BackendProductsAtShop>, BackendError>>
      requestProductsAtShops(Iterable<OsmUID> osmUIDs) =>
          executeCmd(_ProductsAtShopsCmd(osmUIDs));
}

class _ProductsAtShopsCmd extends BackendCmd<List<BackendProductsAtShop>> {
  final Iterable<OsmUID> osmUIDs;
  _ProductsAtShopsCmd(this.osmUIDs);

  @override
  Future<Result<List<BackendProductsAtShop>, BackendError>> execute() async {
    final jsonRes = await backendGetJson('$PRODUCTS_AT_SHOPS_CMD/',
        {'osmShopsUIDs': osmUIDs.map((e) => e.toString())});
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey(PRODUCTS_AT_SHOPS_CMD_RESULT_FIELD)) {
      Log.w('Invalid products_at_shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results =
        json[PRODUCTS_AT_SHOPS_CMD_RESULT_FIELD] as Map<String, dynamic>;
    final productsAtShops = <BackendProductsAtShop>[];
    for (final result in results.values) {
      final productsAtShop =
          BackendProductsAtShop.fromJson(result as Map<String, dynamic>);
      if (productsAtShop != null) {
        productsAtShops.add(productsAtShop);
      }
    }
    return Ok(productsAtShops);
  }
}
