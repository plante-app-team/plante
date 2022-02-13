import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/fuzzy_search.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm/open_street_map.dart';
import 'package:plante/outside/map/osm/osm_address.dart';
import 'package:plante/outside/map/osm/osm_road.dart';
import 'package:plante/outside/map/osm/osm_search_result.dart';
import 'package:plante/outside/map/osm/osm_searcher.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/ui/map/search_page/map_search_page_displayed_error.dart';
import 'package:plante/ui/map/search_page/map_search_result.dart';

const _ONLINE_SEARCH_TIMEOUT = Duration(seconds: 5);

class MapSearchPageModel {
  static const MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS = 5.0;
  final ShopsManager _shopsManager;
  final RoadsManager _roadsManager;
  final LatestCameraPosStorage _cameraPosStorage;
  final AddressObtainer _addressObtainer;
  final OsmSearcher _osmSearcher;
  final UserLocationManager _userLocationManager;
  final ResCallback<String> _querySource;
  final Stream<String> _queryChanges;
  final VoidCallback _updateUi;
  final ArgCallback<MapSearchPageDisplayedError> _errCallback;

  final UiListAddressesObtainer<Shop> _shopsAddresses;

  final _searchResultsStream = StreamController<MapSearchResult?>();

  String _lastQuery = '';

  Coord? _cameraPos;
  CoordsBounds get _searchedArea {
    // Camera pos is not expected to change while the screen is opened
    _cameraPos ??= _cameraPosStorage.getCached();
    if (_cameraPos == null) {
      const msg = 'MapSearchPage is opened when there is no camera pos';
      Log.e(msg);
      throw Exception(msg);
    }
    return _cameraPos!.makeSquare(kmToGrad(30));
  }

  Coord? _lastKnownUserPos;
  final _centerAddressCompleter = Completer<OsmAddress>();

  var _loadingImpl = false;
  bool get _loading => _loadingImpl;
  set _loading(bool value) {
    _loadingImpl = value;
    _updateUi.call();
  }

  Coord get center {
    _searchedArea; // Ensure cache existence
    return _lastKnownUserPos ?? _cameraPos!;
  }

  bool get loading => _loading;

  MapSearchPageModel(
      this._shopsManager,
      this._roadsManager,
      this._cameraPosStorage,
      this._addressObtainer,
      this._osmSearcher,
      this._userLocationManager,
      this._querySource,
      this._queryChanges,
      this._updateUi,
      this._errCallback)
      : _shopsAddresses = UiListAddressesObtainer<Shop>(_addressObtainer) {
    _lastQuery = _querySource.call();
    _queryChanges.listen((updatedQuery) {
      if (_lastQuery != updatedQuery) {
        _lastQuery = updatedQuery;
        _loading = false;
      }
    });
    _initAsync();
  }

  void dispose() {
    _searchResultsStream.close();
  }

  void _initAsync() async {
    // Preload as much as possible
    unawaited(_fetchRoads(_searchedArea));
    unawaited(_shopsManager.fetchShops(_searchedArea));
    unawaited(_fetchAddressCenter());
    _updateLastKnownUserPos();
  }

  Future<Result<List<OsmRoad>, RoadsManagerError>> _fetchRoads(
      CoordsBounds searchedArea) async {
    return await _roadsManager
        .fetchRoadsWithinAndNearby(_convertToProperRoadsArea(searchedArea));
  }

  /// Cities have a TON of roads.
  /// We need to make sure we requests roads from a small enough area
  /// so that this area request would more likely hit cache and wouldn't cause
  /// a network request.
  CoordsBounds _convertToProperRoadsArea(CoordsBounds searchedArea) {
    return searchedArea.center
        .makeSquare(kmToGrad(RoadsManager.REQUESTED_RADIUS_KM * 0.7));
  }

  Future<Result<OsmAddress, OpenStreetMapError>> _fetchAddressCenter() async {
    if (_centerAddressCompleter.isCompleted) {
      return Ok(await _centerAddressCompleter.future);
    }
    final cameraAddressRes = await _addressObtainer.addressOfCoords(center);
    if (cameraAddressRes.isOk && !_centerAddressCompleter.isCompleted) {
      _centerAddressCompleter.complete(cameraAddressRes.unwrap());
    }
    return cameraAddressRes;
  }

