import 'package:plante/base/result.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';

const CREATE_SHOP_CMD = 'create_shop';

extension BackendExt on Backend {
  Future<Result<BackendShop, BackendError>> createShop(
          {required String name, required Coord coord, required String type}) =>
      executeCmd(_CreateShopCmd(name, coord, type));
}

class _CreateShopCmd extends BackendCmd<BackendShop> {
  final String name;
  final Coord coord;
  final String type;
  _CreateShopCmd(this.name, this.coord, this.type);

  @override
  Future<Result<BackendShop, BackendError>> execute() async {
    final jsonRes = await backendGetJson('$CREATE_SHOP_CMD/', {
      'lon': coord.lon.toString(),
      'lat': coord.lat.toString(),
      'name': name,
      'type': type
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();
    if (!json.containsKey('osm_uid')) {
      return Err(BackendError.invalidDecodedJson(json));
    }
    return Ok(BackendShop((e) => e
      ..osmUID = OsmUID.parse(json['osm_uid'] as String)
      ..productsCount = 0));
  }
}
