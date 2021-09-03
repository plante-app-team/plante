import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/outside/map/open_street_map.dart';
import 'package:plante/outside/map/osm_road.dart';
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
            Expanded(
                child: ListView(
                    children: _foundRoads.isNotEmpty
                        ? _foundRoads.map((e) => Text(e.name)).toList()
                        : List.filled(100, 'Hello')
                            .map((e) => Text(e))
                            .toList()))
          ]),
        )));
  }

  void _onSearchTap(String query) async {
    // TODO: no
    final osm = GetIt.I.get<OpenStreetMap>();
    final cameraPosStorage = GetIt.I.get<LatestCameraPosStorage>();
    final roads = await osm
        .fetchRoads(cameraPosStorage.getCached()!.makeSquare(_kmToGrad(10)));
    setState(() {
      _foundRoads.clear();
      if (roads.isOk) {
        _foundRoads.addAll(roads.unwrap());
      }
    });
  }
}

double _kmToGrad(double km) {
  return km * 1 / 111;
}