  void _updateLastKnownUserPos() async {
    _lastKnownUserPos =
        await _userLocationManager.currentPosition(explicitUserRequest: false);
    _lastKnownUserPos ??= await _userLocationManager.lastKnownPosition();
  }

  /// [resultsCallback] will be called multiple times.
  /// When nothing is found then [MapSearchResult] is not-null
  /// but has empty lists.
  /// When search is canceled then [MapSearchResult] is null.
  void search(
      String query, ArgCallback<MapSearchResult?> resultsCallback) async {
    _loading = true;
    try {
      await _searchImpl(query, resultsCallback);
    } on _SearchCancelledException {
      // Nothing to do, search is cancelled
      resultsCallback.call(null);
    } finally {
      _loading = false;
    }
  }

  Future<MapSearchResult> _resultOrCancel(
      MapSearchResult result, String query) async {
    if (query != _querySource.call()) {
      throw _SearchCancelledException();
    }
    return result;
  }

  Future<void> _searchImpl(
      String query, ArgCallback<MapSearchResult?> resultsCallback) async {
    _updateLastKnownUserPos();

    resultsCallback
        .call(await _resultOrCancel(MapSearchResult.create(null, null), query));

    // Step #1: search OSM
    final foundInOsm = await _searchInOsm(query);
    final foundOsmEntitiesIds = <String>{};
    if (foundInOsm != null) {
      foundOsmEntitiesIds.addAll(foundInOsm.first.map((e) => e.osmUID.osmId));
      foundOsmEntitiesIds.addAll(foundInOsm.second.map((e) => e.osmId));
    }

    // Step #2: search shops locally
    final foundShopsLocally = <Shop>[];
    final fetchShopRes = await _shopsManager.fetchShops(_searchedArea);
    _maybeSendError(fetchShopRes.maybeErr()?.convert());
    if (fetchShopRes.isOk) {
      final fuzzyFoundShops =
          await _shopsFuzzySearch(query, fetchShopRes.unwrap().values.toList());
      for (final shop in fuzzyFoundShops) {
        if (!foundOsmEntitiesIds.contains(shop.osmUID.osmId)) {
          foundShopsLocally.add(shop);
          foundOsmEntitiesIds.add(shop.osmUID.osmId);
        }
      }
    }

    final foundShops = <Shop>[];
    foundShops.addAll((foundInOsm?.first ?? []).toList());
    foundShops.addAll(foundShopsLocally);
    _sortByNameAndDistance(
        foundShops, (Shop shop) => shop.name, (Shop shop) => shop.coord);
    resultsCallback.call(
        await _resultOrCancel(MapSearchResult.create(foundShops, null), query));

    // Step #3: search roads locally
    final foundRoadsLocally = <OsmRoad>[];
    final fetchRoadsRes = await _fetchRoads(_searchedArea);
    _maybeSendError(fetchRoadsRes.maybeErr()?.convert());
    if (fetchRoadsRes.isOk) {
      final fuzzyFoundRoads =
          await _roadsFuzzySearch(query, fetchRoadsRes.unwrap());
      for (final road in fuzzyFoundRoads) {
        if (!foundOsmEntitiesIds.contains(road.osmId)) {
          foundRoadsLocally.add(road);
          foundOsmEntitiesIds.add(road.osmId);
        }
      }
    }
    final foundRoads = <OsmRoad>[];
    foundRoads.addAll(foundInOsm?.second ?? []);
    foundRoads.addAll(foundRoadsLocally);
    _sortByNameAndDistance(
        foundRoads, (OsmRoad road) => road.name, (OsmRoad road) => road.coord);
    _mergeCloseRoads(foundRoads);
    resultsCallback.call(await _resultOrCancel(
        MapSearchResult.create(foundShops, foundRoads), query));
  }

