import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/base/coord_utils.dart';
import 'package:plante/location/location_controller.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/osm_road.dart';
import 'package:plante/outside/map/osm_searcher.dart';
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
import 'package:plante/ui/map/search_page/map_search_page_displayed_error.dart';
import 'package:plante/ui/map/search_page/map_search_page_model.dart';
import 'package:plante/ui/map/search_page/map_search_page_result.dart';
import 'package:plante/ui/map/search_page/map_search_result.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({Key? key}) : super(key: key);

  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends PageStatePlante<MapSearchPage> {
  static const _ANIMATION_END_AWAIT_DURATION = Duration(milliseconds: 500);

  final _analytics = GetIt.I.get<Analytics>();
  final _searchBarFocusNode = FocusNode();
  final _querySource = MapSearchBarQueryView();

  late final MapSearchPageModel _model;
  MapSearchResult? _lastSearchResult;

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
    _model = MapSearchPageModel(
      GetIt.I.get<ShopsManager>(),
      GetIt.I.get<RoadsManager>(),
      GetIt.I.get<LatestCameraPosStorage>(),
      GetIt.I.get<AddressObtainer>(),
      GetIt.I.get<OsmSearcher>(),
      GetIt.I.get<LocationController>(),
      () => _querySource.query,
      _querySource.queryChanges,
      () => setState(() {}),
      _displayError,
    );
  }

  @override
  void dispose() {
    _querySource.dispose();
    _model.dispose();
    super.dispose();
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
                  Material(color: Colors.transparent, child: content),
                  AnimatedSwitcher(
                      duration: DURATION_DEFAULT,
                      child: _model.loading && !isInTests()
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink())
                ]))));
  }

  List<Widget> _searchResults() {
    final results = <Widget>[];
    if (!_model.loading && _lastSearchResult == null) {
      results.add(_itemPadding(Text(context.strings.map_search_page_search_hint,
          style: TextStyles.hint)));
    } else {
      results.addAll(_convertFoundEntitiesToWidgets(
        _lastSearchResult?.shops,
        context.strings.map_search_page_shops_title,
        context.strings.map_search_page_shops_not_found,
        _shopToWidget,
        _finishWithShop,
      ));
      results.addAll(_convertFoundEntitiesToWidgets(
        _lastSearchResult?.roads,
        context.strings.map_search_page_streets_title,
        context.strings.map_search_page_streets_not_found,
        _roadToWidget,
        _finishWithRoad,
      ));
    }
    return results;
  }

  Widget _itemPadding(Widget item) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: item);

  Widget _itemsTitlePadding(Widget item) => Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
      child: item);

  List<Widget> _convertFoundEntitiesToWidgets<T>(
      Iterable<T>? entities,
      String title,
      String notFoundMsg,
      ArgResCallback<T, Widget> toWidget,
      ArgCallback<T> onTap) {
    final results = <Widget>[];

    results.add(_itemsTitlePadding(Text(title, style: TextStyles.headline3)));
    if (_model.loading || entities == null) {
      if (!isInTests()) {
        results.add(Wrap(children: [
          _itemPadding(const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator()))
        ]));
      }
    } else if (entities.isEmpty) {
      results.add(_itemPadding(Text(notFoundMsg, style: TextStyles.hint)));
    } else {
      for (final entity in entities) {
        results.add(InkWell(
            onTap: () {
              onTap(entity);
            },
            child: _itemPadding(toWidget(entity))));
      }
    }

    return results;
  }

  Widget _shopToWidget(Shop shop) {
    return MapSearchResultEntry(
        title: shop.name,
        subtitle: shop.type?.localize(context),
        distanceMeters: metersBetween(_model.center, shop.coord));
  }

  Widget _roadToWidget(OsmRoad road) {
    return MapSearchResultEntry(
        title: road.name,
        distanceMeters: metersBetween(_model.center, road.coord));
  }

  void _finishWithShop(Shop shop) {
    Navigator.of(context).pop(MapSearchPageResult.create(shop, null));
  }

  void _finishWithRoad(OsmRoad road) {
    Navigator.of(context).pop(MapSearchPageResult.create(null, road));
  }

  void _onQueryCleared() {
    setState(() {
      _lastSearchResult = null;
      if (_model.loading) {
        Log.e('Query is cleared but model has not stopped searching');
      }
    });
  }

  void _onSearchTap(String query) async {
    _analytics.sendEvent('map_search_start');
    FocusScope.of(context).unfocus();
    _model.search(query, (result) {
      setState(() {
        _lastSearchResult = result;
      });
    });
  }

  void _displayError<T>(MapSearchPageDisplayedError error) {
    switch (error) {
      case MapSearchPageDisplayedError.NETWORK:
        showSnackBar(context.strings.global_network_error, context);
    }
  }
}
