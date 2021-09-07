import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/base/fuzzy_search.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/base/result.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/coords_bounds.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_address.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';
import 'package:plante/ui/map/components/map_search_result_entry.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_search_page_displayed_error.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({Key? key}) : super(key: key);

  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends PageStatePlante<MapSearchPage> {
  static const _ANIMATION_END_AWAIT_DURATION = Duration(milliseconds: 500);

  final _shopsManager = GetIt.I.get<ShopsManager>();
  final _roadsManager = GetIt.I.get<RoadsManager>();
  final _cameraPosStorage = GetIt.I.get<LatestCameraPosStorage>();
  final _osm = GetIt.I.get<OpenStreetMap>();
  final _locationController = GetIt.I.get<LocationController>();
  final _analytics = GetIt.I.get<Analytics>();

  final _searchBarFocusNode = FocusNode();
  final _querySource = MapSearchBarQueryView();

  List<Shop>? _foundShops;
  List<OsmRoad>? _foundRoads;
  String get _query => _querySource.query;

  Coord? _cameraPos;
  Future<CoordsBounds> get _searchedArea async {
    // Camera pos is not expected to change while the screen is opened
    _cameraPos ??= await _cameraPosStorage.get();
    if (_cameraPos == null) {
      const msg = 'MapSearchPage is opened when there is no camera pos';
      Log.e(msg);
      throw Exception(msg);
    }
    return _cameraPos!.makeSquare(kmToGrad(30));
  }

  Coord? _lastKnownUserPos;
  Coord get _center => _lastKnownUserPos ?? _cameraPos!;
  final _centerAddressCompleter = Completer<OsmAddress>();

  var _loading = false;

  _MapSearchPageState() : super('MapSearchPage');

  @override
  void initState() {
    super.initState();
    if (!isInTests()) {
      Future.delayed(
          _ANIMATION_END_AWAIT_DURATION, _searchBarFocusNode.requestFocus);
    } else {
      _searchBarFocusNode.requestFocus();
    }
    _initAsync();
  }

  void _initAsync() async {
    // Preload as much as possible
    final searchedArea = await _searchedArea;
    unawaited(_fetchRoads(searchedArea));
    unawaited(_shopsManager.fetchShops(searchedArea));
    unawaited(_fetchAddressCenter());
    _updateLastKnownUserPos();
  }

  Future<Result<List<OsmRoad>, RoadsManagerError>> _fetchRoads(
      CoordsBounds searchedArea) async {
    return await _roadsManager
        .fetchRoadsWithinAndNearby(_convertToProperRoadsArea(searchedArea));
  }

  void _updateLastKnownUserPos() async {
    _lastKnownUserPos = await _locationController.currentPosition();
  }

  Future<Result<OsmAddress, OpenStreetMapError>> _fetchAddressCenter() async {
    if (_centerAddressCompleter.isCompleted) {
      return Ok(await _centerAddressCompleter.future);
    }
    final cameraAddressRes = await _osm.fetchAddress(_center.lat, _center.lon);
    if (cameraAddressRes.isOk) {
      _centerAddressCompleter.complete(cameraAddressRes.unwrap());
    }
    return cameraAddressRes;
  }

  @override
  Widget buildPage(BuildContext context) {
    final content = Column(children: [
      Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 44),
          child: Hero(
              tag: 'search_bar',
              child: MapSearchBar(
                customPrefixSvgIcon: 'assets/back_arrow.svg',
                onPrefixIconTap: () {
                  Navigator.of(context).pop();
                },
                focusNode: _searchBarFocusNode,
                queryView: _querySource,
                searchButtonAppearanceDelay: _ANIMATION_END_AWAIT_DURATION,
                onSearchTap: _onSearchTap,
                onCleared: _onQueryCleared,
              ))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ListView(children: _searchResults()))),
    ]);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: Container(
                color: Colors.white,
                child: Stack(children: [
                  content,
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: _loading && !isInTests()
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink())
                ]))));
  }

  List<Widget> _searchResults() {
    final results = <Widget>[];
    if (!_loading && _foundShops == null && _foundRoads == null) {
      results.add(Text(context.strings.map_search_page_search_hint,
          style: TextStyles.hint));
    } else {
      results.addAll(_convertFoundEntitiesToWidgets(
        _foundShops,
        context.strings.map_search_page_shops_title,
        context.strings.map_search_page_shops_not_found,
        _shopToWidget,
      ));
      results.addAll(_convertFoundEntitiesToWidgets(
        _foundRoads,
        context.strings.map_search_page_streets_title,
        context.strings.map_search_page_streets_not_found,
        _roadToWidget,
      ));
    }
    return results
        .map((e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: e))
        .toList();
  }

  List<Widget> _convertFoundEntitiesToWidgets<T>(List<T>? entities,
      String title, String notFoundMsg, ArgResCallback<T, Widget> toWidget) {
    final results = <Widget>[];

    results.add(Text(title, style: TextStyles.headline3));
    if (_loading && entities == null) {
      if (!isInTests()) {
        results.add(Wrap(children: const [
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
        ]));
      }
    } else if (entities != null && entities.isEmpty) {
      results.add(Text(notFoundMsg, style: TextStyles.hint));
    } else {
      for (final entity in entities!) {
        results.add(toWidget(entity));
      }
    }

    return results;
  }

  Widget _shopToWidget(Shop shop) {
    return MapSearchResultEntry(
        title: shop.name,
        subtitle: shop.type?.localize(context),
        distanceMeters: metersBetween(_center, shop.coord));
  }

  Widget _roadToWidget(OsmRoad road) {
    return MapSearchResultEntry(
        title: road.name, distanceMeters: metersBetween(_center, road.coord));
  }

  void _onQueryCleared() {
    setState(() {
      _foundShops = null;
      _foundRoads = null;
      _loading = false;
    });
  }

  void _onSearchTap(String query) async {
    _analytics.sendEvent('map_search_start');
    FocusScope.of(context).unfocus();
    _longUiAction(() async {
      try {
        await _searchImpl(query);
      } on _SearchCancelledException {
        // Nothing to do, search is cancelled
      }
    });
  }

  Future<void> _searchImpl(String query) async {
    _updateLastKnownUserPos();

    final updateDisplayedResults = (void Function() fn) {
      if (query != _query) {
        throw _SearchCancelledException();
      }
      setState(() {
        fn.call();
      });
    };

    updateDisplayedResults(() {
      _foundShops = null;
      _foundRoads = null;
    });

    // Step #1: search OSM
    final foundInOsm = await _searchInOsm(query);
    final foundOsmEntitiesIds = <String>{};
    if (foundInOsm != null) {
      foundOsmEntitiesIds.addAll(foundInOsm.first.map((e) => e.osmId));
      foundOsmEntitiesIds.addAll(foundInOsm.second.map((e) => e.osmId));
    }

    final searchedArea = await _searchedArea;

    // Step #2: search shops locally
    final foundShopsLocally = <Shop>[];
    final fetchShopRes = await _shopsManager.fetchShops(searchedArea);
    if (fetchShopRes.isOk) {
      final fuzzyFoundShops =
          await _shopsFuzzySearch(query, fetchShopRes.unwrap().values.toList());
      for (final shop in fuzzyFoundShops) {
        if (!foundOsmEntitiesIds.contains(shop.osmId)) {
          foundShopsLocally.add(shop);
          foundOsmEntitiesIds.add(shop.osmId);
        }
      }
    }
    updateDisplayedResults(() {
      _foundShops = [];
      _foundShops!.addAll((foundInOsm?.first ?? []).toList());
      _foundShops!.addAll(foundShopsLocally);
    });

    // Step #3: search roads locally
    final foundRoadsLocally = <OsmRoad>[];
    final fetchRoadsRes = await _fetchRoads(searchedArea);
    _maybeDisplayError(fetchRoadsRes.maybeErr()?.convert());
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
    updateDisplayedResults(() {
      _foundRoads = [];
      _foundRoads!.addAll(foundInOsm?.second ?? []);
      _foundRoads!.addAll(foundRoadsLocally);
    });
  }

  Future<Pair<List<Shop>, List<OsmRoad>>?> _searchInOsm(String query) async {
    final addressRes = await _fetchAddressCenter();
    if (addressRes.isErr) {
      _maybeDisplayError(addressRes.maybeErr()?.convert());
      return null;
    }
    final address = addressRes.unwrap();
    if (address.country == null || address.city == null) {
      return null;
    }
    final osmSearchRes =
        await _osm.search(address.country!, address.city!, query);
    if (osmSearchRes.isErr) {
      _maybeDisplayError(osmSearchRes.maybeErr()?.convert());
      return null;
    }
    final foundShops = <Shop>[];
    final foundRoads = osmSearchRes.unwrap().roads.toList();
    final foundInflatedShops =
        await _shopsManager.inflateOsmShops(osmSearchRes.unwrap().shops);
    _maybeDisplayError(foundInflatedShops.maybeErr()?.convert());
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

  void _maybeDisplayError<T>(MapSearchPageDisplayedError? error) {
    if (error != null) {
      switch (error) {
        case MapSearchPageDisplayedError.NETWORK:
          showSnackBar(context.strings.global_network_error, context);
      }
    }
  }

  void _longUiAction(dynamic Function() action) async {
    setState(() {
      _loading = true;
    });
    try {
      await action.call();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Cities have a TON of roads.
  /// We need to make sure we requests roads from a small enough area
  /// so that this area request would more likely hit cache and wouldn't cause
  /// a network request.
  CoordsBounds _convertToProperRoadsArea(CoordsBounds searchedArea) {
    return searchedArea.center
        .makeSquare(kmToGrad(RoadsManager.REQUESTED_RADIUS_KM * 0.7));
  }
}

class _SearchCancelledException implements Exception {}