  Future<Pair<List<Shop>, List<OsmRoad>>?> _searchInOsm(String query) async {
    final addressRes = await _fetchAddressCenter();
    if (addressRes.isErr) {
      _maybeSendError(addressRes.unwrapErr().convert());
      return null;
    }
    final address = addressRes.unwrap();
    if (address.country == null || address.city == null) {
      return null;
    }
    Result<OsmSearchResult, OpenStreetMapError> osmSearchRes;
    try {
      osmSearchRes = await _osmSearcher
          .search(address.country!, address.city!, query)
          .timeout(_ONLINE_SEARCH_TIMEOUT);
    } on TimeoutException {
      // Network timeout - we won't show online result
      Log.i('Online search timeout for $query');
      _maybeSendError(MapSearchPageDisplayedError.NETWORK);
      osmSearchRes = Ok(OsmSearchResult.empty);
    }
    if (osmSearchRes.isErr) {
      _maybeSendError(osmSearchRes.unwrapErr().convert());
      return null;
    }
    final foundShops = <Shop>[];
    final foundRoads = osmSearchRes.unwrap().roads.toList();
    final foundInflatedShops =
        await _shopsManager.inflateOsmShops(osmSearchRes.unwrap().shops);
    _maybeSendError(foundInflatedShops.maybeErr()?.convert());
    if (foundInflatedShops.isOk) {
      foundShops.addAll(foundInflatedShops.unwrap().values);
    }
    return Pair(foundShops, foundRoads);
  }

  Future<List<Shop>> _shopsFuzzySearch(String query, List<Shop> shops) async {
    return await FuzzySearch.searchSortCut<Shop>(
        shops, (shop) => shop.name, query);
  }

  Future<List<OsmRoad>> _roadsFuzzySearch(
      String query, List<OsmRoad> roads) async {
    return await FuzzySearch.searchSortCut<OsmRoad>(
        roads, (road) => road.name, query);
  }

  void _sortByNameAndDistance<T>(List<T> entities,
      ArgResCallback<T, String> nameFn, ArgResCallback<T, Coord> coordFn) {
    final result = <T>[];
    final sortedPiece = <T>[];
    final moveSortedPieceToResult = () {
      sortedPiece.sort((lhs, rhs) {
        final lhsDistance = metersBetween(center, coordFn(lhs));
        final rhsDistance = metersBetween(center, coordFn(rhs));
        return lhsDistance.toInt() - rhsDistance.toInt();
      });
      result.addAll(sortedPiece);
      sortedPiece.clear();
    };

    for (var index = 0; index < entities.length; ++index) {
      if (sortedPiece.isEmpty ||
          nameFn(sortedPiece.last).trim() == nameFn(entities[index]).trim()) {
        sortedPiece.add(entities[index]);
        continue;
      }
      moveSortedPieceToResult();
      sortedPiece.add(entities[index]);
    }
    moveSortedPieceToResult();

    entities.clear();
    entities.addAll(result);
  }

  void _mergeCloseRoads(List<OsmRoad> roads) {
    // When roads are closer to each other than closeDistanceMeters, merge them
    const closeDistanceMeters = MAX_DISTANCE_BETWEEN_MERGED_ROADS_KMS * 1000;
    final result = <OsmRoad>[];

    final mergedPiece = <OsmRoad>[];
    final merge = () {
      if (mergedPiece.isNotEmpty) {
        result.add(mergedPiece.first);
      }
      mergedPiece.clear();
    };

    for (var index = 0; index < roads.length; ++index) {
      final sameNames = mergedPiece.isNotEmpty &&
          mergedPiece.first.name.trim() == roads[index].name.trim();
      final areClose = mergedPiece.isNotEmpty &&
          metersBetween(mergedPiece.first.coord, roads[index].coord) <=
              closeDistanceMeters;
      if (mergedPiece.isEmpty || (sameNames && areClose)) {
        mergedPiece.add(roads[index]);
        continue;
      }
      merge();
      mergedPiece.add(roads[index]);
    }
    merge();

    roads.clear();
    roads.addAll(result);
  }

  void _maybeSendError(MapSearchPageDisplayedError? err) {
    if (err != null) {
      _errCallback.call(err);
    }
  }

  void onDisplayedShopsChanged(Set<Shop> displayedShops, List<Shop> allShops) {
    _shopsAddresses.onDisplayedEntitiesChanged(
        displayedEntities: displayedShops, allEntitiesOrdered: allShops);
  }

  FutureShortAddress requestAddressOf(Shop shop) {
    return _shopsAddresses.requestAddressOf(shop);
  }
}

class _SearchCancelledException implements Exception {}
