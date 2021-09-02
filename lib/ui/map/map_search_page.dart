import 'package:flutter/material.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/map/components/map_search_bar.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({Key? key}) : super(key: key);

  @override
  _MapSearchPageState createState() => _MapSearchPageState();
}

class _MapSearchPageState extends PageStatePlante<MapSearchPage> {
  static const _ANIMATION_END_AWAIT_DURATION = Duration(milliseconds: 500);
  final _searchBarFocusNode = FocusNode();

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
                    )))
          ]),
        )));
  }
}
