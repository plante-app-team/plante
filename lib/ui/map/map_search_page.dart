import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/pair.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/roads_manager.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({Key? key}) : super(key: key);

  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends PageStatePlante<MapSearchPage> {
  static const _ANIMATION_END_AWAIT_DURATION = Duration(milliseconds: 500);
  final _searchBarFocusNode = FocusNode();

  final _foundShops = <Shop>[];
  final _foundRoads = <OsmRoad>[];

  _MapSearchPageState() : super('MapSearchPage');

  @override
  void initState() {
    super.initState();
    Future.delayed(
        _ANIMATION_END_AWAIT_DURATION, _searchBarFocusNode.requestFocus);
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: Container(
          color: Colors.white,
          child: Column(children: [
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
                      searchButtonAppearanceDelay:
                          _ANIMATION_END_AWAIT_DURATION,
                      onSearchTap: _onSearchTap,
                    ))),
            Expanded(child: ListView(children: _searchResults())),
          ]),
        )));
  }

  List<Widget> _searchResults() {
    final results = <Widget>[];
    for (final shop in _foundShops) {
      results.add(Text(shop.name));
    }
    for (final road in _foundRoads) {
      results.add(Text(road.name));
    }
    return results;
  }

  void _onSearchTap(String query) async {
    // TODO: no
    final shopsManager = GetIt.I.get<ShopsManager>();
    final roadsManager = GetIt.I.get<RoadsManager>();
    final cameraPosStorage = GetIt.I.get<LatestCameraPosStorage>();
    final cameraPos = cameraPosStorage.getCached();
    if (cameraPos == null) {
      return;
    }
    final osm = GetIt.I.get<OpenStreetMap>();
    final cameraAddressRes =
        await osm.fetchAddress(cameraPos.lat, cameraPos.lon);
    if (cameraAddressRes.isErr) {
      return;
    }
    final cameraAddress = cameraAddressRes.unwrap();
    if (cameraAddress.country == null || cameraAddress.city == null) {
      return;
    }
    final osmSearchRes =
        await osm.search(cameraAddress.country!, cameraAddress.city!, query);
    final osmFoundShops = <Shop>[];
    final osmFoundRoads = <OsmRoad>[];
    if (osmSearchRes.isOk) {
      osmFoundRoads.addAll(osmSearchRes.unwrap().roads);
      final foundInflatedShops =
          await shopsManager.inflateOsmShops(osmSearchRes.unwrap().shops);
      if (foundInflatedShops.isOk) {
        osmFoundShops.addAll(foundInflatedShops.unwrap().values);
      }
    }

    final searchedBounds = cameraPos.makeSquare(_kmToGrad(30));
    final shopsRes = await shopsManager.fetchShops(searchedBounds);
    setState(() {
      _foundShops.clear();
      _foundRoads.clear();
    });

    setState(() {
      _foundShops.addAll(osmFoundShops);
    });

    if (shopsRes.isOk) {
      final shops = await compute(
          _searchShops, Pair(shopsRes.unwrap().values.toList(), query));
      setState(() {
        _foundShops.addAll(shops);
      });
    }

    setState(() {
      _foundRoads.addAll(osmFoundRoads);
    });

    final roadsRes =
        await roadsManager.fetchRoadsWithinAndNearby(searchedBounds);
    if (roadsRes.isOk) {
      final roads =
          await compute(_searchRoads, Pair(roadsRes.unwrap().toList(), query));
      setState(() {
        _foundRoads.addAll(roads);
      });
    }
  }
}

double _kmToGrad(double km) {
  return km * 1 / 111;
}

List<Shop> _searchShops(Pair<Iterable<Shop>, String> shopsAndQuery) {
  final shops = shopsAndQuery.first;
  final query = shopsAndQuery.second;
  final result = <Shop>[];
  for (final shop in shops) {
    if (shop.name.contains(query)) {
      result.add(shop);
    }
  }
  return result;
}

List<OsmRoad> _searchRoads(Pair<Iterable<OsmRoad>, String> roadsAndQuery) {
  final roads = roadsAndQuery.first;
  final query = roadsAndQuery.second;
  final result = <OsmRoad>[];
  for (final road in roads) {
    if (road.name.contains(query)) {
      result.add(road);
    }
  }
  return result;
}
