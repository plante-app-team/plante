import 'package:plante/base/base.dart';
import 'package:plante/base/cached_lazy_op.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/result.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/user_address/distinct_address_type_storage.dart';

class DistinctAddressTypeObtainer {
  final String _name;
  final DistinctAddressTypeStorage _addressStorage;
  final AddressObtainer _addressObtainer;
  final ResCallback<Future<Coord?>> _requestPosition;
  final int _maxToleratedDistanceKms;

  CachedLazyOp<OsmAddress?, None>? _ongoingOp;

  DistinctAddressTypeObtainer(
      this._name,
      this._addressStorage,
      this._addressObtainer,
      this._requestPosition,
      this._maxToleratedDistanceKms);

  Future<OsmAddress?> obtainAddress() async {
    _ongoingOp ??= CachedLazyOp.alwaysOk(_obtainAddressImpl);
    final result = await _ongoingOp!.result;
    _ongoingOp = null;
    return result.unwrap();
  }

  Future<OsmAddress?> _obtainAddressImpl() async {
    final latestAddressPair = await _addressStorage.lastAddress();

    final currentPos = await _requestPosition();
    if (currentPos == null) {
      return latestAddressPair?.second;
    }
    final maxMeters = _maxToleratedDistanceKms * 1000;
    if (latestAddressPair != null &&
        metersBetween(currentPos, latestAddressPair.first) <= maxMeters) {
      return latestAddressPair.second;
    }

    final newAddress = await _addressObtainer.addressOfCoords(currentPos);
    if (newAddress.isErr) {
      Log.w('Could not update latest address of $_name');
      return latestAddressPair?.second;
    }

    await _addressStorage.updateLastAddress(currentPos, newAddress.unwrap());
    return newAddress.unwrap();
  }
}
