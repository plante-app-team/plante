import 'dart:convert';

import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

const SHOPS_BY_OSM_UIDS_CMD = 'shops_data';
const SHOPS_BY_OSM_UIDS_CMD_RESULT_FIELD = 'results_v2';

extension BackendExt on Backend {
  Future<Result<List<BackendShop>, BackendError>> requestShopsByOsmUIDs(
          Iterable<OsmUID> osmUIDs) =>
      executeCmd(_ShopsByOsmUidsCmd(osmUIDs));
}

class _ShopsByOsmUidsCmd extends BackendCmd<List<BackendShop>> {
  final Iterable<OsmUID> osmUIDs;
  _ShopsByOsmUidsCmd(this.osmUIDs);

  @override
  Future<Result<List<BackendShop>, BackendError>> execute() async {
    final jsonRes = await backendGetJson('$SHOPS_BY_OSM_UIDS_CMD/', {},
        body:
            jsonEncode({'osm_uids': osmUIDs.map((e) => e.toString()).toList()}),
        contentType: 'application/json');
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    if (!json.containsKey(SHOPS_BY_OSM_UIDS_CMD_RESULT_FIELD)) {
      Log.w('Invalid shops_data response: $json');
      return Err(BackendError.invalidDecodedJson(json));
    }

    final results =
        json[SHOPS_BY_OSM_UIDS_CMD_RESULT_FIELD] as Map<String, dynamic>;
    final shops = <BackendShop>[];
    for (final result in results.values) {
      final shop = BackendShop.fromJson(result as Map<String, dynamic>);
      if (shop != null) {
        shops.add(shop);
      }
    }
    return Ok(shops);
  }
}
