import 'dart:async';
import 'dart:convert';

import 'package:plante/base/base.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shared_preferences_ext.dart';
import 'package:plante/model/shared_preferences_holder.dart';
import 'package:plante/outside/map/osm/osm_address.dart';

class DistinctAddressTypeStorage {
  final SharedPreferencesHolder _prefs;
  final String _persistentName;

  String get _positionPref =>
      'DISTINCT_ADDRESS_TYPE_STORAGE_${_persistentName}_POSITION';
  String get _addressPref =>
      'DISTINCT_ADDRESS_TYPE_STORAGE_${_persistentName}_ADDRESS';

  Coord? _latestObtainedPosition;
  OsmAddress? _latestObtainedAddress;

  final _inited = Completer<void>();

  DistinctAddressTypeStorage(this._prefs, this._persistentName) {
    _initAsync();
  }

  void _initAsync() async {
    final prefs = await _prefs.get();
    final latestPos = prefs.getPoint(_positionPref);
    _latestObtainedPosition = Coord.fromPointNullable(latestPos);

    final latestAddressJsonStr = prefs.getString(_addressPref);
    if (latestAddressJsonStr != null) {
      final latestAddressJson = jsonDecodeSafe(latestAddressJsonStr);
      if (latestAddressJson != null) {
        try {
          _latestObtainedAddress = OsmAddress.fromJson(latestAddressJson);
        } catch (e) {
          Log.e('$_addressPref decode error: $latestAddressJson', ex: e);
        }
      }
    }

    _inited.complete();
  }

  Future<Pair<Coord, OsmAddress>?> lastAddress() async {
    await _inited.future;
    if (_latestObtainedAddress != null && _latestObtainedPosition != null) {
      return Pair(
        _latestObtainedPosition!,
        _latestObtainedAddress!,
      );
    }
    return null;
  }

  Future<void> updateLastAddress(Coord coord, OsmAddress address) async {
    await _inited.future;
    _latestObtainedAddress = address;
    _latestObtainedPosition = coord;
    final prefs = await _prefs.get();
    await prefs.setPoint(_positionPref, _latestObtainedPosition!.toPoint());
    await prefs.setString(
        _addressPref, jsonEncode(_latestObtainedAddress!.toJson()));
  }
}
