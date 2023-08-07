import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/backend/shops_in_bounds_response.dart';

const SHOPS_IN_BOUNDS_CMD = 'shops_in_bounds_data';

extension BackendExt on Backend {
  Future<Result<ShopsInBoundsResponse, BackendError>> requestShopsWithin(
          CoordsBounds bounds) =>
      executeCmd(_ShopsInBoundsCmd(bounds));
}

class _ShopsInBoundsCmd extends BackendCmd<ShopsInBoundsResponse> {
  final CoordsBounds bounds;
  _ShopsInBoundsCmd(this.bounds);

  @override
  Future<Result<ShopsInBoundsResponse, BackendError>> execute() async {
    final jsonRes = await backendGetJson('/$SHOPS_IN_BOUNDS_CMD/', {
      'north': '${bounds.north}',
      'south': '${bounds.south}',
      'west': '${bounds.west}',
      'east': '${bounds.east}',
    });
    if (jsonRes.isErr) {
      return Err(jsonRes.unwrapErr());
    }
    final json = jsonRes.unwrap();

    try {
      return Ok(ShopsInBoundsResponse.fromJson(json)!);
    } catch (e) {
      Log.w('Invalid shops_in_bounds_data response: $json', ex: e);
      return Err(BackendError.invalidDecodedJson(json));
    }
  }
}
