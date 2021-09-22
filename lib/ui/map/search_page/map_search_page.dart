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
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
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
  final MapSearchPageResult? initialState;
  const MapSearchPage({Key? key, this.initialState}) : super(key: key);

  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends PageStatePlante<MapSearchPage> {
  static const _ANIMATION_END_AWAIT_DURATION = Duration(milliseconds: 500);

  final _analytics = GetIt.I.get<Analytics>();
  final _searchBarFocusNode = FocusNode();
  final _querySource = MapSearchBarQueryView();
  late final ScrollController _scrollController;

  late final MapSearchPageModel _model;
  MapSearchResult? _lastSearchResult;

  final _displayedShops = <Shop>{};

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
      () => () {
        if (mounted) {
          setState(() {});
        }
      },
      _displayError,
    );
    final initialState = widget.initialState;
    if (initialState != null) {
      _lastSearchResult = MapSearchResult.create(
          initialState.foundShops, initialState.foundRoads);
    }
    _scrollController = ScrollController(
        initialScrollOffset: initialState?.scrollOffset ?? 0.0);
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
                queryInitial: widget.initialState?.query,
                queryView: _querySource,
                searchButtonAppearanceDelay: _ANIMATION_END_AWAIT_DURATION,
                onSearchTap: _onSearchTap,
                onCleared: _onQueryCleared,
              ))),
      Expanded(
          child: ListView(
        controller: _scrollController,
        children: _searchResults(),
      )),
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
      results.add(Padding(
          padding:
              const EdgeInsets.only(top: 24, bottom: 18, left: 24, right: 24),
          child: Text(context.strings.map_search_page_search_hint,
              style: TextStyles.hint)));
    } else {
      results.addAll(_convertFoundEntitiesToWidgets(
        entities: _lastSearchResult?.shops,
        entityPadding:
            const EdgeInsets.only(top: 12, bottom: 12, left: 24, right: 24),
        title: context.strings.map_search_page_shops_title,
        titlePadding:
            const EdgeInsets.only(top: 24, bottom: 6, left: 24, right: 24),
        notFoundMsg: context.strings.map_search_page_shops_not_found,
        toWidget: _shopToWidget,
        onTap: _finishWithShop,
      ));
      results.addAll(_convertFoundEntitiesToWidgets(
        entities: _lastSearchResult?.roads,
        entityPadding:
            const EdgeInsets.only(top: 18, bottom: 18, left: 24, right: 24),
        title: context.strings.map_search_page_streets_title,
        titlePadding:
            const EdgeInsets.only(top: 20, bottom: 0, left: 24, right: 24),
        notFoundMsg: context.strings.map_search_page_streets_not_found,
        toWidget: _roadToWidget,
        onTap: _finishWithRoad,
      ));
    }
    return results;
  }

  List<Widget> _convertFoundEntitiesToWidgets<T>(
      {required Iterable<T>? entities,
      required EdgeInsets entityPadding,
      required String title,
      required EdgeInsets titlePadding,
      required String notFoundMsg,
      required ArgResCallback<T, Widget> toWidget,
      required ArgCallback<T> onTap}) {
    final results = <Widget>[];

    results.add(Padding(
        padding: titlePadding,
        child: Text(title,
            style: TextStyles.headline3.copyWith(color: ColorsPlante.grey))));
    if (_model.loading || entities == null) {
      if (!isInTests()) {
        results.add(Wrap(children: [
          Padding(
              padding: entityPadding,
              child: const SizedBox(
                  width: 24, height: 24, child: CircularProgressIndicator()))
        ]));
      }
    } else if (entities.isEmpty) {
      results.add(Padding(
          padding: entityPadding,
          child: Text(notFoundMsg, style: TextStyles.hint)));
    } else {
      for (final entity in entities) {
        results.add(InkWell(
            onTap: () {
              onTap(entity);
            },
            child: Padding(padding: entityPadding, child: toWidget(entity))));
      }
    }

    return results;
  }

  Widget _shopToWidget(Shop shop) {
    return VisibilityDetectorPlante(
        keyStr: shop.osmId,
        onVisibilityChanged: (visible, _) =>
            _onShopVisibilityChange(shop, visible),
        child: MapSearchResultEntry(
            title: shop.name,
            subtitle:
                AddressWidget.forShop(shop, _model.requestAddressOf(shop)),
            distanceMeters: metersBetween(_model.center, shop.coord)));
  }

  void _onShopVisibilityChange(Shop shop, bool visible) {
    if (visible) {
      _displayedShops.add(shop);
    } else {
      _displayedShops.remove(shop);
    }
    _model.onDisplayedShopsChanged(
        _displayedShops.toSet(), // Defensive copy
        _lastSearchResult?.shops?.toList() ?? []);
  }

  Widget _roadToWidget(OsmRoad road) {
    return MapSearchResultEntry(
        title: road.name,
        distanceMeters: metersBetween(_model.center, road.coord));
  }

  void _finishWithShop(Shop shop) {
    Navigator.of(context).pop(MapSearchPageResult.create(
        query: _querySource.query,
        chosenShop: shop,
        allFound: _lastSearchResult,
        scrollOffset: _scrollController.offset));
  }

  void _finishWithRoad(OsmRoad road) {
    Navigator.of(context).pop(MapSearchPageResult.create(
        query: _querySource.query,
        chosenRoad: road,
        allFound: _lastSearchResult,
        scrollOffset: _scrollController.offset));
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
